require 'fileutils'
require 'tmpdir'

module Redispot
  class WorkingDirectory

    # Create a temporary directory
    #
    # @param basedir [String]
    def initialize (basedir = nil)
      @directory = File.expand_path(Dir.mktmpdir(nil, basedir))
      ObjectSpace.define_finalizer(self, Remover.new(@directory))
    end

    # Delete the temporary directory
    #
    def delete
      FileUtils.remove_entry_secure(@directory)
      ObjectSpace.undefine_finalizer(self)
    rescue Errno::ENOENT
    end

    # Returns path to the temporary directory
    #
    # @return [String]
    def to_s
      @directory
    end

    class Remover  # :nodoc
      def initialize (directory)
        @pid       = Process.pid
        @directory = directory
      end

      def call (*args)
        return if @pid != Process.pid
        FileUtils.remove_entry_secure(@directory)
      rescue Errno::ENOENT
      end
    end
  end
end
