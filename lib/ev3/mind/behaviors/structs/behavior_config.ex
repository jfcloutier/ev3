defmodule Ev3.BehaviorConfig do
	@moduledoc "A behavior's configuration"

	defstruct name: nil, motivated_by: nil, senses: nil, fsm: nil

	@doc "Make a new behavior configuration"
	def new(name: name,
					motivated_by: motive_names,
					senses: senses,
					fsm: fsm) do
		%Ev3.BehaviorConfig{name: name,
												motivated_by: motive_names,
												senses: senses,
												fsm: fsm}
	end

end
