{% if flag?(:linux) %}
require "./serialports/lib/linux/driver"
{% elsif flag?(:darwin) %}
require "./serialports/lib/darwin/driver"
{% else %}
raise "Not Supported Platform"
{% end %}

module SerialPorts
    def self.list
        return Driver.list
    end

    def self.get(portName : String) : Port?
        return Driver.get_port_by_name(portName)
    end
end