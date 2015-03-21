require "optout"
require "itunes/store/transporter/shell"
require "itunes/store/transporter/errors"
require "itunes/store/transporter/output_parser"
require "itunes/store/transporter/command/option"

module ITunes
  module Store
    module Transporter
      module Command            # :nodoc: all

        class Base
          include Option

          def initialize(config, default_options = {})
            @config = config
            @shell = Shell.new(@config[:path])
            @default_options = default_options
          end

          def run(options = {})
            options = default_options.merge(options)
            argv = create_transporter_options(options)
            stdout_lines = []
            stderr_lines = []

            # TODO: hooks
            exitcode = @shell.exec(argv) do |line, name|
              if name == :stdout
                stdout_lines << line
                $stdout.puts line if config[:print_stdout]
              else
                stderr_lines << line
                $stderr.puts line if config[:print_stderr]
              end
            end

            if exitcode == 0
              handle_success(stdout_lines, stderr_lines, options)
            else
              handle_error(stdout_lines, stderr_lines, options, exitcode)
            end
          end

          protected

          attr :config
          attr :default_options

          def options
            @options ||= Optout.options do
              # On Windows we must include this else the Transporter batch script will call `pause` after the Transporter exits
              on :windows, "-WONoPause"
              # Optout can't do this: [a, b, c] => -X a -X b -X c
              on :jvm, "-X" #, :multiple => true
            end
          end

          # TODO: conf[:warnings]
          def handle_success(stdout_lines, stderr_lines, options)
            stdout_lines.join
          end

          def handle_error(stdout_lines, stderr_lines, options, exitcode)
            parser = OutputParser.new(stderr_lines)
            errors = parser.errors.any? ? parser.errors : [ TransporterMessage.new(stderr_lines.join) ]
            raise ExecutionError.new(errors, exitcode)
          end

          def create_transporter_options(optz)
            optz[:windows] = "true" if Shell.windows?
            options.argv(optz)
          rescue Optout::OptionError => e
            raise OptionError, e.message
          end
        end

        class Mode < Base
          def initialize(*config)
            super
            options.on :log, "-o", Optout::File
            options.on :verbose, "-v", %w|informational critical detailed eXtreme| # Since log output is critical to determining what's going on we can't include "off"
            options.on :summary, "-summaryFile", Optout::File
            options.on :mode, "-m", /\w+/, :required => true
            options.on :username, "-u", :required => true
            options.on :password, "-p", :required => true
            options.on *SHORTNAME
          end

          protected

          def create_transporter_options(optz)
            optz[:mode] = mode
            super
          end

          def mode
            self.class.to_s.split("::")[-1].gsub(/([a-z])([A-Z])/, "\1_\2").downcase
          end
        end

        class BatchMode < Mode
          BatchOption = Optout::Option.create(:package, "-f", :required => true, :validator => Optout::Dir.exists)
          PackageOption = Optout::Option.create(:package, "-f", :required => true, :validator => Optout::Dir.exists.named(/\.itmsp\z/))

          protected

          def create_transporter_options(optz)
            batch   = optz.delete(:batch)
            package = optz.delete(:package)

            argv = super

            klass = if batch == true
              BatchOption
            else
              if package !~ /\.itmsp\z/
                warn "WARNING: In version 0.3.0 directories without an itmsp extension be treated as a batch upload. " \
                     "This will result in all child directories with an itmsp extension to be uploaded. " \
                     "To prevent this behavior in 0.3.0 you must set the :batch option to false"
              end

              PackageOption
            end

            opt = klass.new(package)

            begin
              opt.validate!
            rescue Optout::OptionError => e
              raise OptionError, e.message
            end

            argv.concat(opt.to_a)
          end
        end
      end
    end
  end
end
