# Logstash input plugin base on aliyun/oss

## 安装使用 **jruby**
    
    ```
    rvm install jruby-9.1.7.0
    rvm use jruby-9.1.7.0 --default
    ```
    
## 安装 **bundler** 

    ```
    gem install bundler
    ```

## 创建项目

用工具生成项目模板

```
logstash-plugin generate --type input --name alioss --path ./
```
    
当前下创建了一个名为 logstash-input-alioss 的工程，目录结构如下:
    
```
|____CHANGELOG.md
|____CONTRIBUTORS
|____DEVELOPER.md
|____Gemfile
|____Gemfile.lock
|____lib
| |____logstash
| | |____inputs
| | | |____alioss.rb
|____LICENSE
|____logstash-input-alioss.gemspec
|____Rakefile
|____README.md
|____spec
| |____inputs
| | |____alioss_spec.rb
```
    
## 安装依赖

使用 **gem** 安装 **aliyun-sdk**、**snappy** 。注意: **aliyun-sdk** 并未使用最新版本，而是使用 0.3.6, 详情戳这里 [issue](https://github.com/aliyun/aliyun-oss-ruby-sdk/issues/40)

```
gem install -v 0.3.6 aliyun-sdk
gem install snappy
```

## 集成 **aliyun-sdk**

编辑 _logstash-input-alioss.gemspec_，添加依赖

```
s.add_runtime_dependency 'aliyun-sdk', '~> 0.3.6'
s.add_runtime_dependency 'snappy'
```
    
## 打包工程 

```
bundle install
```

## 安装插件

安装插件可以分成两种，开发模式、生产模式。参考[这里](https://github.com/Wondermall/logstash-input-google-cloud-pubsub)

### 1. 开发模式

修改 _logstash/Gemfile_ 
        
```
echo 'gem "logstash-input-alioss", :path => "logstash-input-alioss绝对路径"' >> logstash路径/Gemfile
```
        
命令行安装
        
```
logstash-plugin install --no-verify
```
    
### 2. 生产模式

执行下面命令，会在工程下生成 _logstash-input-alioss-0.1.0.gem_ 文件

```
gem build logstash-input-alioss.gemspec
```

命令行安装 (别急，这个过程可能会需要多等一会)

```
logstash-plugin install /path/to/logstash-input-alioss-0.1.0.gem
```

### 3. 检查插件是否安装成功

不论以上哪种方法，安装成功的话都会出现在列表中

```
logstash-plugin list --group input
```

## 编写配置文件 
_alioss.logstash.conf_
    
    ```
    input {
        alioss {
            endpoint => 'your endpoint'
            access_key_id => 'your access_key_id'
            access_key_secret => 'your access_key_secret'
            bucket => 'your bucket'
            interval => 60
            codec => json
        }
    }
    
    output {
        stdout {
            codec=>rubydebug
        }
    }
    ```

## 测试插件
    
    ```
    logstash -f alioss.logstash.conf
    ```




