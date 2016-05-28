module Rails
  module Command
    class RunnerCommand < Base
      class_option :environment, aliases: "-e", type: :string,
        default: Rails::Command.environment.dup,
        desc: "The environment for the runner to operate under (test/development/production)"

      def self.banner(*)
        "bin/rails runner [options] [<'Some.ruby(code)'> | <filename.rb>]"
      end

      def self.command
        "bin/rails runner"
      end

      def perform(code_or_file)
        ENV["RAILS_ENV"] = options[:environment]

        require APP_PATH
        Rails.application.require_environment!
        Rails.application.load_runner

        if File.exist?(code_or_file)
          $0 = code_or_file
          Kernel.load code_or_file
        else
          begin
            eval(code_or_file, binding, __FILE__, __LINE__)
          rescue SyntaxError, NameError
            $stderr.puts "Please specify a valid ruby command or the path of a script to run."
            $stderr.puts "Run '#{self.class.command} -h' for help."
            exit 1
          end
        end
      end
    end
  end
end
