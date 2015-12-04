defmodule Ev3.Transition do
	@moduledoc "A state transition in a finite state machine"

	defstruct from: nil, on: nil, to: nil, condition: nil, doing: nil
	
end
