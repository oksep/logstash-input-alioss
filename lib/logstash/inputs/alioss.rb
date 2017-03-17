# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname
require 'net/http'
require 'uri'

require 'aliyun/oss'
require 'yaml'
require 'snappy'


# 阿里云 OSS 收集器 
#     - 基于 https://github.com/yami/logstash-input-oss 优化
#     - aliyun/oss SDK 文档  https://help.aliyun.com/document_detail/32114.html?spm=5176.doc32114.3.3.6Srsao
#     - 使用阅读 README.md
#   
class LogStash::Inputs::Alioss < LogStash::Inputs::Base
  config_name "alioss"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  config :interval, :validate => :number, :default => 60

  # oss client 配置
  config :access_key_id, :validate => :string, :default => nil
  config :access_key_secret, :validate => :string, :default => nil
  config :endpoint, :validate => :string, :default => nil
  config :bucket, :validate => :string, :default => nil
  config :marker_file, :validate => :string, :default => File.join(Dir.home, '.alioss-marker.yml')
  config :prefix, :validate => :string, :default => ""

  public
  def register
    @host = Socket.gethostname
    @oss_client = Aliyun::OSS::Client.new(
      :endpoint => @endpoint,
      :access_key_id => @access_key_id,
      :access_key_secret => @access_key_secret,
      :cname => false
    )
    @oss_bucket = @oss_client.get_bucket(@bucket)
    @markerConfig = MarkerConfig.new @marker_file
    @logger.info('OSS收集器 启动...')
  end

  def run(queue)
    @current_thread = Thread.current
    Stud.interval(@interval) do
      process(queue)
    end
  end

  def process_test(queue)
     # we can abort the loop if stop? becomes true
    while !stop?
      event = LogStash::Event.new(
        "host" => @host,
        "endpoint"=> @endpoint,
        "access_key_id" => @access_key_id,
        "access_key_secret" => @access_key_secret,
        "bucket" => @bucket
      )
      decorate(event)
      queue << event
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end

  def process(queue)
    @logger.info('Marker from: ' + @markerConfig.getMarker)

    # 1. 请求obj列表
    list = @oss_bucket.list_objects(:prefix => @prefix, :marker => @markerConfig.getMarker)
    
    # 2. 遍历列表
    list.each do |obj|
      if stop?
        @logger.info("stop while attempting to read log file")
        break
      end

      # 3. obj 转化
      parse_obj_2_log(obj) { |log|

        # 4. codec 并发送消息
        @codec.decode(log) do |event|
          decorate(event)
          queue << event
        end
      }

      # 5. 记录 marker
      @markerConfig.setMarker(obj.key)
      @logger.info('Marker end: ' + @markerConfig.getMarker)

    end

  end

  # 下载 obj 并转化成多条 log
  def parse_obj_2_log(obj, &block)
    url=@oss_bucket.object_url(obj.key)
    documents = open_url(url)
    documents = Snappy.inflate(documents)
    documents.each_line(&block)
  end
  
  # 链接 url
  def open_url(url)
    Net::HTTP.get(URI.parse(url))
  end

  # logstash 关闭回调
  def stop
    @markerConfig.ensureMarker
    @logger.info('OSS收集器 停止...')
    @logger.info('Marker record: ' + @markerConfig.getMarker)
    
    Stud.stop!(@current_thread)
  end
end # class LogStash::Inputs::Alioss


# 标记配置工具
class MarkerConfig
  KEY_MARKER = 'next_marker'

  def initialize(filename)
    @filename = filename
    dirname = File.dirname(@filename)
    unless Dir.exist?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    if File.exists?(@filename)
      @config = YAML.load_file(@filename)
    else 
      @config = {KEY_MARKER => nil}
        File.open(@filename, 'w') do |handler| 
          handler.write @config.to_yaml
        end
      end
    end

  def getMarker
    @config[KEY_MARKER] || ''
  end

  public
  def setMarker (marker)
    @config[KEY_MARKER] = marker
  end
  
  public
  def ensureMarker
    File.open(@filename, 'w') do |handler| 
      handler.write @config.to_yaml
    end
  end

end # class bucket 读取配置