require "itunes/store/transporter/command"
require "itunes/store/transporter/command/lookup"
require "itunes/store/transporter/command/providers"
require "itunes/store/transporter/command/schema"
require "itunes/store/transporter/command/status"
require "itunes/store/transporter/command/upload"
require "itunes/store/transporter/command/verify"
require "itunes/store/transporter/command/version"

module ITunes
  module Store      
    ##
    # Upload and manage your assets in the iTunes Store using the iTunes Store's Transporter (+iTMSTransporter+).

    class Transporter

      ##
      # === Options
      #  
      # Options given here will be used as defaults, i.e., for all subsequent method calls. Thus you can set method specific options here but, if you call a method that does not accept these options, it will raise an OptionError. 
      #      
      # [:path (String)] The path to the +iTMSTransporter+. Optional.
      # [:print_stdout (Boolean)] Print +iTMSTransporter+'s stdout to your stdout. Defaults to +false+. 
      # [:print_stderr (Boolean)] Print +iTMSTransporter+'s stderr to your stderr. Defaults to +false+. 
      #

      def initialize(options = nil)
        @defaults = create_options(options)
        @config = { 
          :path	        => @defaults.delete(:path),
          :print_stdout => @defaults.delete(:print_stdout), 
          :print_stderr => @defaults.delete(:print_stderr), 
        }        
      end

      ##
      # :method: lookup
      # :call-seq: 
      #   lookup(options = {})
      #            
      # Retrieve the metadata for a previously delivered package. 
      #
      # You must use either the +:apple_id+ or +:vendor_id+ option to identify the package
      #
      # === Returns
      #
      # [String] The metadata

      ##
      # :method: providers
      # :call-seq: 
      #   providers(options = {})
      #
      # List of Providers for whom your account is authorzed to deliver for.
      #
      # === Returns
      #
      # [Array] Each element is a +Hash+ with two keys: +:shortname+ and +:longname+ representing the given provider's long and short names

      ##
      # :method: schema
      # :call-seq: 
      #   schema(options = {})
      #
      # Download a RelaxNG schema file for a particular metadata specification.
      #    
      # === Returns
      #
      # [String] The schema

      ##
      # :method: status
      # :call-seq: 
      #   status(options = {})
      #
      # Retrieve the status of a previously uploaded package.
      #
      # You must use either the +:vendor_id+ option to identify the package.
      #
      # === Returns
      #
      # [Hash] Descibes various facets of the package's status.
      

      ##
      # :method: upload
      # :call-seq: 
      #   upload(package, options = {})
      #
      # Upload a package to the iTunes Store.
      #
      # === Arguments
      # 
      # [package (String)] The path to the package to upload
      # [options (Hash)] Upload options
      #      
      # === Options
      #
      # [:transport] The method used to upload your package. Optional. Can be one of: <code>"Aspera"</code>, <code>"Signiant"</code>, or <code>"DEV"</code>. By default +iTMSTransporter+ automatically selects the transport.
      # [:rate] Target bitrate in Kbps. Optional, only used with +Aspera+ and +Signiant+ 
      #
      # === Returns
      # 
      # +true+ if the upload was successful.
      
      ##
      # :method: verify      
      # :call-seq: 
      #   verify(package, options = {})
      #      
      # Validate the contents of a package's metadata and assets.      
      #
      # If verification fails an ExecutionError containing the errors will be raised. 
      # Each error message is an instance of TransporterMessage.
      #
      # === Arguments
      #
      # [package (String)] The path to the package to verify
      # [options (Hash)] Verify options
      #
      # === Returns
      # 
      # +true+ if the package was verified.
      
      ##
      # :method: version
      # :call-seq: 
      #   version
      #
      # Return the underlying +iTMSTransporter+ version.
      #
      # === Returns
      #
      # [String] The version number
      
      %w|upload verify|.each do |command|
        define_method(command) do |package, *options| 
          cmd_options = create_options(options.first)
          cmd_options[:package] = package
          run_command(command, cmd_options)
        end
      end
      
      %w|lookup providers schema status version|.each do |command|
        define_method(command) { |*options| run_command(command, options.shift) }
      end          

      private 
      def run_command(name, options) 
        Command.const_get(name.capitalize).new(@config, @defaults).run(create_options(options))
      end

      def create_options(options)
        options ||= {}
        raise ArgumentError, "options must be a Hash" unless Hash === options
        options.dup
      end
    end
  end
end

unless ENV["ITUNES_STORE_TRANSPORTER_NO_SYNTAX_SUGAR"].to_i > 0
  def iTunes
    ITunes
  end
end





