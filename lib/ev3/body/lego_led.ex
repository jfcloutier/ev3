defmodule Ev3.LegoLED do
	@moduledoc "Lego LED access"

	require Logger
	import Ev3.Sysfs
	alias Ev3.Device

	@sys_path "/sys/class/leds"
	@prefix "ev3:"
	@name_regex ~r/ev3:(.*):ev3dev/i

	@doc "Get the available LEDs"
	def leds() do
			if !Ev3.testing?() do
	 		File.ls!(@sys_path)
			|> Enum.filter(&(String.starts_with?(&1, @prefix)))
			|> Enum.map(&(init_led("#{&1}", "#{@sys_path}/#{&1}")))
		else
			[Ev3.Mock.LED.new(:green, :left),
			 Ev3.Mock.LED.new(:green, :right),
			 Ev3.Mock.LED.new(:red, :left),
			 Ev3.Mock.LED.new(:red, :right)]
		end
  end

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
		apply(module_for(led), command, [led | params])
	end



	### Private

	defp module_for(_led) do
		if !Ev3.testing? do
			Ev3.LegoLED
		else
			Ev3.Mock.LED
		end
	end

	defp init_led(dir_name, path) do
		[_, type] = Regex.run(@name_regex, dir_name)
		led = %Device{class: :led,
									path: path,
									port: nil,
									type: type}
		[_, color] = Regex.run(~r/\w+:(\w+)/, type)
		[_, position] = Regex.run(~r/(\w+):\w+/, type)
		%Device{led | props: %{position: String.to_atom(position), color: String.to_atom(color)}}
	end

end
