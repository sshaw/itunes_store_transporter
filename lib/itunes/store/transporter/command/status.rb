require "itunes/store/transporter/command"
require "itunes/store/transporter/xml/status"

module ITunes
  module Store
    module Transporter
      module Command            # :nodoc:

        ##
        # Retrieve the most recent status of previously uploaded packages
        #
        class Status < Mode
          def initialize(*config)
            super
            options.on :vendor_id, "-vendor_ids", /\w/, :multiple => true
            options.on :apple_id, "-apple_ids", /\w/, :multiple => true
            options.on :format, "-outputFormat", %w[xml]
          end

          protected

          def create_transporter_options(optz)
            optz[:format] = "xml"
            super
          end

          def handle_success(stdout_lines, stderr_lines, options)
            # Pre-XML behavior. Not sure if it should be kept.
            return [] if stdout_lines.empty?

            begin
              XML::Status.new.parse(stdout_lines.join(""))
            rescue ParseError => e
              raise TransporterError, e.message
            end
          end
        end
      end
    end
  end
end
