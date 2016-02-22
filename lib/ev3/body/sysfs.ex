defmodule Ev3.Sysfs do
	@moduledoc "Interface to sysfs device files"

  alias Ev3.{LegoMotor, LegoSensor, Device}
  require Logger
  
  @ports_path "/sys/class/lego-port"
	@doc "Get the typed value of an attribute of the device"
  def get_attribute(device, attribute, type) do 
		value = read_sys(device.path, attribute)
    case type do
			:string -> value
			:atom -> String.to_atom(value)
      :percent -> {number, _} = Integer.parse(value)
			            min(max(number, 0), 100)
			:integer -> {number, _} = Integer.parse(value)
									number
			:list -> String.split(value, " ")
    end
  end

	@doc "Set the value of an attribute of the device"
  def set_attribute(device, attribute, value) do
		write_sys(device.path, attribute, "#{value}")
  end

 @doc "Reading a line from a file"
 def read_sys(dir, file) do
		[line] = File.stream!("#{dir}/#{file}")
		|> Stream.take(1)
    |> Enum.to_list()
    String.strip(line)
	end

 @doc "Writing a line to a file"
 def write_sys(dir, file, line) do
	 File.write!("#{dir}/#{file}", line)
 end

 @doc "Execute a command on a device"
 def execute_command(device, command) do
	 true = command in device.props.commands
	 write_sys(device.path, "command", command)
 end
 
 @doc "Execute a stop command on a device"
 def execute_stop_command(device, command) do
	 true = command in device.props.stop_commands
	 write_sys(device.path, "stop_command", command)
 end
 
 @doc "Associate a BrickPi port with an Ev3 motor or sensor" 
 def set_brickpi_port(port, device_type) do
   if (port in [:in1, :in2, :in3, :in4] and LegoSensor.sensor?(device_type))
   or (port in [:outA, :outB, :outC, :outD] and LegoMotor.motor?(device_type)) do
     port_path = "#{@ports_path}/port#{brickpi_port_number(port)}"
     Logger.info("#{port_path}/mode <- #{Device.mode(device_type)}")
     File.write!("#{port_path}/mode", Device.mode(device_type))
     :timer.sleep(500)
     if not Device.self_loading_on_brickpi?(device_type) do
       Logger.info("#{port_path}/set_device <- #{Device.device_code(device_type)}")
       :timer.sleep(500)
       File.write!("#{port_path}/set_device", Device.device_code(device_type))
     end
     :ok
   else
     {:error, "Incompatible or incorrect #{port} and #{device_type}"}
		 end
 end

 ### PRIVATE

 def brickpi_port_number(port) do
   case port do
     :in1 -> 0
     :in2 -> 1
     :outA -> 2
     :outB -> 3
     :in3 -> 4
     :in4 -> 5
     :outC -> 6
     :outD -> 7
   end
 end

end
