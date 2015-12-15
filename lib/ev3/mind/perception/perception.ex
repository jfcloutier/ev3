defmodule Ev3.Perception do
	@moduledoc "Provides the configurations of all perceptors to be activated"

	import Ev3.MemoryUtils
	require Logger
	alias Ev3.PerceptorConfig
	alias Ev3.Percept

	@doc "Give the configurations of all perceptors to be activated"
	def perceptor_configs() do
		[
				# A getting lighter/darker perceptor
				PerceptorConfig.new(
					name: :light,
					focus: %{senses: [:ambient], motives: [], intents: []},
					span: {10, :secs},
					ttl: {30, :secs},
					logic: light()),
				# A collision perceptor based on proximity sensing
				PerceptorConfig.new(
					name: :collision,
					focus: %{senses: [:proximity, :touch, :collision, :time_elapsed], motives: [], intents: []},
					span: nil, # no windowing
					ttl: {30, :secs}, # remember for 30 seconds
					logic: collision()),
				PerceptorConfig.new(
					name: :danger,
					focus: %{senses: [:ambient, :collision, :danger, :time_elapsed], motives: [], intents: []},
					span: {10, :secs}, # only react to what happened in the last 10 seconds
					ttl: {2, :mins}, # remember for 2 minutes
					logic: danger()),
				PerceptorConfig.new(
					name: :hungry,
					focus: %{senses: [:time_elapsed], motives: [], intents: [:eat]},
					span: {10, :mins},
					ttl: {5, :mins},
					logic: hungry()),
				# A food perceptor
				PerceptorConfig.new(
					name: :food,
					focus: %{senses: [:ambient, :color], motives: [], intents: []},
					span: {30, :secs},
					ttl: {2, :mins},
					logic: food()),
				# A beacon perceptor
				PerceptorConfig.new(
					name: :beacon,
					focus: %{senses: [{:beacon_heading, 1}, {:beacon_distance, 1}], motives: [], intents: []},
					span: {30, :secs},
					ttl: {1, :mins},
					logic: beacon()),
				# A stuck perceptor
				PerceptorConfig.new(
					name: :stuck,
					focus: %{senses: [ {:beacon_distance, 1}], motives: [], intents: [:go_forward]},
					span: {30, :secs},
					ttl: {1, :mins},
					logic: stuck())				
		]
	end

	### Private

	def darker() do
		fn
		(_percept, %{percepts: []}) -> nil
		(%Percept{about: :ambient, value: val}, %{percepts: percepts}) ->
				if latest_memory?(
							percepts,
							:ambient,
							fn(value) -> value < val end) do
					Percept.new(about: :darker, value: val)
				else
					nil	  
				end
		end
	end

	def light() do
		fn
		(_percept, %{percepts: []}) -> nil
		(%Percept{about: :ambient, value: val}, %{percepts: percepts}) ->
				latest_ambient = last_memory(
							percepts,
							:ambient)
				cond do
					latest_ambient == nil -> 
						Percept.new(about: :light, value: :same)	  
					latest_ambient.value > val -> 
						Percept.new(about: :light, value: :lighter)	  
					latest_ambient.value < val -> 
						Percept.new(about: :light, value: :darker)	  
					true -> 
						Percept.new(about: :light, value: :same)	  
				end
		end
	end

	def food() do
		fn						 
		(_percept, %{percepts: []}) -> nil
			(%Percept{about: :color, value: :blue}, %{percepts: percepts}) ->
			if latest_memory?(
						percepts,
						:ambient,
						fn(value) -> value > 20  end) do
				IO.puts "!!!! FOOD a plenty !!!!"
			  Percept.new(about: :food, value: :plenty)
			else
				IO.puts "!!!! FOOD a little !!!!"
				Percept.new(about: :food, value: :little)
			end
			(%Percept{about: :color, value: _color}, _memories) ->
			Percept.new(about: :food, value: :none)
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
			(%Percept{about: :touch, value: :pressed}, _memories) ->
					Percept.new(about: :collision, value: :now)
			(_, _) -> nil
		end
	end

	@doc "Danger, Will Robinson!"
	def danger() do
		fn
		(_percept, []) -> nil
		(%Percept{about: :collision, value: :now}, %{percepts: percepts}) ->
				if all_memories?(
							percepts,
							:ambient,
							2000,
							fn(value) -> value < 10 end) do
					Percept.new(about: :danger, value: :high)
				else
					Percept.new(about: :danger, value: :low)
				end
		(%Percept{about: :time_elapsed}, %{percepts: percepts}) ->
				if not any_memory?(
							percepts,
							:danger,
							3000,
							fn(value) -> value in [:high] end) do
					Percept.new(about: :danger, value: :none)
				else
					nil
				end
		(_,_) -> nil
		end
	end

	@doc "Is the robot hungry?"
	def hungry() do
		fn # Hunger based on time since last :eat intend
		(%Percept{about: :time_elapsed}, %{intents: intents}) ->
				how_full = summation(
				intents,
				:eat,
				30_000,
				fn(value) ->
					case value do
						:lots -> 5
						:some -> 3
					end
				end,
				0
			) # How much did I eat in the last 30 secs?
				cond do
					how_full > 10 -> Percept.new(about: :hungry, value: :not)
					how_full > 5 -> Percept.new(about: :hungry, value: :a_little)
					true -> Percept.new(about: :hungry, value: :very)
				end
			(_,_) -> nil
		end
	end

	@doc "Is the robot stuck?"
	def stuck() do 
	fn # Stuck if tried to go forward for a while and distance has not changed"
	(%Percept{about: {:beacon_distance, 1}, value: distance}, %{percepts: percepts, intents: intents}) ->
			attempts = count(
			intents,
			:go_forward,
			15_000,
			fn(_value) -> true end)
			if attempts > 3 do
				average_distance = average(
					percepts,
					{:beacon_distance, 1},
					15_000,
					fn(value) -> value end,
					1000
				)
				change = abs(average_distance - distance)
				if change < 2 do
					Percept.new(about: :stuck, value: true)
				else
					nil
				end
			else
				nil
			end
			(_,_) -> nil
		end
	end

	@doc "Where's the beacons?"
	def beacon() do
		fn
		(%Percept{about: {:beacon_distance, 1}, value: value}, _memories) ->
				cond do
					value < 0 ->
						Percept.new(about: :distance, value: :unknown)
					value == 100 ->
						Percept.new(about: :distance, value: :very_far)
					value > 50 ->
						Percept.new(about: :distance, value: :far)
					value > 10 ->
						Percept.new(about: :distance, value: :close)
					true ->
						Percept.new(about: :distance, value: :very_close)
				end
		(%Percept{about: {:beacon_heading, 1}, value: value}, _memories) ->
				cond do
					value < -10 ->
						Percept.new(about: :direction, value: {:left, abs(value)})
					value > 10 ->
						Percept.new(about: :direction, value: {:right, abs(value)})
					true ->
						Percept.new(about: :direction, value: {:ahead, abs(value)})
			  end
	  (_,_) -> nil
	  end
	end

end
