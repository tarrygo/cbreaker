module Cbreaker
	module DataStore
		class Redis

			KEY_PREFIX = 'cb'.freeze
      		KEY_SEPARATOR = ':'.freeze
      		attr_accessor :redis
			def initialize(redis)
        		@redis = redis
      		end

      		def upsert(attributes)
		    	name = attributes.fetch(:name)
		      	if exist name
		      		update name, attributes
		      	else
		        	create name, attributes
			   	end
      		end

			def get_all(name)
				obj = redis.hgetall(key(name))
				obj
			end

			def get(name, field)
				redis.hget(key(name), field)
			end

			def record_failure(name)
				return redis.hincrby(key(name), "failure_count", 1)
			end

			def open(name, retry_threshold)
				redis.multi do
					redis.hmset(key(name), "state", "open", "retry_threshold", retry_threshold)
					redis.hincrby(key(name), "failure_count", 1)
				end
			end

			def close(name)
				redis.hmset(key(name), "state", "closed", "failure_count", 0)
			end

			def failure_count(name)
				redis.hget(key(name), "failure_count").to_i 
			end

			def state(name)
				redis.hget(key(name), "state")
			end

			def retry_timeout(name)
				redis.hget(key(name), "retry_timeout").to_i
			end
			private

			def exist(name)
				redis.hexists(key(name) , 'name')
			end

			def create(name, attributes)
		      	arr = []
		      	attributes.each_pair do |key, value|
		        	arr.push "#{key}", value
			    end
			    arr.push "state", "closed", "failure_count", 0
			    redis.hmset(key(name), arr)
		    end

		    def update(name, attributes)
		    	arr = []
		    	attributes.each_pair do |key, value|
		    		arr.push "#{key}", value
		    	end
		    	redis.hmset(key(name), arr)
		    end
		    
		    def key(*pieces)
		    	([KEY_PREFIX] + pieces).join(KEY_SEPARATOR)
		    end

		end
	end
end