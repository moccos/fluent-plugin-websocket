# Fluent::Plugin::Websocket

Fluentd websocket output plugin.

## Installation

Copy __out_websocket.rb__ into your fluentd plugin directory.

Default plugin directory is _/etc/fluent/plugin_. You can specify additional location by _-p_ option. (Please see _fluentd -h_)

This plugin depends on [__em-websocket__](https://github.com/igrigorik/em-websocket) module. You can  install it by _gem install em-websocket_.


## Configuration
    <match foo.**>
      type websocket
      port 8080         # default: 8080
      use_msgpack false # default: false
      add_time false    # default: false
      add_tag true      # default: true
    </match>

- __port__: WebSocket listen port.
- __use\_msgpack__: Send [MessagePack](http://msgpack.org/) format binary. Otherwise, you send JSON format text.
- __add\_time__: Add timestamp to the data.
- __add\_tag__: Add fluentd tag to the data.

If there are no websocket connections, this plugin silently discards data. You may use _out\_copy_ plugin like this:

    <match foo.**>
      type copy
      <store>
        type file
        path /var/log/foo/bar.log
      </store>
      <store>
        type websocket
        port 8080
      </store>
    </match>

## Data format
    [tag, timestamp, data_object]

- tag is appended when _add\_tag_ option is true.
- timespamp is appended when _add\_time_ option is true.

### Example
    curl -X POST -d 'json={"action":"login","user":6}' http://localhost:8888/foo/bar

    ["foo.bar",1364699026,{"action":"login","user":6}]

## Client sample
### JSON format (use_msgpack: false)
    function onMessage(evt) {
      data = JSON.parse(evt.data);
      ...
    }

### Msgpack format binary (use_msgpack: true)
Extract data by [msgpack.js](https://github.com/msgpack/msgpack-javascript).

    websocket.binaryType = "arraybuffer"
    ...
    function onMessage(evt) {
      data = msgpack.unpack(new Uint8Array(evt.data))
      ...
    }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

