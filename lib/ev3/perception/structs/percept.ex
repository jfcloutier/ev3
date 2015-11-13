defmodule Ev3.Percept do

	import Ev3.PerceptionUtils

	defstruct sense: nil, since: nil, until: nil, source: nil, retain: nil, value: nil

	def new(sense: sense, value: value) do
		msecs = now()
		%Ev3.Percept{sense: sense,
								 since: msecs,
								 until: msecs,
							   value: value}
	end

	def same?(percept1, percept2) do
		percept1.sense == percept2.sense
		and percept1.value == percept2.value
		and percept1.source == percept2.source
	end
	
end
