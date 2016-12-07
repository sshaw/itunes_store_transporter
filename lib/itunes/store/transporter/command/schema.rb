require "itunes/store/transporter/command"

module ITunes
  module Store
    module Transporter
      module Command

        ##
        # Download a RelaxNG schema file for a particular metadata specification.
        #

        class Schema < Mode
          def initialize(*config)
            super
            options.on *DESTINATION
            options.on :type, "-schemaType", /\A(transitional|strict)\z/i, :required => true
            options.on :version, "-schema", /\w+/i, :required => true
          end

          protected

          def mode
            "generateSchema"
          end
        end
      end
    end
  end
end
