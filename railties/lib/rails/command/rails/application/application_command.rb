require "rails/generators"
require "rails/generators/rails/app/app_generator"

module Rails
  module Generators
    class AppGenerator # :nodoc:
      # We want to exit on failure to be kind to other libraries
      # This is only when accessing via CLI
      def self.exit_on_failure?
        true
      end
    end
  end

  module Command
    class ApplicationCommand < Base
      def perform(*)
        # Output:
        # create  public/Users/kasperhansen/Documents/code/rails/railties/lib/rails/generators/rails/app/templates/public/favicon.ico
        # create  public/Users/kasperhansen/Documents/code/rails/railties/lib/rails/generators/rails/app/templates/public/robots.txt

        # Think it expects the command on ARGV.
        args = Rails::Generators::ARGVScrubber.new(ARGV).prepare!
        Rails::Generators::AppGenerator.start args
      end
    end
  end
end
