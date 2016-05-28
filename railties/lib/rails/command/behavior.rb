require "active_support"

module Rails
  module Command
    module Behavior #:nodoc:
      extend ActiveSupport::Concern

      included do
        mattr_accessor :namespace
      end

      class_methods do
        # Remove the color from output.
        def no_color!
          Thor::Base.shell = Thor::Shell::Basic
        end

        # Track all command subclasses.
        def subclasses
          @subclasses ||= []
        end

        def hide_namespaces(*namespaces)
          hidden_namespaces.concat(namespaces)
        end
        alias hide_namespace hide_namespaces

        # Receives a namespace, arguments and the behavior to invoke the generator.
        # It's used as the default entry point for generate, destroy and update
        # commands.
        def invoke(namespace, args = ARGV, config = {})
          names = namespace.to_s.split(":")
          if klass = find_by_namespace(names.pop, names.any? && names.join(":"))
            args << "--help" if args.empty? && klass.arguments.any?(&:required?)
            klass.perform(args, config)
          else
            options     = sorted_groups.flat_map(&:last)
            suggestions = options.sort_by { |suggested| levenshtein_distance(namespace.to_s, suggested) }.first(3)
            msg =  "Could not find #{command_type} '#{namespace}'. "
            msg << "Maybe you meant #{ suggestions.map { |s| "'#{s}'" }.to_sentence(last_word_connector: " or ", locale: :en) }\n"
            msg << "Run `rails generate --help` for more options."
            puts msg
          end
        end

        def public_namespaces
          lookup!
          subclasses.map(&:namespace)
        end

        def print_commands
          sorted_groups.each { |b, n| print_list(b, n) }
        end

        def sorted_groups
          namespaces = public_namespaces
          namespaces.sort!

          groups = Hash.new { |h,k| h[k] = [] }
          namespaces.each do |namespace|
            base = namespace.split(":").first
            groups[base] << namespace
          end

          rails = groups.delete("rails")
          rails.map! { |n| n.sub(/^rails:/, "") }
          rails.delete("app")
          rails.delete("plugin")
          rails.delete("help")

          hidden_namespaces.each { |n| groups.delete(n.to_s) }

          [[ "rails", rails ]] + groups.sort.to_a
        end

        protected

          # This code is based directly on the Text gem implementation
          # Returns a value representing the "cost" of transforming str1 into str2
          def levenshtein_distance(str1, str2)
            s = str1
            t = str2
            n = s.length
            m = t.length

            return m if (0 == n)
            return n if (0 == m)

            d = (0..m).to_a
            x = nil

            # avoid duplicating an enumerable object in the loop
            str2_codepoint_enumerable = str2.each_codepoint

            str1.each_codepoint.with_index do |char1, i|
              e = i+1

              str2_codepoint_enumerable.with_index do |char2, j|
                cost = (char1 == char2) ? 0 : 1
                x = [
                     d[j+1] + 1, # insertion
                     e + 1,      # deletion
                     d[j] + cost # substitution
                    ].min
                d[j] = e
                e = x
              end

              d[m] = x
            end

            x
          end

          # Prints a list of generators.
          def print_list(base, namespaces) #:nodoc:
            namespaces = namespaces.reject do |n|
              hidden_namespaces.include?(n)
            end

            return if namespaces.empty?
            puts "#{base.camelize}:"

            namespaces.each do |namespace|
              puts("  #{namespace}")
            end

            puts
          end

          # Receives namespaces in an array and tries to find matching generators
          # in the load path.
          def lookup(namespaces) #:nodoc:
            paths = namespaces_to_paths(namespaces)

            paths.each do |raw_path|
              lookup_paths.each do |base|
                path = "#{base}/#{raw_path}_#{command_type}"

                begin
                  require path
                  return
                rescue LoadError => e
                  raise unless e.message =~ /#{Regexp.escape(path)}$/
                rescue Exception => e
                  warn "[WARNING] Could not load #{command_type} #{path.inspect}. Error: #{e.message}.\n#{e.backtrace.join("\n")}"
                end
              end
            end
          end

          # This will try to load any command in the load path to show in help.
          def lookup! #:nodoc:
            $LOAD_PATH.each do |base|
              Dir[File.join(base, *file_lookup_paths)].each do |path|
                begin
                  path = path.sub("#{base}/", "")
                  require path
                rescue Exception
                  # No problem
                end
              end
            end
          end

          # Convert namespaces to paths by replacing ":" for "/" and adding
          # an extra lookup. For example, "rails:model" should be searched
          # in both: "rails/model/model_generator" and "rails/model_generator".
          def namespaces_to_paths(namespaces) #:nodoc:
            paths = []
            namespaces.each do |namespace|
              pieces = namespace.split(":")
              paths << pieces.dup.push(pieces.last).join("/")
              paths << pieces.join("/")
            end
            paths.uniq!
            paths
          end
      end
    end
  end
end
