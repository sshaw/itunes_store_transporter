require "optout"

module ITunes
  module Store
    module Transporter
      module Command
        module Option
          # Common command options
          VENDOR_ID   = [ :vendor_id, "-vendor_id", /\w/ ]
          APPLE_ID    = [ :apple_id, "-apple_id", /\w/ ]
          SHORTNAME   = [ :shortname, "-s", /\w/ ]
          TRANSPORT   = [ :transport, "-t", %w|Aspera Signiant DAV| ]
          SUCCESS     = [ :success, "-success", Optout::Dir.exists ]
          FAILURE     = [ :failure, "-failure", Optout::Dir.exists ]         
          PACKAGE     = [ :package, "-f", Optout::Dir.exists.named(/\.itmsp\z/), { :required => true } ]
          DESTINATION = [ :destination, "-destination" ]          
        end
      end
    end
  end
end
