defmodule Ev3.Perception do
	@docmodule "Provides the configurations of all perceptors to be activated"

	import Ev3.PerceptionUtils
	require Logger
	alias Ev3.PerceptorConfig
	alias Ev3.Percept

	@doc "Give the configurations of all perceptors to be activated"
	def perceptor_configs() do
		[
				# A collision perceptor based on proximity sensing
				PerceptorConfig.new(
					name: :collision_perceptor,
					senses: [:proximity, :touch, :collision],
					span: nil, # no windowing
					retain: {30, :secs}, # remember for 30 seconds
					logic: collision()),
				PerceptorConfig.new(
					name: :fear_perceptor,
					senses: [:ambient, :collision, :scared],
					span: {10, :secs}, # only react to what happened in the last 10 seconds
					retain: {2, :mins}, # remember for 2 minutes
					logic: scared())
		]
	end

	### Private

	@doc "Is a collision soon, imminent or now?"
	def collision() do
		fn
				(_percept, []) -> nil
				(%Percept{sense: :proximity, value: n}, history) when n < 10 ->
					if not any_percept?(
								history,
								:proximity,
								1000,
								fn(value) -> value > 10 end) do
						Percept.new(sense: :collision, value: :imminent)
					else
						nil
					end
				(%Percept{sense: :proximity, value: val}, history) ->
					approaching? = latest_percept?(
						history,
						:proximity,
						fn(previous) -> val < previous  end)
					proximal? = all_percepts?(
						history,
						:proximity,
						5000,
						fn(value) -> value < 50 end)
					if approaching? and proximal? do
						Percept.new(sense: :collision, value: :soon)
					else
		    		nil
	    		end
				(%Percept{sense: :touch, value: :pressed}, history) ->
						if any_percept?(
									history,
									:collision,
									5000,
									fn(value) -> value == :imminent end) do
							Percept.new(sense: :collision, value: :now)
						else
							nil
						end
				(_, _) -> nil
		end
	end

		@doc "Should the robot be scared?"
	def scared() do
		fn
		    (_percept, []) -> nil
		    (%Percept{sense: :collision, value: :now}, history) ->
				    if all_percepts?(
							history,
							:ambient,
							3000,
							fn(value) -> value < 5 end) do
					      Percept.new(sense: :scared, value: :very)
			    	else
				      	Percept.new(sense: :scared, value: :a_little)
			    	end
				(_,_) -> nil
		end
	end
		
end
