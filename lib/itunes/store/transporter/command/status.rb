require "itunes/store/transporter/command"

module ITunes
  module Store
    module Transporter
      module Command            # :nodoc:
        
        ##
        # Retrieve the status of a previously uploaded package
        #
        class Status < Mode
          def initialize(*config)
            super 
            options.on *VENDOR_ID
          end

          protected 
          def handle_success(stdout_lines, stderr_lines, options) 
            status = {}
            while line = stdout_lines.shift
              next unless line =~ /\S+/
              if line =~ /\A--+/
                entry = {}
                while line = stdout_lines.shift
                  break unless line =~ /\A\s*\w/
                  key, value = parse_line(line)
                  entry[key] = value
                end
                (status[:status] ||= []) << entry
              else
                key, value = parse_line(line)
                status[key] = value
              end
            end
            status
          end             

          def parse_line(line)
            key, value = line.split(/:\s+/, 2).map(&:strip)
            key.gsub!(/\s+/, "_")
            key.downcase!
            [key.to_sym, value]
          end
        end                   
      end
    end
  end
end
