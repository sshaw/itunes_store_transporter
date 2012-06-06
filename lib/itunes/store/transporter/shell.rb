require "childprocess"

module ITunes
  module Store
    class Transporter

      class Shell  # :nodoc:
        attr :path

        EXE_NAME = "iTMSTransporter"
        WINDOWS_EXE = "#{EXE_NAME}.CMD"
        DEFAULT_UNIX_PATH = "/usr/local/itms/bin/#{EXE_NAME}"

        class << self
          def windows?
            # We just need to know where iTMSTransporter lives, though cygwin
            # can crow when it receives a Windows path.
            ChildProcess.windows? || ChildProcess.os == :cygwin
          end
          
          def default_path
            if windows?
              # The Transporter installer prefers x86
              # But... I think ruby normalizes this to just PROGRAMFILES
              root = ENV["PROGRAMFILES(x86)"] || ENV["PROGRAMFILES"] # Need C:\ in case?
              File.join(root, "itms", WINDOWS_EXE)
            else
              DEFAULT_UNIX_PATH
            end
          end
        end
        
        def initialize(path = nil)
          @path = path || self.class.default_path
        end
        
        def exec(argv, &block)
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
            raise ITunes::Store::Transporter::TransporterError, e.message
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
