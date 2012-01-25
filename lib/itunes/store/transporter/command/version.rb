require "optout"
require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command
        
        ## 
        # Return the `iTMSTransporter` version.
        #
        class Version < Base
          protected
          def options
            Optout.options { on :version, "-version", :default => true }
          end
          
          def handle_success(stdout_lines, stderr_lines, options)
            super =~ /\s+(\d+(?:\.\d+)*)$/ ? $1 : "Unknown"
          end
        end
      end
    end
  end
end
