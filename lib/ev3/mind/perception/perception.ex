defmodule Ev3.Perception do
	@moduledoc "Provides the configurations of all perceptors to be activated"

	import Ev3.MemoryUtils
	require Logger
	alias Ev3.PerceptorConfig
	alias Ev3.Percept

	@doc "Give the configurations of all perceptors to be activated"
	def perceptor_configs() do
		[
				# A getting darker or lighter perceptor
				PerceptorConfig.new(
					name: :darker_lighter_perceptor,
					focus: %{senses: [:ambient], motives: [], intents: []},
					span: {10, :secs},
					ttl: {30, :secs},
					logic: darker()),
				# A getting lighter perceptor
				PerceptorConfig.new(
					name: :lighter_perceptor,
					focus: %{senses: [:ambient], motives: [], intents: []},
					span: {10, :secs},
					ttl: {30, :secs},
					logic: lighter()),
				# A collision perceptor based on proximity sensing
				PerceptorConfig.new(
					name: :collision_perceptor,
					focus: %{senses: [:proximity, :touch, :collision], motives: [], intents: []},
					span: nil, # no windowing
					ttl: {30, :secs}, # remember for 30 seconds
					logic: collision()),
				PerceptorConfig.new(
					name: :fear_perceptor,
					focus: %{senses: [:ambient, :collision, :scared], motives: [], intents: []},
					span: {10, :secs}, # only react to what happened in the last 10 seconds
					ttl: {2, :mins}, # remember for 2 minutes
					logic: scared()),
				PerceptorConfig.new(
					name: :hunger_perceptor,
					focus: %{senses: [:time_elapsed], motives: [], intents: [:eat]},
					span: {10, :mins},
					ttl: {5, :mins},
					logic: hungry()),
				# A food perceptor
				PerceptorConfig.new(
					name: :food_perceptor,
					focus: %{senses: [:ambient, :color], motives: [], intents: []},
					span: {30, :secs},
					ttl: {2, :mins},
					logic: food())
		]
	end

	### Private

	def darker() do
		fn
		(_percept, %{percepts: []}) -> nil
		(%Percept{about: :ambient, value: val}, %{percepts: percepts}) ->
				previous = Enum.find(percepts, &(&1.about == :ambient))
				if previous != nil and val < previous.value do
					Percept.new(about: :darker, value: previous.value - val)
				else
					nil	  
				end
		end
	end

	def lighter() do
		fn
		(_percept, %{percepts: []}) -> nil
		(%Percept{about: :ambient, value: val}, %{percepts: percepts}) ->
				previous = Enum.find(percepts, &(&1.about == :ambient))
				if previous != nil and val > previous.value do
					Percept.new(about: :darker, value: val - previous.value)
				else
					nil	  
				end
		end
	end

	def food() do
		fn						 
		  (_percept, %{percepts: []}) -> nil
			(%Percept{about: :color, value: :green}, %{percepts: percepts}) ->
			  if latest_memory?(
						percepts,
						:ambient,
						fn(value) -> value > 50  end) do
				  Percept.new(about: :food, value: :plenty)
			  else
				  Percept.new(about: :food, value: :little)	  
			  end
		  (_, _) -> nil
		end
	end

	@doc "Is a collision soon, imminent or now?"
	def collision() do
		fn
		(_percept, %{percepts: []}) -> nil
		(%Percept{about: :proximity, value: n}, %{percepts: percepts}) when n < 10 ->
				if not any_memory?(
							percepts,
							:proximity,
							1000,
							fn(value) -> value > 10 end) do
					Percept.new(about: :collision, value: :imminent)
				else
					nil
				end
				(%Percept{about: :proximity, value: val}, %{percepts: percepts}) ->
				approaching? = latest_memory?(
					percepts,
					:proximity,
					fn(previous) -> val < previous  end)
				proximal? = all_memories?(
					percepts,
					:proximity,
					5000,
					fn(value) -> value < 50 end)
				if approaching? and proximal? do
					Percept.new(about: :collision, value: :soon)
				else
					nil
				end
				(%Percept{about: :touch, value: :pressed}, %{percepts: percepts}) ->
					if any_memory?(
								percepts,
								:collision,
								5000,
								fn(value) -> value == :imminent end) do
						Percept.new(about: :collision, value: :now)
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
		(%Percept{about: :collision, value: :now}, %{percepts: percepts}) ->
				if all_memories?(
							percepts,
							:ambient,
							3000,
							fn(value) -> value < 5 end) do
					Percept.new(about: :scared, value: :very)
				else
					Percept.new(about: :scared, value: :a_little)
				end
				(_,_) -> nil
		end
	end

	@doc "Is the robot hungry?"
	def hungry() do
		fn # Hunger based on time since last :eat intend
		(%Percept{about: :time_elapsed}, %{intents: intents}) ->
				elapsed = time_elapsed_since_last(intents, :eat, fn(_value) -> true end)
				case elapsed do
					nil -> Percept.new(about: :hungry, value: :very)
					n when n > 60_000 -> Percept.new(about: :hungry, value: :very)
					n when n > 10_000 -> Percept.new(about: :hungry, value: :a_little)
					_ -> nil
				end
				(_,_) -> nil
		end
	end

end
