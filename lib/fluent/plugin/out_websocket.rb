# Copyright (C) 2013 IZAWA Tetsu (@moccos)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'em-websocket'
require 'thread'

module Fluent
  $lock = Mutex::new
  $channel = EM::Channel.new

  class WebSocketOutput < Fluent::Output
    Fluent::Plugin.register_output('websocket', self)
    config_param :use_msgpack, :bool, :default => false
    config_param :host, :string, :default => "0.0.0.0"
    config_param :port, :integer, :default => 8080
    config_param :add_time, :bool, :default => false
    config_param :add_tag, :bool, :default => true
    config_param :sampling_interval, :integer, :default => 0
    config_param :sampling_probability, :integer, :default => -1

    ### private methods
    def make_filter()
      if (@sampling_interval > 0) then
        @interval_counter = 0
        lambda {||
          @interval_counter = (@interval_counter + 1) % @sampling_interval
          (@interval_counter == 0)
        }
      elsif (@sampling_probability > 0) then
        lambda {||
          #r = Random.rand(1 .. 100)
          #puts @sampling_probability.to_s + " / " + r.to_s
          #@sampling_probability > r
          @sampling_probability > Random.rand(1 .. 100)
        }
      else
        lambda {|| true}
      end
    end
    private :make_filter

    def ws_open(ws)
      ws.onopen { |handshake|
        callback = @use_msgpack ? proc{|msg| ws.send_binary(msg)} : proc{|msg| ws.send(msg)}
        $lock.synchronize do
          sid = $channel.subscribe callback
          $log.trace "WebSocket connection: ID " + sid.to_s
          ws.onclose {
            $log.trace "Connection closed: ID " + sid.to_s
            $lock.synchronize do
              $channel.unsubscribe(sid)
            end
          }
        end

        #ws.onmessage { |msg|
        #}
      }
    end
    private :ws_open

    ### Fluentd interface methods
    def configure(conf)
      super
      $thread = Thread.new do
      $log.trace "Started em-websocket thread."
      $log.info "WebSocket server #{@host}:#{@port} [msgpack: #{@use_msgpack}]"
      @filter = make_filter()
      EM.run {
        EM::WebSocket.run(:host => @host, :port => @port) do |ws| ws_open(ws) end
      }
      
      end
    end

    def start
      super
    end

    def shutdown
      super
      EM.stop
      Thread::kill($thread)
      $log.trace "Killed em-websocket thread."
    end

    def emit(tag, es, chain)
      chain.next
      es.each {|time,record|
        data = [record]
        if (@add_time) then data.unshift(time) end
        if (@add_tag) then data.unshift(tag) end
        output = @use_msgpack ? data.to_msgpack : data.to_json
        if @filter != nil and @filter.() then
          $lock.synchronize do
            $channel.push output
          end
        end
      }
    end
  end
end
