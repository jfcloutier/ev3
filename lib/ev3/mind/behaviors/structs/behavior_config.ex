defmodule Ev3.BehaviorConfig do
	@moduledoc "A behavior's configuration"

	defstruct name: nil, motivated_by: [], senses: [], fsm: nil

  @doc "Make a new reflex behavior configuration"
	def new(name: name,
					senses: senses,
					fsm: fsm) do
    new(name: name,
					motivated_by: [],
					senses: senses,
					fsm: fsm)
  end

  @doc "Make a new motivated behavior configuration"
	def new(name: name,
					motivated_by: motive_names,
					senses: senses,
					fsm: fsm) do
		%Ev3.BehaviorConfig{name: name,
												motivated_by: motive_names,
												senses: senses,
												fsm: fsm}
	end

  @doc "Does this define a reflex?"
  def reflex?(config) do
    config.motivated_by == []
  end

end
