defmodule Ev3.LegoMotor do
	@moduledoc "Lego motor access"

  alias Ev3.Device
	import Ev3.Sysfs
	require Logger

	@sys_path "/sys/class/tacho-motor"
  @prefix "motor" 
  @driver_regex ~r/lego-ev3-(\w)-motor/i

	@doc "Generates a list of all plugged in motor devices"
	def motors() do
		if !Ev3.testing?() do
			File.ls!(@sys_path)
			|> Enum.filter(&(String.starts_with?(&1, @prefix)))
			|> Enum.map(&(init_motor("#{@sys_path}/#{&1}")))
		else
			[Ev3.Mock.Tachomotor.new(:large, "A"),
			 Ev3.Mock.Tachomotor.new(:large, "B"),
			 Ev3.Mock.Tachomotor.new(:medium, "C")]
		end
  end

	defp module_for(_motor) do
		if !Ev3.testing?() do
			Ev3.Tachomotor
		else
			Ev3.Mock.Tachomotor
		end
	end

 @doc "Get the list of senses from a motor"
	def senses(motor) do
		apply(module_for(motor), :senses, [motor])
	end


	@doc "Read the value of a sense from a motor"
	def read(motor, sense) do # {value, updated_motor} - value can be nil
		try do
			apply(module_for(motor), :read, [motor, sense])
		rescue
			error ->
				Logger.warn("#{inspect error} when reading #{inspect sense} from #{inspect motor}")
				{nil, motor}
		end
	end

	@doc "Get how long to pause between reading a sense from a motor. In msecs"
	def pause(motor) do
			apply(module_for(motor), :pause, [motor])
	end

	@doc "Get the resolution of a motor (the delta between essentially identical readings). Nil or an integer."
	def sensitivity(motor, sense) do
			apply(module_for(motor), :sensitivity, [motor, sense])
	end

	  @doc "Is this a large motor?"
  def large?(motor) do
		motor.type == :large
  end

  @doc "Is this a medium motor?"
  def medium?(motor) do
		motor.type == :medium
  end

	def execute_command(motor, command, params) do
		apply(module_for(motor), command, [motor | params])
	end

	### PRIVATE

  defp init_motor(path) do
		port_name = read_sys(path, "port_name")
    driver_name = read_sys(path, "driver_name")
    [_, type_letter] = Regex.run(@driver_regex, driver_name)
    type = case type_letter do
						 "l" -> :large
						 "m" -> :medium
           end
    motor = %Device{class: :motor,
										path: path, 
										port: port_name, 
										type: type}
    count_per_rot = get_attribute(motor, "count_per_rot", :integer)
    commands = get_attribute(motor, "commands", :list)
		stop_commands = get_attribute(motor, "stop_commands", :list)
    %Device{motor | props: %{count_per_rot: count_per_rot, 
														 commands: commands,
														 stop_commands: stop_commands,
														 controls: Map.put_new(get_sys_controls(motor), 
																									 :speed_mode, 
																									 nil)}}  
  end

  defp get_sys_controls(motor) do
		%{polarity: get_attribute(motor, "polarity", :atom),
			speed:  get_attribute(motor, "speed_sp", :integer), # in counts/sec,
			duty_cycle:  get_attribute(motor, "duty_cycle_sp", :integer),
			ramp_up: get_attribute(motor, "ramp_up_sp", :integer),
			ramp_down: get_attribute(motor, "ramp_down_sp", :integer),
			position: get_attribute(motor, "position_sp", :integer), # in counts,
	 	  time: get_attribute(motor, "time_sp", :integer),
		  speed_regulation: get_attribute(motor, "speed_regulation", :atom)}
  end

end

