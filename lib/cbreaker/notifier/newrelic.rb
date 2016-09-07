module Cbreaker
	module Notifier
		class Newrelic
			attr_accessor :app_name
			attr_accessor :options
			def initialize(options)
				@app_name =  NewRelic::Agent.config[:'app_name']
				@options = options
			end

			def notify(params)
				notify_hash = options.merge(params)
				::NewRelic::Agent.record_custom_event('Circuit_Breaker', notify_hash)
			end
		end
	end
end