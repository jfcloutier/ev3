defmodule Ev3.Communicating do
	use Behaviour

	@doc "Communicate info to other robots in a team"
	defcallback communicate(info :: any, team :: atom) :: :any

end
