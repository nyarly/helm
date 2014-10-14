module Wheelhouse
  class SingleCommand
    def initialize(server, command)
      @server, @command = server, command
    end
    attr_accessor :result
    attr_reader :server

    def to_s
      "#{server.name}: #{rendered} => #{status}"
    end

    def status
      if @result
        "\n" + @result.format_streams.gsub(/^/m,"  ")
      else
        "[unfinished]"
      end
    end

    def rendered
      @rendered ||= @command.render(server)
    end
  end
end
