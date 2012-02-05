require "optout"
require "itunes/store/transporter"
require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command            # :nodoc:

        ##
        # Validate the contents of a package's metadata and assets.
        #

        class Verify < Mode
          def initialize(*config)
            super
            options.on *SHORTNAME
            options.on *PACKAGE
            options.on :verify_assets, "-disableAssetVerification", Optout::Boolean  # If false verify MD only no assets
          end

          protected
          # Verify mode returns 0 if there are no packages to verify but will emit an error message about the lack of packages
          def handle_success(stdout_lines, stderr_lines, options)
            parser = Transporter::OutputParser.new(stderr_lines)
            if parser.errors.any?
              raise ITunes::Store::Transporter::ExecutionError.new(parser.errors, 0)
            else
              true
            end
          end
        end
      end
    end
  end
end

