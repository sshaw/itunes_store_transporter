
module ITunes
  module Store
    class Transporter
      class OutputParser

	##
	# This class extracts error and warning messages output by +iTMSTransporter+. For each message
        # is creates an instance of ITunes::Store::Transporter::TransporterMessage 
	#

	attr :errors
	attr :warnings

	ERROR_LINE = />\s+ERROR:\s+(.+)/
	WARNING_LINE = />\s+WARN:\s+(.+)/

	# Generic messages we want to ignore        
	SKIP_ERRORS = [ /\boperation was not successful/i,
                        /\bunable to verify the package/i,
                        /^an error occurred while/i,
                        /^unknown operation/i,
			/\bunable to authenticate/i ]

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
            # Note if logging is off ERROR_LINE wont match and only the lines contained 
            # in create_message() are output            
	    if line =~ ERROR_LINE
	      error = $1
	      next if SKIP_ERRORS.any? { |skip| error =~ skip }
	      errors << create_message(error)
	    elsif line =~ WARNING_LINE
	      warnings << create_message($1)
	    end
	  end

          # TODO: Remove dups from both arrays
	end

        # TODO: Error lines beginning with WARNING 
	def create_message(line)          
	  case line
	  when /^ERROR\s+ITMS-(\d+):\s+(.+)/
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

	  message.gsub! /^"|"$/, ""
	  TransporterMessage.new(message, code ? code.to_i : nil)
	end
      end
    end
  end
end
