defmodule Ev3.Tachomotor do
	@moduledoc "Tachomotor access"

  import Ev3.Sysfs
  alias Ev3.Device

	@sys_path "/sys/class/tacho-motor"
  @prefix "motor" 
  @driver_regex ~r/lego-ev3-(\w)-motor/i

	@doc "Generates a list of all plugged in motor devices"
	def motors() do
		File.ls!(@sys_path)
    |> Enum.filter(&(String.starts_with?(&1, @prefix)))
    |> Enum.map(&(init_motor("#{@sys_path}/#{&1}")))
  end

	@doc "Reset a motor to defaul control values"
  def reset(motor) do
		execute_command(motor, "reset")
		refresh_controls(motor)
  end

	@doc "Run a motor forever at speed or duty cycle, according to controls"
  def run(motor) do
		apply_motor_controls(motor)
		if target_speed(motor, :dps) == 0 do
			execute_command(motor, "run-direct")
    else
		  execute_command(motor, "run-forever")
    end
		motor
  end

	@doc "Run a motor for some time according to controls"
  def run_for(motor, msecs) when is_integer(msecs) do
		motor1 = set_control(motor, :time, msecs)
		apply_motor_controls(motor1)
		execute_command(motor1, "run-timed")
		motor1
  end

	@doc "Run a motor to an absolute position in degrees according to controls"
  def run_to_absolute(motor, degrees) do
		run_to_position(motor, :absolute, degrees)
  end

	@doc "Run a motor to a relative position in degrees according to controls"
  def run_to_relative(motor, degrees) do
		run_to_position(motor, :relative, degrees)
		motor
  end

	@doc "Coast a motor to a halt according to controls"
  def coast(motor) do
		apply_motor_controls(motor)
		execute_stop_command(motor, "coast")
		# Patches running flag not removed by stopping
		reset(motor)		
    apply_motor_controls(motor)
    motor
  end

	@doc "Brake a motor to a sudden halt according to controls"
  def brake(motor) do
		apply_motor_controls(motor)
		execute_stop_command(motor, "brake")
		# Patches running flag not removed by stopping
		reset(motor)
    apply_motor_controls(motor)
		motor
  end

	@doc "Actively hold a motor to its current position according to controls"
  def hold(motor) do
		apply_motor_controls(motor)
		execute_stop_command(motor, "hold")
		motor
  end

  @doc "Reverse the motor's polarity (the direction it rotates in)"
  def reverse_polarity(motor) do
		case get_control(motor, :polarity) do
			:normal -> set_control(motor, :polarity, :inversed)
      :inversed -> set_control(motor, :polarity, :normal)
    end
  end

  @doc "Get current polarity"
  def polarity(motor) do
		get_control(motor, :polarity)
  end

	@doc "Change the motor's duty cycle. Immediately effective only when running direct"
  def set_duty_cycle(motor, value) when value in -100 .. 100 do
		set_attribute(motor, "duty_cycle_sp", value) #takes effect immediately
		motor
		 |> set_control(:duty_cycle, value)
		 |> set_control(:speed, 0)
  end

  @doc "Get target duty cycle"
  def target_duty_cycle(motor) do
		get_control(motor, :duty_cycle)
  end

	@doc "Set the target speed to maintain in degrees per second"
  def set_speed(motor, :dps, value) when is_number(value) do
		count_per_sec = round(value * count_per_rot(motor) / 360)
		motor
		|> set_control(:speed_regulation, :on)
    |> set_control(:speed_mode, :dps)
		|> set_control(:speed, count_per_sec)
  end

	@doc "Set the target speed to maintain in rotations per second"
  def set_speed(motor, :rps, value) when is_number(value) do
		count_per_sec = round(value * count_per_rot(motor))
		motor
		|> set_control(:speed_regulation, :on)
    |> set_control(:speed_mode, :rps)
		|> set_control(:speed, count_per_sec)
  end

	@doc "Get the target speed in rotations per second"
  def target_speed(motor, :rps) do # rotations per second
    get_control(motor, :speed) / count_per_rot(motor)
  end

	@doc "Get the target speed in degrees per second"
  def target_speed(motor, :dps) do # degrees per second
		get_control(motor, :speed) * (360 / count_per_rot(motor))
  end

  @doc "Set the target position in degrees"
	def set_target_degrees(motor, degrees) when is_number(degrees) do
		count = round(degrees * count_per_rot(motor) / 360)
		set_control(motor, :position, count)
	  end  

  @doc "Set the target position in rotations"
	def set_target_rotations(motor, rotations) when is_number(rotations) do
		count =  round(rotations * count_per_rot(motor) / 360)
		set_control(motor, :position, count)
  end  

	@doc "Get the target position in rotations"
  def target_rotations(motor) do
    get_control(motor, :position) / count_per_rot(motor)
  end

	@doc "Get the target position in degrees"
  def target_degrees(motor) do
		get_control(motor, :position) * (360 / count_per_rot(motor))
  end

	@doc "Set the ramp up time in msecs"
	def set_ramp_up(motor, msecs) when is_integer(msecs) and msecs >= 0 do
		set_control(motor, :ramp_up, msecs)
  end

	@doc "Set the ramp down time in msecs"
	def set_ramp_down(motor, msecs) when is_integer(msecs) and msecs >= 0 do
		set_control(motor, :ramp_down, msecs)
 end

	@doc "Get the actual motor speed"
  def current_speed(motor, mode) do
		speed = get_attribute(motor, "speed", :integer)
		case mode do
			:dps -> speed * (360 / motor.props.count_per_rot)
			:rps -> speed / motor.props.count_per_rot
    end
  end

	@doc "Get the actual motor's duty cycle"
  def current_duty_cycle(motor) do
		get_attribute(motor, "duty_cycle", :percent)
  end

	@doc "Get the actual position of the motor in degrees"
  def current_position(motor) do
		position = get_attribute(motor, "position", :integer)
    round(position * count_per_rot(motor) / 360)
  end

  @doc "Is this a large motor?"
  def large?(motor) do
		motor.type == :large
  end

  @doc "Is this a medium motor?"
  def medium?(motor) do
		motor.type == :medium
  end

	@doc "Is the motor running?"
	## BUG - The running flag stays on after the motor is stopped. Cleared only by reset.
  def running?(motor) do
	  has_state?(motor, "running")
  end

	@doc "Is the motor ramping up or down?"
  def ramping?(motor) do
	  has_state?(motor, "ramping")
  end

	@doc "Is the motor holding?"
  def holding?(motor) do
	  has_state?(motor, "holding")
  end

	@doc "Is the motor stalled?"
  def stalled?(motor) do
	  has_state?(motor, "stalled")
  end

  ## PRIVATE

  defp run_to_position(motor, rel_or_abs, degrees) when rel_or_abs in [:relative, :absolute] do
		motor1 = set_control(motor, :position, round(degrees * count_per_rot(motor) / 360))
		apply_motor_controls(motor1)
		case rel_or_abs do
			:absolute -> execute_command(motor1, "run-to-abs-pos")
			:relative -> execute_command(motor1, "run-to-rel-pos")
    end
    motor1
  end

  defp get_control(motor, control) do
		Map.get(motor.props.controls, control)
  end

  defp set_control(motor, control, value) do
		%Device{motor | props: %{motor.props | controls: Map.put(motor.props.controls, control, value)}}
  end

  defp count_per_rot(motor) do
		Map.get(motor.props, :count_per_rot)
  end

  defp has_state?(motor, state) do
		states = get_attribute(motor, "state", :string)
		state in String.split(states, " ")
  end 

  defp init_motor(path) do
		port_name = read_sys(path, "port_name")
    driver_name = read_sys(path, "driver_name")
    [_, type_letter] = Regex.run(@driver_regex, driver_name)
    type = case type_letter do
						 "l" -> :large
						 "m" -> :medium
           end
    motor = %Device{class: :tacho_motor,
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

  defp refresh_controls(motor) do
		speed_mode = get_control(motor, :speed_mode)
		%Device{motor | 
						  props: %{motor.props |
												  controls: Map.put_new(get_sys_controls(motor), :speed_mode, speed_mode)}}
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

  defp apply_motor_controls(motor) do
		set_attribute(motor, "speed_regulation", get_control(motor, :speed_regulation))
		speed = case motor.type do
							:large -> min(get_control(motor, :speed), 900)
							:medium -> min(get_control(motor, :speed), 1200)
						end
		set_attribute(motor, "speed_sp", speed)
		set_attribute(motor, "duty_cycle_sp", get_control(motor, :duty_cycle))
		set_attribute(motor, "polarity", get_control(motor, :polarity))
		set_attribute(motor, "ramp_up_sp", get_control(motor, :ramp_up))
		set_attribute(motor, "ramp_down_sp", get_control(motor, :ramp_down))
		set_attribute(motor, "position_sp", get_control(motor, :position))
		set_attribute(motor, "time_sp", get_control(motor, :time))
		:ok
	end

end

