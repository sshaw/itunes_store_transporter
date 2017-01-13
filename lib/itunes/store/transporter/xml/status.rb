require "rexml/document"
require "itunes/store/transporter/errors"

module ITunes
  module Store
    module Transporter
      module XML

        ##
        # XML parser for the status and statusAll commands XML output
        #
        class Status
          NA = "N/A".freeze

          ##
          #
          # Parse status or statusAll XML
          #
          # === Arguments
          #
          # [xml (String|IO)] The XML
          #
          # === Errors
          #
          # ParseError, ExecutionError
          #
          # An ExecutionError is raised if the XML contains iTMSTransporter error messages.
          #
          # === Returns
          #
          # A Hash representation of the XML output.
          # Hash keys and values are slightly different (better, I hope) than the
          # elements and attributes returned by Apple. See the documentation for
          # ITunes::Store::Transporter::ITMSTransporter#status
          #
          def parse(xml)
            doc = _parse(xml)
            status = []

            # No elements means there's just text nodes with an error message
            raise self, doc.root.get_text.to_s unless doc.root.has_elements?

            doc.root.each_element do |e|
              next unless e.node_type == :element
              status << upload_status(e)
            end

            status
          end

          private

          def _parse(xml)
            begin
              doc = REXML::Document.new(xml)
            rescue REXML::ParseException => e
              raise ParseError, sprintf("%s, caused by line %s: %s",
                                        "XML is not well-formed", e.line, e.source.buffer[0..32])
            # For the other tricks REXML has up its sleeve :)
            rescue => e
              raise ParseError, "XML parsing failed: #{e}"
            end

            raise ParseError, "Invalid XML document: '#{xml[0..32]}'" unless doc.root
            doc
          end

          def upload_status(e)
            {
              :apple_id => e.attributes["apple_identifier"],
              :vendor_id => e.attributes["vendor_identifier"],
              :content_status => content_status(e),
              :info => upload_info(e)
            }
          end

          def upload_info(e)
            e.get_elements("upload_status_info").map do |info|
              info.attributes.each_with_object({}) do |(name, value), hash|
                hash[name.to_sym] = value
              end
            end
          end

          def content_status(e)
            e = e.get_elements("content_status_info").first
            return unless e

            {
              :status => e.attributes["content_status"],
              :review_status => e.attributes["content_review_status"],
              :itunes_connect_status => e.attributes["itunes_connect_status"],
              :store_status => store_status(e),
              :video_components => video_components(e)
            }
          end

          def store_status(e)
            e = e.get_elements("store_status").first
            return unless e

            e.attributes.each_with_object({}) do |(name, value), status|
              status[name.to_sym] = territory_list(value)
            end
          end

          def video_components(video)
            video.get_elements("video_components/video_component").map do |e|
              hash = { :name => e.attributes["component_name"] }

              [:locale, :status, :delivered].each do |name|
                value = e.attributes["component_#{name}"]
                value = nil if value == NA
                hash[name] = value
              end

              hash
            end
          end

          def territory_list(value)
            value && value != NA ? value.split(/\s*,\s*/) : []
          end

          def exception(text)
            # Some overlap here with OutputParser, may want to create ErrorParser
            text.sub!(/^\s*Error Summary\s*/, "")
            text.strip!

            errors = text.split(/\n\s*/).map do |line|
              message, code = line, nil
              if message =~ /(.+)\((-?\d+)\)\Z/
                message, code = $1, $2.to_i
              end

              TransporterMessage.new(message.strip, code)
            end

            ExecutionError.new(errors)
          end
        end
      end
    end
  end
end
