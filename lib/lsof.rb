class Lsof
  class << self
    def kill(port)
      pid = listener_pid(port)
      system "kill -9 #{pid}" if pid
    end

    def running?(port)
      listener_pid(port) ? true : false
    end

    def listener_pid(port)
      port = `lsof -i tcp:#{port} | grep '(LISTEN)' | awk '{print $2}'`
      if port.empty?
        nil
      else
        Integer(port)
      end
    end
  end
end