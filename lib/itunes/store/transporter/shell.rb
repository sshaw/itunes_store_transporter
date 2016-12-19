require "childprocess"
require "itunes/store/transporter/errors"

module ITunes
  module Store
    module Transporter

      class Shell  # :nodoc:
        attr :path

        EXE_NAME = "iTMSTransporter"
        WINDOWS_EXE = "#{EXE_NAME}.CMD"
        DEFAULT_UNIX_PATH = "/usr/local/itms/bin/#{EXE_NAME}"

        OSX_APPLICATION_LOADER_PATHS = [
          "/Applications/Application Loader.app/Contents/MacOS/itms/bin/#{EXE_NAME}",
          "/Developer/Applications/Utilities/Application Loader.app/Contents/MacOS/itms/bin/#{EXE_NAME}"
        ]

        class << self
          def windows?
            # We just need to know where iTMSTransporter lives, though cygwin
            # can crow when it receives a Windows path.
            ChildProcess.windows? || ChildProcess.os == :cygwin
          end

          def osx?
            ChildProcess.os == :macosx
          end

          def default_path
            case
              when windows?
                # The Transporter installer prefers x86
                # But... I think ruby normalizes this to just PROGRAMFILES
                root = ENV["PROGRAMFILES(x86)"] || ENV["PROGRAMFILES"] # Need C:\ in case?
                File.join(root, "itms", WINDOWS_EXE)
              when osx?
                paths = OSX_APPLICATION_LOADER_PATHS.dup
                root  = `xcode-select --print-path`.chomp rescue ""

                if !root.empty?
                  ["/Applications/Application Loader.app/Contents/MacOS/itms/bin/#{EXE_NAME}",
                   "/Applications/Application Loader.app/Contents/itms/bin/#{EXE_NAME}"].each do |path|
                    paths << File.join(root, "..", path)
                  end
                end

                paths.find { |path| File.exist?(path) } || DEFAULT_UNIX_PATH
              else
                DEFAULT_UNIX_PATH
            end
          end
        end

        def initialize(path = nil)
          @path = path || self.class.default_path
        end

        def exec(argv, &block)
          raise ArgumentError, "block required" unless block_given?

          begin
            process = ChildProcess.build(path, *argv)

            stdout = IO.pipe
            stderr = IO.pipe

            stdout[1].sync = true
            process.io.stdout = stdout[1]

            stderr[1].sync = true
            process.io.stderr = stderr[1]

            process.start

            stdout[1].close
            stderr[1].close

            poll(stdout[0], stderr[0], &block)
          rescue ChildProcess::Error, SystemCallError => e
            raise TransporterError, e.message
          ensure
            process.wait if process.alive?
            [ stdout, stderr ].flatten.each { |io| io.close if !io.closed? }
          end

          process.exit_code
        end

        private

        def poll(stdout, stderr)
          read = [ stdout, stderr ]

          loop do
            # TODO: Not working on jruby
            if ready = select(read, nil, nil, 1)
              ready.each do |set|
                next unless set.any?

                set.each do |io|
                  if io.eof?
                    read.delete(io)
                    next
                  end

                  name = io == stdout ? :stdout : :stderr
                  yield(io.gets, name)
                end

              end
            end
            break unless read.any?
          end
        end

      end
    end
  end
end
