require "#{File.dirname(__FILE__)}/spec_helper"

describe Lsof do
  include WaitFor
  include FileUtils
  attr_reader :port, :process_pids
  before do
    @port = 6666
    @process_pids = []
  end

  after do
    hide_error_stream do
      Lsof.kill port
    end

    rm_rf "lsof.pid"
  end

  def start_process_using_port
    Thread.start do
      dir = File.dirname(__FILE__)
      system("ruby #{dir}/fixtures/test_server.rb -p #{port} -f lsof")
    end
    wait_for do
      Lsof.running?(port)
    end
    process_pids << Integer(File.read("lsof.pid"))
    process_pids << Integer(File.read("lsof_1.pid"))
    process_pids << Integer(File.read("lsof_2.pid"))
    process_pids.compact!
    process_pids.length.should == 3
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
      sleep 1
      Lsof.running?(port).should be_false
    end
  end
  
  describe ".running_remotely?" do
    it "should return true when there is a process on the port" do
      start_process_using_port
      Lsof.running_remotely?("localhost", port).should be_true
    end

    it "should return false when there is no process on the port" do
      wait_for do
        !Lsof.running_remotely?("localhost", port)
      end
      Lsof.running_remotely?("localhost", port).should be_false
    end
  end

  describe ".listener_pids" do
    it "when there is a process listening on a port, returns the process id in an Array" do
      start_process_using_port
      pids = Lsof.listener_pids(port)
      pids.should == process_pids
    end

    it "when there is no process listening on a port, returns []" do
      Lsof.listener_pids(port).should == []
    end
  end
end
