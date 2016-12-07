require "optout"
require "itunes/store/transporter/errors"
require "itunes/store/transporter/command"
require "itunes/store/transporter/output_parser"

module ITunes
  module Store
    module Transporter
      module Command            # :nodoc:

        ##
        # Validate the contents of a package's metadata and assets.
        #
        class Verify < BatchMode
          def initialize(*config)
            super
            options.on :verify_assets, "-disableAssetVerification", Optout::Boolean  # If false verify MD only no assets
          end

          protected

          def create_transporter_options(optz)
            # Include the option if false
            optz[:verify_assets] = !optz[:verify_assets] if optz.include?(:verify_assets)
            super
          end

          # Verify mode returns 0 if there are no packages to verify but will emit an error message about the lack of packages
          def handle_success(stdout_lines, stderr_lines, options)
            parser = OutputParser.new(stderr_lines)
            if parser.errors.any?
              raise ExecutionError.new(parser.errors, 0)
            else
              true
            end
          end
        end
      end
    end
  end
end
