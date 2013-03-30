require 'em-websocket'
require 'thread'

module Fluent
  puts "plugin started!"
  $lock = Mutex::new
  $channel = EM::Channel.new

  class WebSocketOutput < Fluent::Output
    Fluent::Plugin.register_output('websocket', self)
    config_param :use_msgpack, :bool, :default => false
    config_param :port, :integer, :default => 8080
    config_param :add_time, :bool, :default => false
    config_param :add_tag, :bool, :default => true
    config_param :debug, :bool, :default => false

    def configure(conf)
      super
      $thread = Thread.new do
      EM.run {
        EM::WebSocket.run(:host => "0.0.0.0", :port => @port) do |ws|
          ws.onopen { |handshake|
            callback = @use_msgpack ? proc{|msg| ws.send_binary(msg)} : proc{|msg| ws.send(msg)}
            $lock.synchronize do
              sid = $channel.subscribe {|msg| callback.call msg}
              if @debug then puts "WebSocket connection: ID " + sid.to_s end
              ws.onclose {
                if @debug then puts "Connection closed: " + sid.to_s end
                $lock.synchronize do
                  $channel.unsubscribe(sid)
                end
              }
            end

            #ws.onmessage { |msg|
            #}
          }
        end
      }
      end
    end

    def start
      super
    end

    def shutdown
      super
      Thread::kill($thread)
    end

    def emit(tag, es, chain)
      chain.next
      es.each {|time,record|
        data = [record]
        if (@add_time) then data.unshift(time) end
        if (@add_tag) then data.unshift(tag) end
        output = @use_msgpack ? data.to_msgpack : data.to_json
        $lock.synchronize do
          $channel.push output
        end
      }
    end
  end
end
