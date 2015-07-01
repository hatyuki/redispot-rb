require 'fileutils'
require 'timeout'
require 'tmpdir'

module Redispot
  class Server

    # Destractor
    #
    # @private
    def self.destroy (pid, owner_pid, timeout)
      Proc.new do
        return if pid.nil? || owner_pid != Process.pid

        signals = [:TERM, :INT, :KILL]

        begin
          Process.kill(signals.shift, pid)
          Timeout.timeout(timeout) { Process.waitpid(pid) }
        rescue Timeout::Error
          retry
        end
      end
    end

    # Create a new instance, and start redis-server if block given.
    #
    # @example
    #   Redispot::Server.new do |connect_info|
    #     redis = Redis.new(connect_info)
    #     assert_equal('PONG', redis.ping)
    #   end
    #
    # @param config [Hash] This is a `redis.conf` key value pair. You can use any key-value pair(s) that redis-server supports.
    # @param timeout [Fixnum] Timeout seconds for detecting if redis-server is awake or not.
    # @param tmpdir [String] Temporal directory, where redis config will be stored.
    # @yield [connect_info] Connection info for client library to connect this redis-server instance.
    # @yieldparam connect_info [String] This parameter is designed to pass directly to Redis module.
    def initialize (config: { }, timeout: 3, tmpdir: nil, &block)
      @executable = 'redis-server'
      @owner_pid  = Process.pid
      @pid        = nil
      @workdir    = nil
      @config     = config
      @timeout    = timeout
      @tmpdir     = tmpdir.nil? ? nil : File.expand_path(tmpdir)

      if @config[:loglevel].to_s == 'warning'
        $stderr.puts 'Redispot::Server does not support "loglevel warning", using "notice" instead.'
        @config[:loglevel] = 'notice'
      end

      start(&block) if block
    end

    # Start redis-server instance.
    #
    # @example
    #   redis_server = Redispot::Server.new
    #   redis_server.start do |connect_info|
    #     redis = Redis.new(connect_info)
    #     assert_equal('PONG', redis.ping)
    #   end
    #
    # @yield [connect_info] Connection info for client library to connect this redis-server instance.
    # @yieldparam connect_info [Hash] This parameter is designed to pass directly to Redis module.
    def start
      Dir.mktmpdir(nil, @tmpdir) do |workdir|
        @workdir = workdir
        yield start_redis_server
        stop
      end
    end

    private
    def start_redis_server
      File.open(logfile, 'w') do |logfh|
        @pid = Process.fork do
          begin
            exec @executable, config_file, out: logfh, err: logfh
          rescue => error
            $stderr.puts "exec failed: #{error}"
            exit error.errno
          end
        end
      end

      begin
        Timeout.timeout(@timeout) do
          loop do
            if !Process.waitpid(@pid, Process::WNOHANG).nil?
              @pid = nil
              raise RuntimeError, "failed to launch redis-server\n#{File.read(logfile)}"
            else
              if File.read(logfile) =~ /The server is now ready to accept connections/
                ObjectSpace.define_finalizer(self, proc { stop })
                return connect_info
              end
            end

            sleep 0.1
          end
        end
      rescue Timeout::Error
        stop if @pid
        raise RuntimeError, "failed to launch redis-server\n#{File.read(logfile)}"
      end
    end

    def connect_info
      return unless @pid

      host = config[:bind].nil? ? '0.0.0.0' : config[:bind]
      port = config[:port]

      if port.is_a?(Fixnum) && port > 0
        { url: "redis://#{host}:#{port}/" }
      else
        { path: config[:unixsocket] }
      end
    end

    def stop
      return if @pid.nil? || @owner_pid != Process.pid

      signals = [:TERM, :INT, :KILL]

      begin
        Process.kill(signals.shift, @pid)
        Timeout.timeout(@timeout) { Process.waitpid(@pid) }
      rescue Timeout::Error
        retry
      end

      @pid     = nil
      @workdir = nil

      ObjectSpace.undefine_finalizer(self)
    end

    def logfile
      "#{@workdir}/redis.log"
    end

    def config_file
      config_string = config.inject('') do |memo, (key, value)|
        next if value.to_s.empty?
        memo += "#{key} #{value}\n"
      end

      "#{@workdir}/redis.conf".tap do |config_path|
        File.write(config_path, config_string)
      end
    end

    def config
      default_config.merge(@config)
    end

    def default_config
      {
        unixsocket: "#{@workdir}/redis.sock",
        dir:        "#{@workdir}/"
      }
    end

  end
end
