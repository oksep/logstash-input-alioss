# Logstash input plugin base on aliyun/oss

1. 该项目由模板工具生成

    `logstash-plugin generate --type input --name alioss --path ./`
    
    目录结构如下:
    
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

2. 安装使用 **jruby**
    
    ```
    rvm install jruby-9.1.7.0
    rvm use jruby-9.1.7.0 --default
    ```
    
3. 安装 **bundler** 

    ```
    gem install bundler
    ```
4. 使用 **gem** 安装 **aliyun-sdk**、**snappy** 。注意: **aliyun-sdk** 并未使用最新版本，而是使用 0.3.6, 详情戳这里 [issue](https://github.com/aliyun/aliyun-oss-ruby-sdk/issues/40)

    ```
    gem install -v 0.3.6 aliyun-sdk
    gem install snappy
    ```
5. 集成 **aliyun-sdk**，编辑 _logstash-input-alioss.gemspec_，添加依赖

    ```
    s.add_runtime_dependency 'aliyun-sdk', '~> 0.3.6'
    s.add_runtime_dependency 'snappy'
    ```
    
6. 打包工程 

    ```
    bundle install
    ```

7. 修改 _logstash/Gemfile_ 
    
    ```
    echo 'gem "logstash-input-alioss", :path => "logstash-input-alioss绝对路径"' >> logstash路径/Gemfile
    ```
    
8. 安装插件 
    
    ```
    logstash-plugin install --no-verify
    ```

9. 测试插件
    
    ```
    logstash -e 'input { alioss { } } output { stdout {codec=>rubydebug} }'
    ```
