require "optout"

module ITunes
  module Store
    class Transporter
      module Command
        module Option
          # Common command options
          VENDOR_ID   = [ :vendor_id, "-vendor_id", /\w/ ]
          APPLE_ID    = [ :apple_id, "-apple_id", /\w/ ]
          SHORTNAME   = [ :shortname, "-s", String ]
          TRANSPORT   = [ :transport, "-t", %w|Aspera Signiant DAV| ]
          ON_SUCCESS  = [ :on_success, "-success", Optout::Dir.exists ]
          ON_FAILURE  = [ :on_failure, "-failure", Optout::Dir.exists ]         
          PACKAGE     = [ :package, "-f", Optout::Dir.exists.named(/\.itmsp\z/), { :required => true } ]
          DESTINATION = [ :destination, "-destination" ]          
          DELETE_ON_SUCCESS = [ :delete_on_success, "-delete", Optout::Boolean ]
        end
      end
    end
  end
end
