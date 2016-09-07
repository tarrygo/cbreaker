require 'timeout'
require 'newrelic_rpm'
module Cbreaker
	class Circuit
		
		attr_reader :data_store
		attr_reader :name
		attr_accessor :failure_threshold
		attr_accessor :timeout
		attr_accessor :retry_timeout
		attr_accessor :monitoring
		attr_accessor :monit_hash
		attr_accessor :notifier
		attr_accessor :state
		attr_accessor :failure_count
		attr_accessor :excluded_exceptions
		attr_accessor :logger
		class << self
      		attr_accessor :default_data_store
        end
        CircuitOpenError = Class.new RuntimeError
        CircuitBrokenError = Class.new RuntimeError

		def initialize(name, options, data_store)
			@name = name
			@timeout = options[:timeout] || 10
			@failure_threshold = options[:failure_threshold] || 10
			@retry_timeout = options[:retry_timeout] || 30
      		@data_store = data_store
      		@excluded_exceptions = options[:excluded_exceptions]
			@logger = options[:logger]
			@monitoring = options[:monitoring]
      		@monit_hash = options[:monit_hash]
      		
      		cbreaker_hash = cb_params(options)
      		@data_store.upsert(cbreaker_hash)
      		if monitoring
      			notify_hash = cbreaker_hash.merge(monit_hash)
      			@notifier = Notifier::Newrelic.new(notify_hash)
      		end
		end

		def run
			current_time = Time.now.to_i
			current_state = state(current_time)
			if current_state == State::CLOSED || current_state == State::HALF_OPEN
				begin
		        	result = Timeout.timeout(timeout, CircuitBrokenError) do
		        		yield
		        	end
		        	close 
					result
		        rescue Exception => e
		        	if @excluded_exceptions.nil? or !(@excluded_exceptions.include? e.class or @excluded_exceptions.include? e.class.to_s)
		        		if tripped?
		        			open(current_time, e.message) 
		        		else
		        			record_failure(e.message)
		        		end
		        	end
		          	raise e
		        end
	      	else
	        	raise CircuitOpenError, "Circuit is open for #{name}. Please wait for #{retry_timeout} secs!"
	      	end
		end

		def state(current_time)
			obj = data_store.get_all(name)
			if obj["state"] == State::CLOSED
				return State::CLOSED
			elsif current_time >  obj["retry_threshold"].to_i
				return State::HALF_OPEN
			else
				return State::OPEN
			end
		end

		def open(time, exception)
			retry_threshold = time + retry_timeout
			data_store.open(name, retry_threshold)
			logger.error "Cbreaker: OPENING_CIRCUIT: circuit: #{name}; failure_count: #{failure_count}" if logger
			notifier.notify(status: State::OPEN, exception: exception, failure_count: failure_threshold+1)	if monitoring
		end

		def close
			count = data_store.failure_count(name)
			data_store.close(name)
			if(count>0)
				logger.info "Cbreaker: CLOSING_CIRCUIT: circuit: #{name};" if logger
				notifier.notify(status: State::CLOSED, earlier_failure_count: count) if monitoring
			end
		end

		def tripped?
			count = data_store.failure_count(name)
			if count >= failure_threshold
				return true
			end
			return false
		end

		def record_failure(exception)
			count = data_store.record_failure(name)
			logger.debug "Cbreaker: RECORDING_FAILURE: circuit: #{name}; failure_count: #{count}; exception: #{exception}" if logger
			notifier.notify(status: State::FAIL, exception: exception, failure_count: count)	if monitoring
		end

		private

		def cb_params(options) 
			cbreaker_hash = {}
			cbreaker_hash[:name] = @name
			cbreaker_hash[:timeout] = options[:timeout]
			cbreaker_hash[:failure_threshold] = options[:failure_threshold]
			cbreaker_hash[:retry_timeout] = options[:retry_timeout]
			cbreaker_hash
		end
	end
end
