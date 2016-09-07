module Cbreaker
	class << self
		def repo
      		@repo
    	end
		def repo=(repo)
      		@repo = repo
    	end
	end
end

require_relative "cbreaker/version"
require_relative 'cbreaker/data_store/redis'
require_relative 'cbreaker/data_store/in_memory'
require_relative 'cbreaker/notifier/newrelic'
require_relative 'cbreaker/state'
require_relative 'cbreaker/circuit'


def Cbreaker(name, options, data_store=nil)
	data_store ||=  Cbreaker::DataStore::InMemory.instance
	Cbreaker::Circuit.new(name, options, data_store)
end
