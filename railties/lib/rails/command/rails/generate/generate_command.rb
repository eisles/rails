require "rails/generators"

module Rails
  module Command
    class GenerateCommand < Base
      def help # :nodoc:
        Rails::Generators.help self.class.command_name
      end

      def perform(*)
        generator = args.shift
        return help unless generator

        require_application_and_environment!
        Rails.application.load_generators

        root = defined?(ENGINE_ROOT) ? ENGINE_ROOT : Rails.root
        Rails::Generators.invoke generator, args, behavior: :invoke, destination_root: root
      end
    end
  end
end
