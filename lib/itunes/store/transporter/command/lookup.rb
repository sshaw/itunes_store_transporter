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
            # These 2 are mutually exclusive, and one is required. 
            # Optout has no way to denote this
            options.on *VENDOR_ID
            options.on *APPLE_ID
            options.on *SHORTNAME
            options.on *DESTINATION
          end

          def run(options = {})
            options[:destination] = Dir.mktmpdir
            super
          ensure
            FileUtils.rm_rf(options[:destination])
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
