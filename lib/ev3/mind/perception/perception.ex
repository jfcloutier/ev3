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
					ttl: {10, :secs},
					logic: light()),
				# A collision perceptor based on distance sensing
				PerceptorConfig.new(
					name: :collision,
					focus: %{senses: [:distance, :touch, :collision, :time_elapsed], motives: [], intents: []},
					span: nil, # no windowing
					ttl: {10, :secs}, # remember for 10 seconds
					logic: collision()),
				PerceptorConfig.new(
					name: :danger,
					focus: %{senses: [:ambient, :collision, :danger, :time_elapsed], motives: [], intents: []},
					span: {10, :secs}, # only react to what happened in the last 10 seconds
					ttl: {30, :secs}, # remember for 30 secs
					logic: danger()),
				PerceptorConfig.new(
					name: :hungry,
					focus: %{senses: [:time_elapsed], motives: [], intents: [:eat]},
					span: {1, :mins},
					ttl: {30, :secs},
					logic: hungry()),
				# A food perceptor
				PerceptorConfig.new(
					name: :food,
					focus: %{senses: [:ambient, :color], motives: [], intents: []},
					span: {10, :secs},
					ttl: {30, :secs},
					logic: food()),
				# An odor perceptor
				PerceptorConfig.new(
					name: :scent,
					focus: %{senses: [{:beacon_heading, 1}, {:beacon_distance, 1}], motives: [], intents: []},
					span: {10, :secs},
					ttl: {30, :secs},
					logic: scent()),
				# A stuck perceptor
				PerceptorConfig.new(
					name: :stuck,
					focus: %{senses: [ {:beacon_distance, 1}, :distance], motives: [], intents: [:go_forward, :go_backward]},
					span: {10, :secs},
					ttl: {10, :secs},
					logic: stuck())				
		]
	end

  @doc "Find all senses used for perception"
  def used_senses() do
    perceptor_configs()
    |> Enum.map(&(Map.get(&1.focus, :senses, [])))
    |> List.flatten()
    |> MapSet.new()
    |> MapSet.to_list()
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
		(%Percept{about: :distance, value: n}, %{percepts: percepts}) when n < 10 ->
				if not any_memory?(
							percepts,
							:distance,
							1000,
							fn(value) -> value > 10 end) do
					Percept.new(about: :collision, value: :imminent)
				else
					nil
				end
			(%Percept{about: :distance, value: val}, %{percepts: percepts}) ->
				approaching? = latest_memory?(
					percepts,
					:distance,
					fn(previous) -> val < previous  end)
				proximal? = all_memories?(
					percepts,
					:distance,
					5000,
					fn(value) -> value < 30 end)
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
	fn # Stuck if tried to go forward or backward for the last 5 secs and distances to beacon or obtacle have not changed"
	(%Percept{about: {:beacon_distance, 1}, value: beacon_distance}, %{percepts: percepts, intents: intents}) ->
			forward_attempts = count(
			intents,
			:go_forward,
			5_000,
			fn(_value) -> true end)
			backward_attempts = count(
			intents,
			:go_backward,
			5_000,
			fn(_value) -> true end)
			if (forward_attempts + backward_attempts) > 1 do
				average_beacon_distance = average(
					percepts,
					{:beacon_distance, 1},
					5_000,
					fn(value) -> value end,
					1000
				)
				beacon_distance_change = abs(average_beacon_distance - beacon_distance)
        {low, high} = range(
          percepts,
          :distance,
          5_000,
          fn(value) -> value end,
          {0, 1000}
        )
				if beacon_distance_change < 3 and (high - low) < 3 do
					Percept.new(about: :stuck, value: true)
				else
					Percept.new(about: :stuck, value: false)
				end
			else
				nil
			end
			(_,_) -> nil
		end
	end

	@doc "Where's the bacon?"
	def scent() do
		fn
		(%Percept{about: {:beacon_distance, 1}, value: value}, _memories) ->
				cond do
					value < 0 ->
						Percept.new(about: :scent_strength, value: :unknown)
					value == 100 ->
						Percept.new(about: :scent_strength, value: :very_weak)
					value > 50 ->
						Percept.new(about: :scent_strength, value: :weak)
					value > 10 ->
						Percept.new(about: :scent_strength, value: :strong)
					true ->
						Percept.new(about: :scent_strength, value: :very_strong)
				end
		  (%Percept{about: {:beacon_heading, 1}, value: value}, %{percepts: percepts}) ->
        latest_scent_strength = last_memory(
							percepts,
							:scent_strength)
				cond do
					value < -10 ->
						Percept.new(about: :scent_direction, value: {:left, abs(value), latest_scent_strength})
					value > 10 ->
						Percept.new(about: :scent_direction, value: {:right, abs(value), latest_scent_strength})
					true ->
						Percept.new(about: :scent_direction, value: {:ahead, abs(value), latest_scent_strength})
			  end
	  (_,_) -> nil
	  end
	end

end
