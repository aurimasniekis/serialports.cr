module SerialPorts
    struct PortMetadata
        property name            : String
        property transport       : String
        property description     : String?
        property usbVID          : Int32?
        property usbPID          : Int32?
        property usbVendorName   : String?
        property usbProductName  : String?
        property usbSerialNumber : String?

        def initialize(
            @name : String,
            @transport : String,
            @description : String?,
            @usbVID : Int32?,
            @usbPID : Int32?,
            @usbVendorName :  String?,
            @usbProductName : String?,
            @usbSerialNumber : String?
            )
        end
    end

    class Port
        enum BaudRate
            B50 = 50
            B75 = 75
            B110 = 110
            B134 = 134
            B150 = 150
            B200 = 200
            B300 = 300
            B600 = 600
            B1200 = 1200
            B1800 = 1800
            B2400 = 2400
            B4800 = 4800
            B7200 = 7200
            B9600 = 9600
            B14400 = 14400
            B19200 = 19200
            B28800 = 28800
            B38400 = 38400
            B57600 = 57600
            B76800 = 76800
            B115200 = 115200
            B230400 = 230400
        end
    
        enum ParityMode
            PARITY_NONE = 0
            PARITY_ODD  = 1
            PARITY_EVEN = 2
        end

        property metadata              : PortMetadata?

        property portName              : String?
        property baudRate              : Int32?
        property dataBits              : Int32?
        property stopBits              : Int32?
        property parityMode            : ParityMode?
        property interCharacterTimeout : Int32?
        property minimumReadSize       : Int32?

        def self.open(portName : String, baudRate : Int32 = BaudRate::B9600, dataBits : Int32 = 8, stopBits : Int32 = 1, parityMode : ParityMode = ParityMode::PARITY_NONE, interCharacterTimeout : Int32 = 0, minimumReadSize : Int32 = 1)
            instance = Driver.get_port_by_name(portName)

            if instance.nil?
                raise "SerialPort #{portName} not found."
            end

            instance = instance.as(Port)

            instance.baudRate = baudRate
            instance.dataBits = dataBits
            instance.stopBits = stopBits
            instance.parityMode = parityMode
            instance.interCharacterTimeout = interCharacterTimeout
            instance.minimumReadSize = minimumReadSize
            
            instance.open
        end

        def initialize(@portName : String, @metadata : PortMetadata)
        end

        def open
        end

        def metadata
            @metadata
        end

    end
end