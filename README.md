# Cbreaker

Cbreaker is a ruby gem that implements circuit breaker pattern as described in http://martinfowler.com/bliki/CircuitBreaker.html.

###Storage:
It comes with support for both in-memory and centralized storage.

In distributed server setup you can prefer to use centralised storage option to make your service detect the failure asap.

Currently only redis is being supported as centralized storage. However it is easy to integrate any other cache service.

Check and implement methods in cbreaker/data_store/redis.  

For error reporting/ notification it comes with new relic support. However other notification can easily be integrated in cbreaker/notifier/. Check cbreaker/notifier/newrelic for more details. 


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cbreaker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cbreaker

## Usage

###Configurations:

Following parameters are configurable:

failure_threshold, retry_timeout, timeout

To enable new relic monitoring: 

	cbreaker_options["monitoring"]: true
	
To add extra params for monitoring:

	cbreaker_options["monit_hash"]: {"app": "some app name", "endpoint": "app_name"}
	
To add cbreaker log in your app, mention your app logger.

	cbreaker_options["logger"]=app_logger
	
To exclude the exceptions from opening the the circuit:

	cbreaker_options["excluded_exceptions"] = ['exception1', 'exception2']

###Execution:

cbreaker = Cbreaker('cbreaker_name', cbreaker_options, $data_store)

	cbreaker.run do
		#Code you want to wrap under circuit breaker 
	end

Here in data_store you will have to provide the redis connection.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cbreaker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

