require 'json'
require 'msgpack'
require 'fluent/test'
require 'fluent/plugin/out_websocket'
require 'websocket-eventmachine-client'

class WebSocketForTest
  def initialize(key, n)
    @n_received = 0
    @v_received = []

    @ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://localhost:8080')
    @ws.onmessage do |msg, type|
      #puts "Received message: #{msg.to_s} / #{type.to_s}"
      data = type == :text ? JSON.parse(msg): MessagePack.unpack(msg)
      @v_received.push(data[0][key])
      @n_received += 1
      if (n == @n_received)
        @ws.close()
      end
    end
  end

  attr_reader :n_received, :v_received
end

class WebSocketOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    v_str = "sekaiichi kawaiiyo"
    v_int = -1234567
    v_double = -123.4567
    @key = "key"
    @values = [v_str, v_int, v_double]
  end

  CONFIG = %[
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::OutputTestDriver.new(Fluent::WebSocketOutput).configure(conf)
  end

  def impl_test(d)
    sleep(0.2)
    ws = WebSocketForTest.new(@key, @values.length)
    sleep(0.2)
    for v in @values
      d.emit({@key => v}, 0)
    end
    sleep(0.5)
    assert_equal(@values.length, ws.n_received)
    result = ws.v_received
    for i in 0 .. @values.length
      assert_equal(@values[i], result[i])
    end
  end

  # TODO: How to test another configuration?
  #def test_json_out
    #d = create_driver %[
      #use_msgpack false
      #add_tag false
    #]
    #impl_test(d)
  #end

  def test_msgpack_out
    d = create_driver %[
      use_msgpack true
      add_tag false
    ]
    impl_test(d)
  end

end
