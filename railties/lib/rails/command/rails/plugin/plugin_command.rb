module Rails
  module Command
    class PluginCommand < Base
      def self.banner(*) # :nodoc:
        "bin/rails plugin new [options]"
      end

      class_option :rc, type: :boolean, default: File.join("~", ".railsrc"),
        desc: "Initialize the plugin command with previous defaults. Uses .railsrc in your home directory by default."

      class_option :no_rc, desc: "Skip evaluating .railsrc."

      def perform(type = nil, *plugin_args)
        plugin_args << "--help" unless type == "new"

        unless options.key?("no_rc") # Thor's not so indifferent access hash.
          railsrc = File.expand_path(options[:rc])

          if File.exist?(railsrc)
            extra_args = File.read(railsrc).split(/\n+/).flat_map(&:split)
            puts "Using #{extra_args.join(" ")} from #{railsrc}"
            plugin_args.insert(1, *extra_args)
          end
        end

        require "rails/generators"
        require "rails/generators/rails/plugin/plugin_generator"
        Rails::Generators::PluginGenerator.start plugin_args
      end
    end
  end
end
