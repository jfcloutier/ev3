defmodule Ev3.LegoSensor do
	@moduledoc "Lego sensor access"

	require Logger
	import Ev3.Sysfs
	alias Ev3.Device
	alias Ev3.TouchSensor
	alias Ev3.ColorSensor
	alias Ev3.InfraredSensor

	@sys_path "/sys/class/lego-sensor"
  @prefix "sensor"
	@driver_regex ~r/lego-ev3-(\w+)/i
	@mode_switch_delay 100

	@doc "Get the currently connected lego sensors"
  def sensors() do
		File.ls!(@sys_path)
   |> Enum.filter(&(String.starts_with?(&1, @prefix)))
   |> Enum.map(&(init_sensor("#{@sys_path}/#{&1}")))
  end

	def senses(sensor) do
		case sensor.type do
			:touch -> TouchSensor.senses(sensor)
			:color -> ColorSensor.senses(sensor)
			:infrared -> InfraredSensor.senses(sensor)
		end	
	end

	def read(sensor, sense) do # {value, updated_sensor} - value can be nil
		try do
			case sensor.type do
				:touch -> TouchSensor.read(sensor, sense)
				:color -> ColorSensor.read(sensor, sense)
				:infrared -> InfraredSensor.read(sensor, sense)
			end
		rescue
			error ->
				Logger.warn("#{inspect error} when reading #{inspect sense} from #{inspect sensor}")
				{nil, sensor}
		end
	end

	def pause(sensor) do
		case sensor.type do
			:touch -> TouchSensor.pause(sensor)
			:color -> ColorSensor.pause(sensor)
			:infrared -> InfraredSensor.pause(sensor)
		end	
	end

	def sensitivity(sensor) do
		case sensor.type do
			:touch -> TouchSensor.sensitivity(sensor)
			:color -> ColorSensor.sensitivity(sensor)
			:infrared -> InfraredSensor.sensitivity(sensor)
		end	
	end

	@doc "Is this the ultrasonic sensor?"
  def ultrasonic?(sensor) do
		sensor.type == :ultrasonic
  end

	@doc "Is this the gyro sensor?"
  def gyro?(sensor) do
		sensor.type == :gyro
  end

	@doc "Is this the color sensor?"
  def color?(sensor) do
		sensor.type == :color
  end

	@doc "Is this the touch sensor?"
  def touch?(sensor) do
		sensor.type == :touch
  end

	@doc "Is this the infrared sensor?"
  def infrared?(sensor) do
		sensor.type == :infrared
  end

	@doc "Set the sensor's mode"
  def set_mode(sensor, mode) do
		if mode(sensor) != mode do
			set_attribute(sensor, "mode", mode)
			# Logger.debug("Switched #{sensor.path} mode to #{mode}")
			:timer.sleep(@mode_switch_delay) # Give time for the mode switch
			%Device{sensor | props: %{sensor.props | mode: mode}}
		else
			sensor
		end
  end

  @doc "Get the sensor mode"
  def mode(sensor) do
		sensor.props.mode
  end


  #### PRIVATE

  defp init_sensor(path) do
		port_name = read_sys(path, "port_name")
    driver_name = read_sys(path, "driver_name")
    [_, type_name] = Regex.run(@driver_regex, driver_name)
    type = case type_name do
						 "us" -> :ultrasonic
						 "gyro" -> :gyro
						 "color" -> :color
						 "touch" -> :touch
						 "ir" -> :infrared
           end
    sensor = %Device{class: :sensor,
						path: path, 
						port: port_name, 
						type: type}
		mode = get_attribute(sensor, "mode", :string)
    %Device{sensor | props: %{mode: mode}}    
  end

end
