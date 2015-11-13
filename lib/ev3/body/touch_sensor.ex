defmodule Ev3.TouchSensor do
	@moduledoc "Touch sensor"

  import Ev3.Sysfs

	@doc "Get the state of the touch sensor (:pressed or :released)"
  def state(sensor) do
		case get_attribute(sensor, "value0", :integer) do
			0 -> :released
			1 -> :pressed
    end
  end

	@doc "Is the touch sensor pressed"
  def pressed?(sensor) do
		state(sensor) == :pressed
  end

	@doc "Is the touch sensor released?"
  def released?(sensor) do
		state(sensor) == :released
  end

end
