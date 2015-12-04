defmodule Ev3.Motive do
	@moduledoc "A struct for a motive (a unit of intent)"

	import Ev3.Utils

	# A "memorizable" - must have about, since and value fields

	# inhibits: what motives this one inhibits
	# value: either :on or :off
	defstruct about: nil, since: nil, inhibits: [], value: nil, source: nil

	@doc "Create an motive that's on"
	def on(name) do
	  %Ev3.Motive{about: name,
                since: now(),
							  value: :on}
  end

	@doc "Create a motive that's off (to turn off an on motive of the same name)"
	def off(name) do
	  %Ev3.Motive{about: name,
                since: now(),
							  value: :off}
  end

	@doc "Is the motive on?"
	def on?(motive) do
		motive.value == :on
	end
	
	@doc "Add an inhibition"
	def inhibit(motive, other) do
		%Ev3.Motive{motive | inhibits: [other | motive.inhibits]}
	end
	
end							
