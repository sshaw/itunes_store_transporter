require "itunes/store/transporter/itms_transporter"
require "itunes/store/transporter/command/lookup"
require "itunes/store/transporter/command/providers"
require "itunes/store/transporter/command/schema"
require "itunes/store/transporter/command/status"
require "itunes/store/transporter/command/upload"
require "itunes/store/transporter/command/verify"
require "itunes/store/transporter/command/version"

module ITunes
  module Store
    # See ITunes::Store::Transporter::ITMSTransporter
    module Transporter
      def self.new(options = nil)
        ITMSTransporter.new(options)
      end
    end
  end
end

unless ENV["ITUNES_STORE_TRANSPORTER_NO_SYNTAX_SUGAR"].to_i > 0
  def iTunes
    ITunes
  end
end
