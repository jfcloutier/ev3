defmodule Ev3.Percept do
  @moduledoc "A struct for a percept (a unit of perception)"
	
	import Ev3.PerceptionUtils

	# resolution is the precision of the detector or perceptor. Nil if perfect resolution.
	defstruct sense: nil, since: nil, until: nil, source: nil, retain: nil, resolution: nil, value: nil

	@doc "Create a new percept with sense and value set"
	def new(sense: sense, value: value) do
		msecs = now()
		%Ev3.Percept{sense: sense,
								 since: msecs,
								 until: msecs,
							   value: value}
	end

	@doc "Are two percepts essentially the same (same sense, value and source)?"
	def same?(percept1, percept2) do
		percept1.sense == percept2.sense
		and percept1.value == percept2.value
		and percept1.source == percept2.source
	end
	
end
