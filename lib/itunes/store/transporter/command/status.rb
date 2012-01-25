require "itunes/store/transporter/command"

module ITunes
  module Store
    class Transporter
      module Command
        
        ##
        # Retrieve the status of a previously uploaded package
        #
        class Status < Mode
          protected 
          def handle_success(stdout_lines, stderr_lines, options) 
            status = {}
            stdout_lines.each do |line|
              next unless line =~ /\A\s*\w/
              key, value = line.split(/:\s+/, 2).map(&:strip)
              key.gsub!(/\s+/, "_")
              key.downcase!
              status[key.to_sym] = value
            end
            status
          end
        end        

      end
    end
  end
end
