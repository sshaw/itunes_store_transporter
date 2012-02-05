require "optout"
require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command            # :nodoc:
        
        ## 
        # Return the +iTMSTransporter+ version.
        #
        class Version < Base
          protected
          def initialize(*config)
            super
            options.on :version, "-version"
          end

          def create_transporter_options(optz)
            optz[:version] = true
            super optz
          end
          
          def handle_success(stdout_lines, stderr_lines, options)
            super =~ /version\s+(\d+(?:\.\d+)*)\Z/i ? $1 : "Unknown"
          end
        end
      end
    end
  end
end
