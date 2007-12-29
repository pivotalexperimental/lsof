class Lsof
  class << self
    def kill(port)
      pid = listener_pid(port)
      system "kill -9 #{pid}" unless pid.empty?
    end

    def running?(port)
      !listener_pid(port).empty?
    end

    protected

    def listener_pid(port)
      `lsof -i tcp:#{port} | grep '(LISTEN)' | awk '{print $2}'`
    end
  end
end