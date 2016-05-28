require 'active_support'
require 'active_support/core_ext/enumerable'

module Rails
  module Command
    autoload :Behavior, 'rails/command/behavior'
    autoload :Base, 'rails/command/base'

    include Behavior

    def self.hidden_namespaces
      @hidden_namespaces ||= %w( rails )
    end

    def self.environment
      ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    # Rails finds namespaces similar to thor, it only adds one rule:
    #
    # Command names must end with "_command.rb". This is required because Rails
    # looks in load paths and loads the command just before it's going to be used.
    #
    #   find_by_namespace :webrat, :rails, :integration
    #
    # Will search for the following commands:
    #
    #   "rails:webrat", "webrat:integration", "webrat"
    #
    # Notice that "rails:commands:webrat" could be loaded as well, what
    # Rails looks for is the first and last parts of the namespace.
    def self.find_by_namespace(name, *) #:nodoc:
      lookups = [ name, "rails:#{name}" ]

      lookup(lookups)

      namespaces = subclasses.index_by(&:namespace)
      namespaces[(lookups & namespaces.keys).first]
    end

    protected
      def self.command_type
        @command_type ||= 'command'
      end

      def self.lookup_paths
        @lookup_paths ||= %w( rails/command command )
      end

      def self.file_lookup_paths
        @file_lookup_paths ||= [ "{#{lookup_paths.join(',')}}", "**", "*_command.rb" ]
      end
  end
end
