defmodule Ev3.Perception do

	import Ev3.PerceptionUtils
	alias Ev3.PerceptorDef
	alias Ev3.Percept

	def perceptor_defs() do
		[
				PerceptorDef.new(
					name: :motion_perceptor,
					senses: [:speed, :motion],
					span: nil, # no windowing
					retain: {60, :secs},
					logic: motion())
		]
	end

	### Private

	defp motion() do
		fn
		(_percept, []) -> nil
	  (%Percept{sense: :speed, value: 0}, history) ->
				if all_percepts_since?(history, :speed, 100, fn(value) -> value == 0 end) do
					Percept.new(sense: :motion, value: :stopped)
				else
					nil
				end
		(%Percept{sense: :speed, value: val}, history) when abs(val) > 0 ->
		    from_stopped? = latest_percept?(history, :motion, fn(value) -> value == :stopped end)
		    moving? = all_percepts_since?(history, :speed, 100, fn(value) -> abs(value) > 0 end)
		    if from_stopped? and moving? do
			    Percept.new(sense: :motion, value: :started)
		    else
		    	nil
	    	end
		end
	end
		
end
