require "optout"
require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command

        ##
        # Upload a package to the iTunes Store
        #
        class Upload < Mode
          def initialize(*config)
            super
            options.on :rate, "-k", /\A\d+[KM]?\z/
            options.on :shortname, "-s", String
            options.on :protocol, "-t", %w|Aspera Signiant DAV| # case sensitive?
            options.on :on_success, "-success", Optout::Dir.exists
            options.on :on_failure, "-failure", Optout::Dir.exists
            options.on :log_history, "-loghistory", Optout::Dir.exists
            options.on :delete_on_success, "-delete", Optout::Boolean
            ###
            options.on :package, "-f", Optout::Dir.exists, :required => true
          end
        end
      end
    end
  end
end
