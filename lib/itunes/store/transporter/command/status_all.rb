require "itunes/store/transporter/command/status"

module ITunes
  module Store
    module Transporter
      module Command            # :nodoc:

        ##
        # Retrieve the full status history of previously uploaded packages
        #
        class StatusAll < Status
          protected

          def mode
            "statusAll"
          end
        end
      end
    end
  end
end
