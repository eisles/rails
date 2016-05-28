require "thor"
require "erb"

require "active_support/core_ext/string/filters"
require "active_support/core_ext/string/inflections"

require "rails/command/actions"

module Rails
  module Command
    class Base < Thor
      class Error < Thor::Error # :nodoc:
      end

      include Actions

      # Tries to get the description from a USAGE file one folder above the command
      # root.
      def self.desc(usage = nil, description = nil)
        if usage
          super
        else
          @desc ||= ERB.new(File.read(usage_path)).result(binding) if usage_path
        end
      end

      # Convenience method to get the namespace from the class name. It's the
      # same as Thor default except that the Command at the end of the class
      # is removed.
      def self.namespace(name = nil)
        if name
          super
        else
          @namespace ||= super.chomp("_command").sub(/:command:/, ":")
        end
      end

      # Convenience method to hide this command from the available ones when
      # running rails command.
      def self.hide!
        Rails::Command.hide_namespace namespace
      end

      def self.inherited(base) #:nodoc:
        super

        if base.name && base.name !~ /Base$/
          Rails::Command.subclasses << base
        end
      end

      def self.perform(args, config) # :nodoc:
        # Pass Thor the command to dispatch unless it's help.
        runnable = command_name unless Thor::HELP_MAPPINGS.include?(args.first)

        dispatch(runnable, args.dup, nil, config)
      end

      def help(command = self.class.command_name, *)
        self.class.command_help(shell, command)
      end

      protected
        # Use Rails' default banner.
        def self.banner(*)
          "bin/rails #{command_name} #{arguments.map(&:usage).join(' ')} [options]".squish!
        end

        # Sets the base_name taking into account the current class namespace.
        #
        #   Rails::Command::TestCommand.base_name # => 'rails'
        def self.base_name
          @base_name ||= begin
            if base = name.to_s.split("::").first
              base.underscore
            end
          end
        end

        # Return command name without namespaces.
        #
        #   Rails::Command::TestCommand.command_name # => 'test'
        def self.command_name
          @command_name ||= begin
            if command = name.to_s.split("::").last
              command.chomp!("Command")
              command.underscore
            end
          end
        end

        # Path to lookup a USAGE description in a file.
        def self.usage_path
          if default_command_root
            path = File.join(default_command_root, "USAGE")
            path if File.exist?(path)
          end
        end

        # Default file root to place extra files a command might need, placed
        # one folder above the command file.
        #
        # For a `Rails::Command::TestCommand` placed in `rails/command/test_command.rb`
        # would return `rails/test`.
        def self.default_command_root
          path = File.expand_path(File.join(base_name, command_name), __dir__)
          path if File.exist?(path)
        end

        # Allow the command method to be called perform.
        def self.create_command(meth)
          if meth == "perform"
            alias_method command_name, meth
          else
            # Prevent exception about command without usage.
            # Some commands define their documentation differently.
            @usage ||= ""
            @desc  ||= ""

            super
          end
        end
    end
  end
end
