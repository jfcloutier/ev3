defmodule Ev3.Percept do
  @moduledoc "A struct for a percept (a unit of perception). A percept is either generated from a sensor or synthesized from memorized percepts, motives and commands."
	
	import Ev3.Utils

	# A "memorizable" - must have about, since and value fields
	
	# resolution is the precision of the detector or perceptor. Nil if perfect resolution.
	defstruct about: nil, since: nil, until: nil, source: nil, ttl: nil, resolution: nil, value: nil, transient: false

	@doc "Create a new percept with sense and value set"
	def new(about: sense, value: value) do
		msecs = now()
		%Ev3.Percept{about: sense,
								 since: msecs,
								 until: msecs,
							   value: value}
	end

	@doc "Create a new percept with sense, value set"
	def new_transient(about: sense, value: value) do
		msecs = now()
		%Ev3.Percept{about: sense,
								 since: msecs,
								 until: msecs,
							   value: value,
							 	 transient: true}
	end
	
	@doc "Are two percepts essentially the same (same sense, value and source)?"
	def same?(percept1, percept2) do
		percept1.about == percept2.about
		and percept1.value == percept2.value
		and percept1.source == percept2.source
	end
	
end
