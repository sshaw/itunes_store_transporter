require "tempfile" 
require "fileutils"
require "itunes/store/transporter"
require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command

        ##
        # Retrieve the metadata for a previously delivered package.  
        #
        class Lookup < Mode
          def initialize(*config)
            super
            # These 2 are mutually exclusive, Optout has no way to denote this
            options.on :vendor_id, "-vendor_id"
            options.on :apple_id, "-apple_id"

            # Schema req this option too
            options.on :shortname, "-s", :required => true
            options.on :destination, "-destination"
          end

          def run(options = {})
            options = options.dup
            options[:destination] = Dir.mktmpdir
            super options
          ensure
            FileUtils.rm_r(options[:destination])
          end

          protected
          def handle_success(stdout_lines, stderr_lines, options)
            id = options[:apple_id] || options[:vendor_id]
            path = File.join(options[:destination], "#{id}.itmsp", "metadata.xml")
            # Should probably raise an ex if it doesn't exist
            File.read(path) if File.exists?(path)
          end

          def mode
            "lookupMetadata"
          end
        end
      end
    end
  end
end
