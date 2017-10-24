lib LibC
  VTIME = 16
  O_NOCTTY = 0o0400
end

module SerialPorts::Driver


  def self.convertOptions(termiosOption : LibC::Termios, port : Port)
    termiosOption.c_cflag |= LibC::CLOCAL

    termiosOption.c_cflag |= LibC::CREAD

    vTime = ((port.interCharacterTimeout.as(Int32) / 100).round() * 100).to_i
    vMin = port.minimumReadSize.as(Int32)

    if vMin == 0 && vTime < 100
      raise "Invalid values for Configuration.interCharacterTimeout and Configuration.minimumReadSize"
    end

    if vTime > 25500
      raise "Invalid values for Configuration.interCharacterTimeout"
    end

    termiosOption.c_cc[LibC::VTIME] = (vTime / 100).to_u8
    termiosOption.c_cc[LibC::VMIN] = vMin.to_u8

    unless port.baudRate_standard?
      termiosOption.c_ispeed = 9600
      termiosOption.c_ospeed = 9600
    else
      termiosOption.c_ispeed = port.baudRate.as(Int32)
      termiosOption.c_ospeed = port.baudRate.as(Int32)
    end

    case port.dataBits
    when 5
      termiosOption.c_cflag |= LibC::CS5
    when 6
      termiosOption.c_cflag |= LibC::CS6
    when 7
      termiosOption.c_cflag |= LibC::CS7
    when 8
      termiosOption.c_cflag |= LibC::CS8
    else
      raise "Invalid value for Configuration.dataBits provided. Valid options; 5, 6, 7, 8"
    end

    case port.stopBits
    when 1,2
      termiosOption.c_cflag |= LibC::CSTOPB
    else
      raise "Invalid value for Configuration.stopBits provided. Valid options 1, 2"
    end

    case port.parityMode
    when Port::ParityMode::PARITY_NONE
    when Port::ParityMode::PARITY_ODD
      termiosOption.c_cflag |= LibC::PARENB
      termiosOption.c_cflag |= LibC::PARODD
    when Port::ParityMode::PARITY_ODD
      termiosOption.c_cflag |= LibC::PARENB
    else
      raise "InvaliInvalid value ford Configuration.parityMode provided"
    end

    return termiosOption
  end

  def self.open(port : Port) : Int32
    fd = LibC.open(port.portName.as(String), LibC::O_RDWR | LibC::O_NOCTTY | LibC::O_NONBLOCK, 0o0600)

    if fd < 0
      raise Errno.new("Error opening port '#{port.portName}'")
    end

    if LibC.fcntl(fd, LibC::F_SETFL, 0) == -1
      raise Errno.new("fcntl() failed")
    end

    LibC.tcgetattr(fd, out mode)
    mode = convertOptions(mode, port)

    LibC.tcsetattr(fd, Termios::LineControl::TCSANOW, pointerof(mode))

    fd
  end

  def self.close(port : Port)
    LibC.close(port.fd.as(Int32)) unless port.fd.nil?
  end

    def self.list : Array(Port)
        ports = [] of Port

        unless Dir.exists? "/sys/class/tty"
            raise Errno.new("Could not open /sys/class/tty")
        end

        entries = Dir.entries("/sys/class/tty")

        entries.each do |entry|
            next if entry == "."
            next if entry == ".."

            buf = "/sys/class/tty/#{entry}"

            begin
                stat = File.lstat buf
            rescue Errno
                raise Errno.new("Device '#{entry}' not found")
            end

            if !stat.symlink?
                buf = "/sys/class/tty/#{entry}/device"
            end

            begin
                buf = File.real_path buf
            rescue
                next
            end

            if buf.includes? "virtual"
                next
            end

            portName = "/dev/#{entry}"

            ports << Port.new(portName, port_info(entry))
        end

        ports
    end

    def self.get_port_by_name(portName : String) : Port?
        unless Dir.exists? "/sys/class/tty"
            raise Errno.new("Could not open /sys/class/tty")
        end

        entries = Dir.entries("/sys/class/tty")

        entries.each do |entry|
            next if portName != "/dev/#{entry}"

            buf = "/sys/class/tty/#{entry}"

            begin
                stat = File.lstat buf
            rescue Errno
                raise Errno.new("Device '#{entry}' not found")
            end

            if !stat.symlink?
                buf = "/sys/class/tty/#{entry}/device"
            end

            begin
                buf = File.real_path buf
            rescue
                next
            end

            if buf.includes? "virtual"
                next
            end

            portName = "/dev/#{entry}"

            return Port.new(portName, port_info(entry))
        end

        nil
    end

    private def self.port_info(portName : String) : PortMetadata
        file_name = "/sys/class/tty/#{portName}"
        
        stat = File.lstat file_name

        if !stat.symlink?
            file_name = "/sys/class/tty/#{file_name}/device"
        end

        file_name = File.real_path file_name

        transport = "Native"
        if file_name.includes? "bluetooth"
            transport = "Bluetooth"
        elsif file_name.includes? "usb"
            transport = "Usb"
        end

        bus = nil
        address = nil
        vid = nil
        pid = nil
        description = nil
        serial = nil
        if transport == "Usb"
            i = 0
            sub_dir = ""
            while i < 5
                sub_dir = "#{sub_dir}../"
                
                file_name = "/sys/class/tty/#{portName}/device/#{sub_dir}busnum"
                unless File.exists? file_name
                    i += 1
                    next
                end

                bus = File.read file_name

                unless bus
                    i += 1
                    next
                end

                file_name = "/sys/class/tty/#{portName}/device/#{sub_dir}devnum"
                unless File.exists? file_name
                    i += 1
                    next
                end

                address = File.read file_name

                unless address
                    i += 1
                    next
                end
                
                file_name = "/sys/class/tty/#{portName}/device/#{sub_dir}idVendor"
                unless File.exists? file_name
                    i += 1
                    next
                end

                vid = File.read file_name

                unless vid
                    i += 1
                    next
                end
                
                file_name = "/sys/class/tty/#{portName}/device/#{sub_dir}idProduct"
                unless File.exists? file_name
                    i += 1
                    next
                end

                pid = File.read file_name

                unless pid
                    i += 1
                    next
                end
                
                file_name = "/sys/class/tty/#{portName}/device/#{sub_dir}product"
                unless File.exists? file_name
                    i += 1
                    next
                end

                description = File.read file_name

                unless description
                    i += 1
                    next
                end
                
                file_name = "/sys/class/tty/#{portName}/device/#{sub_dir}manufacturer"
                unless File.exists? file_name
                    i += 1
                    next
                end

                manufacturer = File.read file_name

                unless manufacturer
                    i += 1
                    next
                end
                
                file_name = "/sys/class/tty/#{portName}/device/#{sub_dir}serial"
                unless File.exists? file_name
                    i += 1
                    next
                end

                serial = File.read file_name

                unless serial
                    i += 1
                    next
                end

                

                i += 1
            end
        end

        PortMetadata.new(portName.as(String), transport.as(String), description.as?(String), vid.as?(Int32), pid.as?(Int32), manufacturer.as?(String), description.as?(String), serial.as?(String))
    end
end