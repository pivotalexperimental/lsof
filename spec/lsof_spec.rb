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
      src = <<-SRC
        def start_server(pid_file)
          File.open(pid_file, "w") do |file|
            file.print Process.pid.to_s
          end
          require "rubygems"
          require "eventmachine"
          EventMachine::run do
            EventMachine::start_server "127.0.0.1", #{port}, EventMachine::Protocols::LineAndTextProtocol
          end
        end

        start_server "lsof.pid"
      SRC
      `ruby -e '#{src}' 2>&1`
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
    describe "when there is only one process listening to the port" do
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

  describe ".listener_pids" do
    it "when there is a process listening on a port, returns the process id in an Array" do
      start_process_using_port
      pid = Lsof.listener_pids(port)
      pid.should == [pid_of_process]
    end

    it "when there is no process listening on a port, returns []" do
      Lsof.listener_pids(port).should == []
    end
  end
end
