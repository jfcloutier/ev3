defmodule Ev3.Moving do
	use Behaviour


	defcallback reset(motor :: %Ev3.Device{}) :: %Ev3.Device{}

	defcallback set_speed(motor :: %Ev3.Device{}, mode :: atom, speed :: number) :: %Ev3.Device{}
		
	defcallback reverse_polarity(motor :: %Ev3.Device{}) :: %Ev3.Device{} 

	defcallback set_duty_cycle(motor :: %Ev3.Device{}, duty_cycle :: number) :: %Ev3.Device{}  

	defcallback run(motor :: %Ev3.Device{}) :: %Ev3.Device{}  

	defcallback run_for(motor :: %Ev3.Device{}, duration :: number) :: %Ev3.Device{}  

	defcallback run_to_absolute(motor :: %Ev3.Device{}, degrees :: number) :: %Ev3.Device{}  

	defcallback run_to_relative(motor :: %Ev3.Device{}, degrees :: number) :: %Ev3.Device{}  

	defcallback coast(motor :: %Ev3.Device{}) :: %Ev3.Device{}  

	defcallback brake(motor :: %Ev3.Device{}) :: %Ev3.Device{}  

	defcallback hold(motor :: %Ev3.Device{}) :: %Ev3.Device{}

  defcallback set_ramp_up(motor :: %Ev3.Device{}, msecs :: number) :: %Ev3.Device{}

	defcallback set_ramp_down(motor :: %Ev3.Device{}, msecs :: number) :: %Ev3.Device{}

end
