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
      # === Arguments 
      #
      # [options (Hash)] Transporter options
      #
      # === Options
      #  
      # Options given here will be used as defaults for all subsequent method calls. Thus you can set method specific options here but, if you call a method that does not accept one of these options, an OptionError will be raised.
      # 
      # See specific methods for a list of options. 
      #
      # [:username (String)] Your username
      # [:password (String)] Your password
      # [:shortname (String)] Your shortname. Optional, not every iTunes account has one
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
      # === Arguments 
      #
      # [options (Hash)] Transporter options
      #
      # ==== Options
      #
      # You must use either the +:apple_id+ or +:vendor_id+ option to identify the package
      #
      # === Errors
      #
      # TransporterError, OptionError, ExecutionError
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
      # === Arguments 
      #
      # [options (Hash)] Transporter options
      #
      # === Errors
      #
      # TransporterError, OptionError, ExecutionError
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
      # === Arguments 
      #
      # [options (Hash)] Transporter options
      #
      # === Options
      #
      # [:type (String)] transitional or strict
      # [:version (String)] The schema version you'd like to download. This is typically in the form of +schemaVERSION+. E.g., +film4.8+
      #
      # === Errors
      #
      # TransporterError, OptionError, ExecutionError      
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
      # === Arguments 
      #
      # [options (Hash)] Transporter options
      #
      # === Options 
      #
      # [:vendor_id (String)] ID of the package you want status info on
      #
      # === Errors
      #
      # TransporterError, OptionError, ExecutionError
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
      # [package (String)] The path to the package directory to upload. Package names must end in +.itmsp+.
      # [options (Hash)] Transporter options
      #      
      # === Options
      #
      # [:transport (String)] The method/protocol used to upload your package. Optional. Can be one of: <code>"Aspera"</code>, <code>"Signiant"</code>, or <code>"DEV"</code>. By default +iTMSTransporter+ automatically selects the transport.
      # [:rate (Integer)] Target bitrate in Kbps. Optional, only used with +Aspera+ and +Signiant+ 
      # [:success (String)] A directory to move the package to if the upload succeeds
      # [:failure (String)] A directory to move the package to if the upload fails
      # [:delete (Boolean)] Delete the package if the upload succeeds. Defaults to +false+.
      # [:log_history (String)] Write an +iTMSTransporter+ log to this directory. Off by default.
      #
      # === Errors
      #
      # TransporterError, OptionError, ExecutionError
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
      # [package (String)] The path to the package directory to verify. Package names must end in +.itmsp+.
      # [options (Hash)] Verify options
      #
      # === Options
      #
      # [:verify_assets (Boolean)] If false the assets will not be verified. Defaults to +true+.
      #
      # === Errors
      #
      # TransporterError, OptionError, ExecutionError
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





