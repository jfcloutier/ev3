defmodule Ev3.Sysfs do
	@moduledoc "Interface to sysfs device files"

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

end
