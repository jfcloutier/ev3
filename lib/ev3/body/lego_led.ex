defmodule Ev3.LegoLED do
	@moduledoc "Lego LED access"

	require Logger
	import Ev3.Sysfs
	alias Ev3.Device

	@sys_path "/sys/class/leds"
	@ev3_prefix "ev3:"
	@ev3_name_regex ~r/ev3:(.*):ev3dev/i
  @brickpi_prefix "brickpi:"
  @brickpi_name_regex ~r/brickpi:(.*):ev3dev/i
  

	@doc "Get the available LEDs"
	def leds() do
    case Ev3.platform() do
			:ev3 ->
	 		  File.ls!(@sys_path)
			  |> Enum.filter(&(String.starts_with?(&1, @ev3_prefix)))
			  |> Enum.map(&(init_ev3_led("#{&1}", "#{@sys_path}/#{&1}")))
      :brickpi ->
        File.ls!(@sys_path)
			  |> Enum.filter(&(String.starts_with?(&1, @brickpi_prefix)))
			  |> Enum.map(&(init_brickpi_led("#{&1}", "#{@sys_path}/#{&1}")))              
		  :dev ->
			    [Ev3.Mock.LED.new(:green, :left),
			     Ev3.Mock.LED.new(:green, :right),
			     Ev3.Mock.LED.new(:red, :left),
			     Ev3.Mock.LED.new(:red, :right),
			     Ev3.Mock.LED.new(:blue, :left),
			     Ev3.Mock.LED.new(:blue, :right)]
		end
  end

  @doc "Find a led device by position and color, or nil"
	def led(position: position, color: color) do
		leds()
		|> Enum.find(&(position(&1) == position and color(&1) == color))
	end

	@doc "Get left vs right position of the LED"
	def position(led) do
		led.props.position
	end

	@doc "Get the color of the LED"
	def color(led) do
		led.props.color
	end

	@doc "Get the LED max brightness"
	def max_brightness(led) do
		get_attribute(led, "max_brightness", :integer)
	end

	@doc "Get the current brightness"
	def brightness(led) do
		get_attribute(led, "brightness", :integer)
	end

	@doc "Set the brightness"
	def set_brightness(led, value) do
		set_attribute(led, "brightness", value)
		led
	end

	@doc "Execute an LED command"
	def execute_command(led, command, params) do
#		IO.puts("--- Executing LED #{led.path} #{command} #{inspect params}")
		spawn_link(fn() -> apply(module_for(led), command, [led | params]) end) # call to LEDs seems to be time-consuming
    led
	end

	### PRIVATE

	defp module_for(_led) do
		if !Ev3.testing? do
			Ev3.LegoLED
		else
			Ev3.Mock.LED
		end
	end

	defp init_ev3_led(dir_name, path) do
		[_, type] = Regex.run(@ev3_name_regex, dir_name)
		led = %Device{class: :led,
									path: path,
									port: nil,
									type: type}
		[_, color] = Regex.run(~r/\w+:(\w+)/, type)
		[_, position] = Regex.run(~r/(\w+):\w+/, type)
		%Device{led | props: %{position: String.to_atom(position), color: String.to_atom(color)}}
	end

  	defp init_brickpi_led(dir_name, path) do
		[_, type] = Regex.run(@brickpi_name_regex, dir_name)
		led = %Device{class: :led,
									path: path,
									port: nil,
									type: type}
		[_, color] = Regex.run(~r/\w+:(\w+)/, type)
		[_, pos] = Regex.run(~r/(\w+):\w+/, type)
    position = case pos do
      "led1" -> "left"
      "led2" -> "right"
    end
		%Device{led | props: %{position: String.to_atom(position), color: String.to_atom(color)}}
	end

end
