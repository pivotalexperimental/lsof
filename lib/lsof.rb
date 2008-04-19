class Lsof
  class << self
    def kill(port)
      pid = listener_pids(port)
      `#{find_pids_cmd(port)} | xargs kill 2>&1`
    end

    def running?(port)
      listener_pids(port).empty? ? false : true
    end

    def listener_pids(port)
      output = `#{find_pids_cmd(port)}`
      output.split("\n").map do |port|
        Integer(port)
      end
    end

    def find_pids_cmd(port)
      "lsof -i tcp:#{port} | grep '(LISTEN)' | awk '{print $2}'"
    end
  end
end