defmodule Ev3.MotivatorConfig do
	@moduledoc "A motivator's configuration"

	defstruct name: nil, focus: nil, motives: [], intents: [], span: nil, logic: nil

	@doc "Make a new motivator configuration"
	def new(name: name,
					focus: %{senses: _senses, motives: _motives, intents: _intents} = focus,
					span: span,
					logic:
					logic) do
		%Ev3.MotivatorConfig{name: name, focus: focus, span: span, logic: logic}
	end

end
