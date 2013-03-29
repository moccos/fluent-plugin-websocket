module Fluent
  require 'em-websocket'

  $channel = EM::Channel.new
  $thread = Thread.new do
  EM.run {
    EM::WebSocket.run(:host => "0.0.0.0", :port => 8081) do |ws|
      puts "EventMachine run"
      ws.onopen { |handshake|
        sid = $channel.subscribe { |msg| ws.send msg }
        puts "WebSocket connection: " + sid.to_s
        ws.onclose {
          puts "Connection closed: " + sid.to_s
          $channel.unsubscribe(sid)
        }

        ws.onmessage { |msg|
          ws.send "Pong: #{msg}"
        }
      }
    end
  }
  end

  class WebSocketOutput < Fluent::Output
    Fluent::Plugin.register_output('websocket', self)
    config_param :add_time, :bool, :default => false
    config_param :add_tag, :bool, :default => true
    config_param :port, :integer, :default => 8080

    def configure(conf)
      super
    end

    def start
      super
    end

    def shutdown
      super
      Thread::kill($thread)
    end

    # This method is called when an event reaches Fluentd.
    # 'es' is a Fluent::EventStream object that includes multiple events.
    # You can use 'es.each {|time,record| ... }' to retrieve events.
    # 'chain' is an object that manages transactions. Call 'chain.next' at
    # appropriate points and rollback if it raises an exception.
    def emit(tag, es, chain)
      chain.next
      es.each {|time,record|
        output = [record]
        if (add_time) then output.unshift(time) end
        if (add_tag) then output.unshift(tag) end
        json = output.to_json + "\n"
        $channel.push json
      }
    end
  end
end
