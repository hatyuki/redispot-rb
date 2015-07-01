# Redispot

[![Gem Version](https://badge.fury.io/rb/redispot.svg)](http://badge.fury.io/rb/redispot)
[![Build Status](https://travis-ci.org/hatyuki/redispot-rb.svg?branch=master)](https://travis-ci.org/hatyuki/redispot-rb)
[![Code Climate](https://codeclimate.com/github/hatyuki/redispot-rb/badges/gpa.svg)](https://codeclimate.com/github/hatyuki/redispot-rb)

Launching the redis-server instance which is available only within a block.
It is useful when you want to test your code.
It is a Ruby clone of [Test::RedisServer](https://github.com/typester/Test-RedisServer).


## Synopsis
```ruby
require 'redis'
require 'redispot'

Redispot::Server.new do |connect_info|
  redis = Redis.new(connect_info)
  redis.ping  # => "PONG"
end
```


## Methods
### Redispot::Server.new(options)
Create a new instance, and start redis-server if block given.

```ruby
redis_server = Redispot::Server.new(options)

# or

Redispot::Server.new(options) do |connect_info|
  redis = Redis.new(connect_info)
  # ...
end
```

Available options are:

- [Hash] config

    This is a `redis.conf` key value pair. You can use any key-value pair(s) that redis-server supports.

    If you want to use this redis.conf:

    ```
    port 9999
    databases 16
    save 900 1
    ```

    Your conf parameter will be:

    ```ruby
    Redispot::Server.new(config: {
        port:      9999,
        databases: 16,
        save:      '900 1',
    })
    ```

- [Fixnum] timeout (Default: 3)

    Timeout seconds for detecting if redis-server is awake or not.

- [String] tmpdir

    Temporal directory, where redis config will be stored.


### Redispot::Server#start
Start redis-server instance manually.

```ruby
server = Redispot::Server.new
server.start do |connect_info|
  redis = Redis.new(connect_info)
  redis.ping  # => "PONG"
end
```


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'redispot'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redispot


## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/hatyuki/redispot-rb.


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
