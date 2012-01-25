require "optout"
require "childprocess"
require "itunes/store/transporter"
require "itunes/store/transporter/shell"
require "itunes/store/transporter/errors"
require "itunes/store/transporter/output_parser"

module ITunes
  module Store
    class Transporter
      module Command
        
        class Base
          def initialize(config, default_options = {})
            @config = config
            @shell = Shell.new(@config[:path])
            @default_options = default_options
          end
          
          def run(options = {})
            argv = create_transporter_options(options)
            stdout_lines = []
            stderr_lines = []
           
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
              handle_error(stdout_lines, stderr_lines, exitcode, options)
            end
          end

          protected
          attr :config
          attr :default_options
          
          # TODO: conf[:warnings]
          def handle_success(stdout_lines, stderr_lines, options)
            stdout_lines.join
          end
          
          def handle_error(stdout_lines, stderr_lines, options, exitcode)
            parser = Transporter::OutputParser.new(stderr_lines)
            errors = parser.errors.any? ? parser.errors : [ TransporterMessage.new(stderr_lines.join) ]
            raise ITunes::Store::Transporter::ExecutionError.new(errors, exitcode)
          end
          
          def create_transporter_options(optz)
            options.argv(default_options.merge(optz))
          rescue Optout::OptionError => e
            raise ITunes::Store::Transporter::OptionError, e.message
          end
        end
      
        class Mode < Base
          #OPTIONS[:username]

          protected
          def options
            @options ||= Optout.options do
              on :log, "-o", Optout::File
              on :verbose, "-v", %w|off informational critical detailed eXtreme|
              on :username, "-u", :required => true
              on :password, "-p", :required => true
              on :summary, "-summaryFile", Optout::File
              on :mode, "-m", /\w+/, :required => true
             
              # On Windows we must include this else Transporter will call `pause` when an error occurs            
              on :windows, "-WONoPause"               
            
              # Will Transporter accept multiple JVM args?
              # Optout can't do this: [a, b, c] => -X a -X b -X c
              on :jvm, "-X", :multiple => true           
            end
          end
        
          def create_transporter_options(optz)
            optz = optz.dup 
            optz[:mode] = mode
            optz[:windows] = "true" if Transporter::Shell.windows?
            super optz
          end
        
          def mode
            self.class.to_s.split("::")[-1].gsub(/([a-z])([A-Z])/, "\1_\2").downcase
          end
        end

      end
    end
  end
end  
