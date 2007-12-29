require "#{File.dirname(__FILE__)}/spec_helper"

describe Lsof do
  include WaitFor
  include FileUtils
  attr_reader :port, :pid_of_process
  before do
    @port = 6666
  end

  after do
    hide_error_stream do
      Lsof.kill port
    end

    rm_rf "lsof.pid"
  end

  def start_process_using_port
    Thread.start do
      cmd = <<-CMD
        ruby -e '
                  File.open("lsof.pid", "w") do |file|
                    file.print Process.pid.to_s
                  end
                  require "rubygems"
                  require "eventmachine"
                  EventMachine::run do
                    EventMachine::start_server "127.0.0.1", #{port}, EventMachine::Protocols::LineAndTextProtocol
                  end
                '2>&1
      CMD
      `#{cmd}`
    end
    wait_for do
      Lsof.running?(port)
    end
    @pid_of_process = Integer(File.read("lsof.pid"))
    pid_of_process.should_not be_nil
    pid_of_process.class.should == Fixnum
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
    it "when there is a process is using the port, returns true" do
      start_process_using_port
      Lsof.running?(port).should be_true
    end

    it "when there is no process using the port, returns false" do
      Lsof.running?(port).should be_false
    end
  end

  describe ".listener_pid" do
    it "when there is a process listening on a port, returns the process id" do
      start_process_using_port
      pid = Lsof.listener_pid(port)
      pid.should == pid_of_process
    end

    it "when there is no process listening on a port, returns nil" do
      Lsof.listener_pid(port).should == nil
    end
  end
end