# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-websocket"
  gem.version       = "0.1.7"
  gem.authors       = ["IZAWA Tetsu (@moccos)"]
  gem.email         = ["tt.izawa@gmail.com"]
  gem.homepage      = "https://github.com/moccos/fluent-plugin-websocket"
  gem.summary       = %q{Fluentd websocket output plugin}
  gem.description   = %q{Fluentd websocket output plugin which can output JSON string or MessagePack binary to the clients.}
  gem.required_ruby_version = ">= 1.9.2"
  gem.licenses = ["Apache License, Version 2.0"]

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"
  gem.add_development_dependency "websocket-eventmachine-client"
  gem.add_runtime_dependency "msgpack"
  gem.add_runtime_dependency "yajl-ruby"
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "em-websocket"
end
