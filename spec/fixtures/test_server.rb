require "optparse"
require "rubygems"
require "eventmachine"
require "timeout"

$port = nil
$pid_file = nil
options ||= OptionParser.new do |o|
  o.on('-p', '--port=PORT') do |port_from_user|
    $port = Integer(port_from_user)
  end

  o.on('-f', '--pid_file=PID_FILE') do |pid_file_from_user|
    $pid_file = pid_file_from_user
  end
end
options.parse!

class NoopServer < EventMachine::Connection
end

def create_pid_file(pid_file)
  File.open(pid_file, "w") do |file|
    file.print Process.pid.to_s
  end
end

EventMachine::run {
  EventMachine::start_server "localhost", $port, NoopServer

  create_pid_file "#{$pid_file}.pid"
  fork do
    create_pid_file "#{$pid_file}_1.pid"
    sleep
  end
  fork do
    create_pid_file "#{$pid_file}_2.pid"
    sleep
  end

  Timeout.timeout(5) do
    File.exists?("#{$pid_file}.pid") && File.exists?("#{$pid_file}_1.pid") && File.exists?("#{$pid_file}_2.pid")
  end
}
