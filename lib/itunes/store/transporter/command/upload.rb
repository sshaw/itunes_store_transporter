require "optout"
require "itunes/store/transporter/command"

module ITunes
  module Store
    module Transporter
      module Command            # :nodoc: all

        ##
        # Upload a package to the iTunes Store
        #
        class Upload < BatchMode
          def initialize(*config)
            super
            options.on *TRANSPORT
            options.on *SUCCESS
            options.on *FAILURE
            options.on :delete, "-delete", Optout::Boolean
            options.on :rate, "-k", Integer  # Required if TRANSPORT is Aspera or Signiant
            options.on :streams, "-numStreams", Integer  # Only valid if TRANSPORT is Signiant
            options.on :log_history, "-loghistory", Optout::Dir.exists
          end

          protected

          def handle_success(stdout_lines, stderr_lines, options)
            true
          end
        end
      end
    end
  end
end
