module Cbreaker
	module DataStore
		class InMemory
			attr_accessor :store
			
			def initialize()
        		@store = Hash.new
      		end

      		def self.instance
    			@@instance
  			end
      		
      		def get_store
      			@store
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
				store[name]
			end

			def get(name, field)
				store[name][field]
			end

			def record_failure(name)
				store[name]["failure_count"] = store[name]["failure_count"] +1
				return store[name]["failure_count"]
			end

			def open(name, retry_threshold)
				store[name]["state"] = "open"
				store[name]["retry_threshold"] = retry_threshold
				store[name]["failure_count"] += 1 
			end

			def close(name)
				store[name]["state"] = "closed"
				store[name]["failure_count"] = 0
			end

			def failure_count(name)
				store[name]["failure_count"]
			end
			@@instance = InMemory.new

		    private_class_method :new
		    
			private

			def exist(name)
				store.has_key? name
			end

			def create(name, attributes)
		      	store[name] = {}
		      	attributes.each_pair do |key, value|
		        	store[name][key] = value
			    end
			    store[name]["state"] = 'closed'
			    store[name]["failure_count"] = 0
		    end

		    def update(name, attributes)
		    	attributes.each_pair do |key, value|
		    		store[name][key] = value
		    	end
		    end

		end
	end
end