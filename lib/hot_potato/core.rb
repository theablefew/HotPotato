require 'logger'
require 'snappy'

module HotPotato
  
  module Core

    CONFIG_PATH = "#{APP_PATH}/config/config.yml"

    def set_logger(provider, options = {})
      if provider == :queue_logger
        @@hot_potato_log ||= QueueLogger.new(options)
      else
        @@hot_potato_log ||= Logger.new(STDOUT)
      end
    end

    def log
      @@hot_potato_log ||= Logger.new(STDOUT)
      @@hot_potato_log.level = Logger::INFO
      return @@hot_potato_log
    end

    def config
      @@config ||= YAML.load_file(CONFIG_PATH)[RACK_ENV]
    end
      
    def stat
      @@cache ||= Cache.new
    end
      
    def queue_inject(name, message)
      @@queue ||= Redis.new (config['redis']) #:host => config['redis_hostname'], :port => config['redis_port'], :db => config['redis_db']
      @@queue.rpush name.to_sym, Snappy.deflate(message.to_json)
    end
    
    def queue_subscribe(name, &block) 
      queue ||= Redis.new (config['redis']) #:host => config['redis_hostname'], :port => config['redis_port'], :db => config['redis_db']
      while true
        message = queue.blpop(name.first.to_sym, 0).tap do |channel, message|
          yield JSON.parse(Snappy.inflate(message))
        end
      end
    end
      
    def acquire_lock(key, duration = 10)
      if !stat.getset("hotpotato.lock.#{key.to_s}", "1")
        stat.expire "hotpotato.lock.#{key.to_s}", duration
        return true
      else
        stat.expire "hotpotato.lock.#{key.to_s}", duration
        return false
      end
    end
    
    def release_lock(key)
      stat.del("hotpotato.lock.#{key.to_s}")
    end  
      
  end
  
end
