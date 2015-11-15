defmodule Ev3.Sensing do
	use Behaviour

	@doc "Get all the senses a sensor possesses"
	defcallback senses(sensor :: %Ev3.Device{}) :: [any]

	@doc "Get the current value of a sense"
	defcallback read(sensor :: %Ev3.Device{} , sense :: any) :: any

	@doc "Get how long to pause before reading the next sense value"
	defcallback pause(sensor :: %Ev3.Device{}) :: integer

	@doc "Get the sensitivity of the device; the change in value to be noticed"
	defcallback sensitivity(sensor :: %Ev3.Device{}) :: integer | nil

end

