require "itunes/store/transporter/errors"

module ITunes
  module Store
    module Transporter
      class OutputParser

        ##
        # This class extracts error and warning messages output by +iTMSTransporter+. For each message
        # is creates an instance of ITunes::Store::Transporter::TransporterMessage
        #

        attr :errors
        attr :warnings

        ERROR_LINE = /<main>\s+ERROR:\s+(.+)/
        WARNING_LINE = /<main>\s+WARN:\s+(.+)/

        # Generic messages we want to ignore.
        SKIP_ERRORS = [ /\boperation was not successful/i,
                        /\bunable to verify the package/i,
                        /\bwill NOT be verified/,
                        /^an error has occurred/i,
                        /^an error occurred while/i,
                        /^unknown operation/i,
                        /\bunable to authenticate the package/i ]

        ##
        # === Arguments
        #
        # [output (Array)]  +iTMSTransporter+ output
        #
        def initialize(output)
          @errors = []
          @warnings = []
          parse_output(output) if Array === output
        end

        private

        def parse_output(output)
          output.each do |line|
            if line =~ ERROR_LINE
              error = $1
              next if SKIP_ERRORS.any? { |skip| error =~ skip }
              errors << create_message(error)
            elsif line =~ WARNING_LINE
              warnings << create_message($1)
            end
          end

          # Unique messages only. The block form of uniq() is not available on Ruby < 1.9.2
          [errors, warnings].each do |e|
            next if e.empty?
            uniq = {}
            e.replace(e.select { |m| uniq.include?(m.message) ? false : uniq[m.message] = true })
          end
        end

        def create_message(line)
          case line
          when /^(?:ERROR|WARNING)\s+ITMS-(\d+):\s+(.+)/
            code = $1
            message = $2
          when /(.+)\s+\((\d+)\)$/,
               # Is this correct?
               /(.+)\s+errorCode\s+=\s+\((\d+)\)$/
            message = $1
            code = $2
          else
            message = line
            code = nil
          end

          message.gsub! /^"/, ""
          message.gsub! /"(?: at .+)?$/, ""

          TransporterMessage.new(message, code ? code.to_i : nil)
        end
      end
    end
  end
end
