require "itunes/store/transporter/command"

module ITunes
  module Store
    module Transporter
      module Command

        ##
        # List of Providers for whom your account is authorzed to deliver for.
        #
        class Providers < Mode
          protected

          def mode
            "provider"
          end

          def handle_success(stdout_lines, stderr_lines, options)
            providers = []
            stdout_lines.each do |line|
              line.chomp!
              if line =~ /\A\d+\s+(.+?)\s+(\w+)\Z/
                provider = {}
                provider[:longname] = $1
                provider[:shortname] = $2
                providers << provider
              end
            end

            providers
          end
        end
      end
    end
  end
end
