
module ITunes
  module Store
    module Transporter

      class TransporterError < StandardError; end
      class OptionError < TransporterError; end
      class ParseError < TransporterError; end

      class ExecutionError < TransporterError
        attr :errors
        attr :exitstatus

        def initialize(errors, exitstatus = nil)
          @errors = [ errors ].flatten
          @exitstatus = exitstatus
          super @errors.map { |e| e.to_s }.join ", "
        end
      end

      class TransporterMessage
        attr :code
        attr :message

        def initialize(message, code = nil)
          @message = message
          @code = code
        end

        # 1000...2000?

        def bad_data?
          (3000...4000).include?(code)
        end

        def invalid_data?
          (4000...5000).include?(code)
        end

        def missing_data?
          (5000...6000).include?(code)
        end

        def unsupported_feature?
          (6000...7000).include?(code)
        end

        def schema_error?
          (8000...9000).include?(code)
        end

        def asset_error?
          (9000...10_000).include?(code)
        end

        def validation_error?
          (3000...10_000).include?(code)
        end

        def to_s
          s = message.dup
          s << " (#{code})" if code
          s
        end
      end
    end
  end
end
