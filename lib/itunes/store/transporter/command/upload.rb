require "optout"
require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command            # :nodoc: all

        ##
        # Upload a package to the iTunes Store
        #
        class Upload < Mode
          def initialize(*config)
            super
            options.on *PACKAGE
            options.on *SHORTNAME
            options.on *TRANSPORT
            options.on *ON_SUCCESS
            options.on *ON_FAILURE
            options.on :delete, "-delete", Optout::Boolean
            options.on :rate, "-k", Fixnum    # Required if TRANSPORT is Aspera or Signiant 
            options.on :log_history, "-loghistory", Optout::Dir.exists
            options.on :delete_on_success, "-delete", Optout::Boolean
          end
        end
      end
    end
  end
end
