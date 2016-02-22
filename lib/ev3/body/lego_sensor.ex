defmodule Ev3.LegoSensor do
	@moduledoc "Lego sensor access"

	require Logger
	import Ev3.Sysfs
	alias Ev3.Device

	@sys_path "/sys/class/lego-sensor"
  @prefix "sensor"
	@driver_regex ~r/lego-ev3-(\w+)/i
	@mode_switch_delay 100

	@doc "Get the currently connected lego sensors"
  def sensors() do
		if !Ev3.testing?() do
	 		files = case File.ls(@sys_path) do
								{:ok, files} -> files
								{:error, reason} ->
									Logger.warn("Failed getting sensor files: #{inspect reason}")
									[]
							end
			files
			|> Enum.filter(&(String.starts_with?(&1, @prefix)))
			|> Enum.map(&(init_sensor("#{@sys_path}/#{&1}")))
		else
			[Ev3.Mock.TouchSensor.new(),
       Ev3.Mock.ColorSensor.new(),
       Ev3.Mock.InfraredSensor.new(),
       Ev3.Mock.UltrasonicSensor.new(),
       Ev3.Mock.GyroSensor.new()]
		end
  end

  @doc "Is this type of device a sensor?"
  def sensor?(device_type) do
    device_type in [:touch, :infrared, :color, :ultrasonic, :gyro]
  end

	@doc "Get the list of senses from a sensor"
	def senses(sensor) do
		apply(module_for(sensor), :senses, [sensor])
	end


	@doc "Read the value of a sense from a sensor"
	def read(sensor, sense) do # {value, updated_sensor} - value can be nil
		try do
			apply(module_for(sensor), :read, [sensor, sense])
		rescue
			error ->
				Logger.warn("#{inspect error} when reading #{inspect sense} from #{inspect sensor}")
				{nil, sensor}
		end
	end

	@doc "Get how long to pause between reading a sense from a sensor. In msecs"
	def pause(sensor) do
			apply(module_for(sensor), :pause, [sensor])
	end

	@doc "Get the resolution of a sensor (the delta between essentially identical readings). Nil or an integer."
	def sensitivity(sensor, sense) do
			apply(module_for(sensor), :sensitivity, [sensor, sense])
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

	defp module_for(sensor) do
		if !Ev3.testing?() do
			case sensor.type do
				:touch -> Ev3.TouchSensor
				:color -> Ev3.ColorSensor
				:infrared -> Ev3.InfraredSensor
        :ultrasonic -> Ev3.UltrasonicSensor
        :gyro -> Ev3.GyroSensor
			end
		else
			case sensor.type do
				:touch -> Ev3.Mock.TouchSensor
				:color -> Ev3.Mock.ColorSensor
				:infrared -> Ev3.Mock.InfraredSensor
        :ultrasonic -> Ev3.Mock.UltrasonicSensor
        :gyro -> Ev3.Mock.GyroSensor
			end
		end
	end

  defp init_sensor(path) do
		port_name = read_sys(path, "address")
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
