require "rubygems"
require "spec"
dir = File.dirname(__FILE__)
$LOAD_PATH.unshift File.expand_path("#{dir}/../lib")
require "lsof"
require "rr"
require "fileutils"
require "eventmachine"

Spec::Runner.configure do |config|
  config.mock_with :rr
end

module WaitFor
  def wait_for(seconds=5)
    Timeout.timeout(seconds) do
      loop do
        break if yield
      end
    end
  end
end