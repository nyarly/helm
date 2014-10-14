module Wheelhouse
  class Uptime < ServerCommand
    def name
      "uptime"
    end

    def description
      "Check the load on multiple servers"
    end

    def command(server)
      ssh(server, "uname -a; uptime")
    end

    def format_result(execution)
      puts "#{execution.server.name} (#{execution.server.public_ip_address})"
      puts execution.result.stdout
      puts
    end
  end
end
