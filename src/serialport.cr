require "./serialports/*"

require "./serial_ports"



SerialPorts::Port.open("/dev/ttyACM0") do |io, p|
  io.write_byte 33u8

  while true
    puts "Reading Byte"
    byte = io.read_byte
    pp byte.as(UInt8).unsafe_chr
    puts "Sending Byte"
    io.write_byte byte.as(UInt8) + 1u8
  end
end

# pp SerialPorts.list()