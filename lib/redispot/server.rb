require 'timeout'

module Redispot
  class Server
    using Refinements

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
      @config     = config.symbolize_keys
      @timeout    = timeout
      @workdir    = WorkingDirectory.new(tmpdir)

      if @config[:port].nil? && @config[:unixsocket].nil?
        @config[:unixsocket] = "#{@workdir}/redis.sock"
        @config[:port]       = 0
      end

      if @config[:dir].nil?
        @config[:dir] = @workdir
      end

      if @config[:loglevel].to_s == 'warning'
        $stderr.puts 'Redispot::Server does not support "loglevel warning", using "notice" instead.'
        @config[:loglevel] = 'notice'
      end

      start(&block) if block
    end

    # Start redis-server instance manually.
    # If block given, the redis instance is available only within a block.
    # Users must call Redispot::Server#stop they have called Redispot::Server#start without block.
    #
    # @example
    #   redispot.start do |connect_info|
    #     redis = Redis.new(connect_info)
    #     assert_equal('PONG', redis.ping)
    #   end
    #
    #   # or
    #
    #   connect_info = redispot.start
    #
    # @overload start { ... }
    #   @yield [connect_info] Connection info for client library to connect this redis-server instance.
    #   @yieldparam connect_info [Hash] This parameter is designed to pass directly to Redis module.
    # @overload start
    #   @return connect_info [Hash] This parameter is designed to pass directly to Redis module.
    def start
      return if @pid
      start_process

      if block_given?
        begin
          yield connect_info
        ensure
          stop
        end
      else
        connect_info
      end
    end

    # Stop redis-server.
    # This method is automatically called from object destructor.
    #
    def stop
      return unless @pid

      signals = [:TERM, :INT, :KILL]

      begin
        Process.kill(signals.shift, @pid)
        Timeout.timeout(@timeout) { Process.waitpid(@pid) }
      rescue Timeout::Error => error
        retry unless signals.empty?
        raise error
      end

      @pid = nil

      ObjectSpace.undefine_finalizer(self)
    end

    # Return connection info for client library to connect this redis-server instance.
    #
    # @example
    #   redispot = Redispot::Server.new
    #   redis    = Redis.new(redispot.connect_info)
    #
    # @return [String] This parameter is designed to pass directly to Redis module.
    def connect_info
      host = @config[:bind].presence || '0.0.0.0'
      port = @config[:port]

      if port.is_a?(Fixnum) && port > 0
        { url: "redis://#{host}:#{port}/" }
      else
        { path: @config[:unixsocket] }
      end
    end

    private
    #
    def start_process
      logfile = "#{@workdir}/redis-server.log"

      execute_redis_server(logfile)
      wait_redis_server(logfile)
      ObjectSpace.define_finalizer(self, Killer.new(@pid, @timeout))
    end

    #
    # @param logfile [Pathname]
    def execute_redis_server (logfile)
      File.open(logfile, 'a') do |fh|
        @pid = Process.fork do
          configfile = "#{@workdir}/redis.conf"
          File.write(configfile, config_string)

          begin
            Kernel.exec(@executable, configfile, out: fh, err: fh)
          rescue SystemCallError => error
            $stderr.puts "exec failed: #{error}"
            exit error.errno
          end
        end
      end
    rescue SystemCallError => error
      $stderr.puts "failed to create log file: #{error}"
    end

    #
    # @param logfile [Pathname]
    def wait_redis_server (logfile)
      Timeout.timeout(@timeout) do
        while Process.waitpid(@pid, Process::WNOHANG).nil?
          return if File.read(logfile) =~ /the server is now ready to accept connections/i
          sleep 0.1
        end

        @pid = nil
        raise Timeout::Error
      end
    rescue Timeout::Error
      raise RuntimeError, "failed to launch redis-server\n#{File.read(logfile)}"
    end

    #
    # @return [String]
    def config_string
      @config.each_with_object(String.new) do |(key, value), memo|
        next if value.to_s.empty?
        memo << "#{key} #{value}\n"
      end
    end


    class Killer  # :nodoc
      def initialize (redis_pid, timeout = 3)
        @owner_pid = Process.pid
        @redis_pid = redis_pid
        @timeout   = timeout
      end

      def call (*args)
        return if @owner_pid != Process.pid

        signals = [:TERM, :INT, :KILL]

        begin
          Process.kill(signals.shift, pid)
          Timeout.timeout(timeout) { Process.waitpid(pid) }
        rescue Timeout::Error => error
          retry unless signals.empty?
          raise error
        end
      end
    end

  end
end
