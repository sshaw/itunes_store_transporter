require "itunes/store/transporter/command"
require "itunes/store/transporter/xml/status"

module ITunes
  module Store
    module Transporter
      module Command            # :nodoc:

        ##
        # Retrieve the status of a previously uploaded package
        #
        class Status < Mode
          def initialize(*config)
            super
            options.on :vendor_id, "-vendor_ids", /\w/, :multiple => true
            options.on :apple_id, "-apple_ids", /\w/, :multiple => true
          end

          protected

          def handle_success(stdout_lines, stderr_lines, options)
            StatusXMLParser.new.parse(stdout_lines.join(""))
          end
        end
      end
    end
  end
end
