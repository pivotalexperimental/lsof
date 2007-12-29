require "#{File.dirname(__FILE__)}/spec_helper"

describe Lsof do
  include WaitFor
  attr_reader :port
  before do
    @port = 6666
  end

  def start_process_using_port
    Thread.start do
      cmd = <<-CMD
        ruby -e '
                  require "rubygems"
                  require "eventmachine"
                  EventMachine::run do
                    EventMachine::start_server "127.0.0.1", #{port}, EventMachine::Protocols::LineAndTextProtocol
                  end
                ' &2>1
      CMD
      `#{cmd}`
    end
    wait_for do
      Lsof.running?(port)
    end
  end

  def hide_error_stream
    old_stderr = $stderr
    begin
      $stderr = StringIO.new
      yield
    rescue Exception => e
      $stderr = old_stderr
      raise e
    ensure
      $stderr = old_stderr
    end
  end

  describe '.kill' do
    it "kills all processes associated with a provided port" do
      start_process_using_port
      hide_error_stream do
        Lsof.kill port
      end
      wait_for do
        !Lsof.running?(port)
      end
    end
  end

  describe '.running?' do
    after(:each) do
      hide_error_stream do
        Lsof.kill port
      end
    end

    it "when there is a process is using the port, returns true" do
      start_process_using_port
      Lsof.running?(port).should be_true
    end

    it "when there is no process using the port, returns false" do
      Lsof.running?(port).should be_false
    end
  end
end