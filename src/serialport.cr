require "./serialports/*"

lib LibC
  VTIME = 16
  O_NOCTTY = 0x20000
end


require "./serial_ports"

SerialPorts::Port.open("/dev/cu.usbmodem142121") do |io, p|
  io.write_byte 33u8

  while true
    puts "Reading Byte"
    byte = io.read_byte
    pp byte
    puts "Sending Byte"
    io.write_byte byte.as(UInt8) + 1u8
  end
end