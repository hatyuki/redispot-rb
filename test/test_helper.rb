$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'redispot'
require 'redis'
require 'socket'
require 'test/unit'

def empty_port
  socket = TCPServer.open(0)
  port   = socket.addr[1]
  socket.close
  port
end
