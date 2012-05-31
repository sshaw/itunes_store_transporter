require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command            # :nodoc: all
        
        ## 
        # Return the +iTMSTransporter+ version.
        #
        class Version < Base
          def initialize(*config)
            super
            options.on :version, "-version"
          end

          protected
          def create_transporter_options(optz)
            optz[:version] = true
            super
          end
          
          def handle_success(stdout_lines, stderr_lines, options)
            super =~ /version\s+(\d+(?:\.\d+)*)\b/i ? $1 : "Unknown"
          end
        end
      end
    end
  end
end
