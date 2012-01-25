require "itunes/store/transporter/command"
Dir[File.join(File.dirname(__FILE__), 
              "transporter", 
              "command", 
              "*.rb")].each { |cmd| require cmd }

module ITunes
  module Store      
    class Transporter
      def initialize(options = {})
        @defaults = options.dup
        @config = { 
          :path	      => @defaults.delete(:path),
          :print_stdout => @defaults.delete(:print_stdout), 
          :print_stderr => @defaults.delete(:print_stderr), 
        }
        
        # path = @config[:path]
        # raise ArgumentError "File not found: #{path}" unless File.exists?(path)
        # raise ArgumentError "File not a executable: #{path}" unless File.executable?(path)
      end


      %w|upload verify|.each do |command|
        define_method(command) do |package, *options| 
          cmd_options = Hash === options.first ? options.shift.dup : {}
          cmd_options[:package] = package
          run_command(command, cmd_options)
        end
      end
      
      %w|lookup providers schema status upload verify version|.each do |command|
        define_method(command) { |*options| run_command(command, options.shift) }
      end          

      private 
      def run_command(name, options) 
        Command.const_get(name.capitalize).new(@config, @defaults).run(options)       
      end
    end
  end
end

unless ENV["ITUNES_STORE_TRANSPORTER_NO_SYNTAX_SUGAR"].to_i > 0
  def iTunes
    ITunes
  end
end





