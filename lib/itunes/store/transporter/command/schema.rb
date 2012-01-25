require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command
        
        ##
        # Download an RelaxNG schema file for a particular metadata specification.
        #

        class Schema < Mode
          def initialize(*config)
            super
            options.on :shortname, "-s", String, :required => true
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
