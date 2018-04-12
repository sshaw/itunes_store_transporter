require "tmpdir"
require "fileutils"
require "itunes/store/transporter/errors"
require "itunes/store/transporter/command"

module ITunes
  module Store
    module Transporter
      module Command

        ##
        # Retrieve the metadata for a previously delivered package.
        #
        class Lookup < Mode
          def initialize(*config)
            super
            options.on *SHORTNAME
            options.on *ITC_PROVIDER

            # These 2 are mutually exclusive, and one is required.
            # Optout has no way to denote this
            options.on *VENDOR_ID
            options.on *APPLE_ID
            options.on *DESTINATION
          end

          def run(options = {})
            options[:destination] = Dir.mktmpdir
            super
          ensure
            FileUtils.rm_rf(options[:destination]) if options[:destination]
          end

          protected

          def handle_success(stdout_lines, stderr_lines, options)
            id = options[:apple_id] || options[:vendor_id]
            path = File.join(options[:destination], "#{id}.itmsp", "metadata.xml")

            if !File.exists?(path)
              raise TransporterError, "No metadata file exists at #{path}"
            end

            begin
              metadata = File.read(path)
            rescue StandardError => e
              raise TransporterError, "Failed to read metadata file #{path}: #{e}"
            end

            metadata
          end

          def mode
            "lookupMetadata"
          end
        end
      end
    end
  end
end
