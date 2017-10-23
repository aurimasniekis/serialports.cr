require "./libiokit"

lib IOKit
 KIOServicePlane = "IOService"
 KIOTTYDeviceKey = "IOTTYDevice"
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

    termiosOption.c_ispeed = port.baudRate.as(Int32)
    termiosOption.c_ospeed = port.baudRate.as(Int32)

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
    LibC.close(port.fd)
  end

  def self.list
    ports = [] of Port
    
    classes = IOKit.io_service_matching("IOSerialBSDClient")

    if classes.null?
      raise "IOServiceMatching() failed"
    end

    if 0 != IOKit.io_service_get_matching_services(IOKit.kIOMasterPortDefault, classes.as(IOKit::CfDictionaryRef), out iter)
      raise "IOServiceGetMatchingServices() failed"
    end
    
    loop do
      ioPort = IOKit.io_iterator_next(iter)

      break if ioPort == 0
    
      portNameCf = IOKit.io_registry_entry_create_cf_property(ioPort, IOKit.__cf_string_make_constant_string("IOCalloutDevice"), IOKit.kCFAllocatorDefault, 0)

      if portNameCf
        portName = get_cf_string portNameCf.as(IOKit::CfStringRef)

        next if portName.nil?
        
        IOKit.io_registry_entry_get_parent_entry(ioPort, to_s_array(IOKit::KIOServicePlane), out ioParent)

        transport = "Native"
        ioClass = registry_entry_search(ioParent, "IOClass")
        if false == ioClass.nil? && ioClass.as(String).includes? "USB"
          transport = "USB"
        end

        ioProviderClass = registry_entry_search(ioParent, "IOProviderClass")
        if false == ioProviderClass.nil? && ioProviderClass.as(String).includes? "USB"
          transport = "USB"
        end

        description = registrey_entry_multi_search(ioParent, ["USB Interface Name", "USB Product Name", "Product Name", IOKit::KIOTTYDeviceKey])
        
        usbBusNumber = registry_entry_search(ioParent, "USBBusNumber", :Number)
        usbAddress = registry_entry_search(ioParent, "USB Address", :Number)

        usbVid = registry_entry_search(ioParent, "idVendor", :Number)
        usbPid = registry_entry_search(ioParent, "idProduct", :Number)

        usbVendorName = registry_entry_search(ioParent, "USB Vendor Name")
        usbProductName = registry_entry_search(ioParent, "USB Product Name")
        usbSerialName = registry_entry_search(ioParent, "USB Serial Number")

        portMetadata = PortMetadata.new(portName.as(String), transport.as(String), description.as?(String), usbVid.as?(Int32), usbPid.as?(Int32), usbVendorName.as?(String), usbProductName.as?(String), usbSerialName.as?(String))

        ports << Port.new(portName, portMetadata)

      end

      IOKit.io_object_release(ioPort)
    end

    ports
  end

  def self.get_port_by_name(requirePortName : String) : Port?
    classes = IOKit.io_service_matching("IOSerialBSDClient")
    
    if classes.null?
      raise "IOServiceMatching() failed"
    end

    if 0 != IOKit.io_service_get_matching_services(IOKit.kIOMasterPortDefault, classes.as(IOKit::CfDictionaryRef), out iter)
      raise "IOServiceGetMatchingServices() failed"
    end
    
    loop do
      ioPort = IOKit.io_iterator_next(iter)

      break if ioPort == 0
    
      portNameCf = IOKit.io_registry_entry_create_cf_property(ioPort, IOKit.__cf_string_make_constant_string("IOCalloutDevice"), IOKit.kCFAllocatorDefault, 0)

      if portNameCf
        portName = get_cf_string portNameCf.as(IOKit::CfStringRef)

        next if portName.nil?
        next if portName != requirePortName
        
        IOKit.io_registry_entry_get_parent_entry(ioPort, to_s_array(IOKit::KIOServicePlane), out ioParent)

        transport = "Native"
        ioClass = registry_entry_search(ioParent, "IOClass")
        if false == ioClass.nil? && ioClass.as(String).includes? "USB"
          transport = "USB"
        end

        ioProviderClass = registry_entry_search(ioParent, "IOProviderClass")
        if false == ioProviderClass.nil? && ioProviderClass.as(String).includes? "USB"
          transport = "USB"
        end

        description = registrey_entry_multi_search(ioParent, ["USB Interface Name", "USB Product Name", "Product Name", IOKit::KIOTTYDeviceKey])
        
        usbBusNumber = registry_entry_search(ioParent, "USBBusNumber", :Number)
        usbAddress = registry_entry_search(ioParent, "USB Address", :Number)

        usbVid = registry_entry_search(ioParent, "idVendor", :Number)
        usbPid = registry_entry_search(ioParent, "idProduct", :Number)

        usbVendorName = registry_entry_search(ioParent, "USB Vendor Name")
        usbProductName = registry_entry_search(ioParent, "USB Product Name")
        usbSerialName = registry_entry_search(ioParent, "USB Serial Number")

        portMetadata = PortMetadata.new(portName.as(String), transport.as(String), description.as?(String), usbVid.as?(Int32), usbPid.as?(Int32), usbVendorName.as?(String), usbProductName.as?(String), usbSerialName.as?(String))

        IOKit.io_object_release(ioPort)

        return Port.new(portName, portMetadata)
      end

      IOKit.io_object_release(ioPort)
    end

    nil
  end

  private def self.registrey_entry_multi_search(entry : IOKit::IoRegistryEntryT, propertyNames : Array(String), options = IOKit::KIoRegistryIterateRecursively | IOKit::KIoRegistryIterateParents) : String | Int32 | Nil
    propertyNames.each do |propertyName|
      result = registry_entry_search(entry, propertyName, :String, options)

      unless result.nil?
        return result
      end
    end

    nil
  end

  private def self.registry_entry_search(entry : IOKit::IoRegistryEntryT, propertyName : String, type : Symbol = :String, options = IOKit::KIoRegistryIterateRecursively | IOKit::KIoRegistryIterateParents) : String | Int32 | Nil
    cf_property = IOKit.io_registry_entry_search_cf_property(entry, to_s_array(IOKit::KIOServicePlane), IOKit.__cf_string_make_constant_string(propertyName), IOKit.kCFAllocatorDefault, options)

    if cf_property
      case type
      when :String
        result = get_cf_string(cf_property.as(IOKit::CfStringRef))
      when :Number
        result = get_cf_number(cf_property.as(IOKit::CfNumberRef))
      end

      IOKit.cf_release cf_property

      return result
    end

    nil
  end

  private def self.get_cf_string(cf_type_ref : IOKit::CfTypeRef) : String | Nil
      buffer = Bytes.new(IOKit.cf_string_get_length(cf_type_ref))

      if IOKit.cf_string_get_c_string(cf_type_ref, buffer, buffer.size + 1, IOKit::KCfStringEncodingAscii) == 1
      return String.new(buffer, "ASCII", :skip)
      end

      nil
  end

  private def self.get_cf_number(cf_type_ref : IOKit::CfNumberRef) : Int32 | Nil
    number = 0
    if result = IOKit.cf_number_get_value(cf_type_ref, IOKit::KCfNumberIntType, pointerof(number)) == 1
      return number
    end

    nil
  end

  private def self.to_s_array(input : String)
    array = StaticArray(UInt8, 128).new(0_u8)

    input.each_char_with_index do |char, index|
      array[index] = char.bytes[0]
    end

    array
  end

  end