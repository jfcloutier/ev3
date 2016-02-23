defmodule Ev3.Motivation do
	@moduledoc "Provides the configurations of all motivators to be activated"

	require Logger

	alias Ev3.{MotivatorConfig, Motive, Percept}
	import Ev3.MemoryUtils
	
	@doc "Give the configurations of all motivators. Motivators turn motives on and off"
  def motivator_configs() do
		[
				# A curiosity motivator
				MotivatorConfig.new(
					name: :curiosity,
					focus: %{senses: [:time_elapsed], motives: [], intents: []},
					span: nil,
					logic: curiosity()
				),
				# A hunger motivator
				MotivatorConfig.new(
					name: :hunger,
					focus: %{senses: [:hungry], motives: [], intents: []},
					span: nil, # for as long as we can remember
					logic: hunger(),
				),
				# A fear motivator
				MotivatorConfig.new(
					name: :fear,
					focus: %{senses: [:danger], motives: [], intents: []},
					span: nil, # for as long as we can remember
					logic: fear()
				)
		]
	end

  @doc "Find all senses used for motivation"
  def used_senses() do
    motivator_configs()
    |> Enum.map(&(Map.get(&1.focus, :senses, [])))
    |> List.flatten()
    |> MapSet.new()
    |> MapSet.to_list()
  end


	@doc "Curiosity motivation"
	def curiosity() do
		fn
		(%Percept{about: :time_elapsed}, _) ->
				Motive.on(:curiosity) # never turned off
		end
	end
	
	@doc "Hunger motivation"
	def hunger() do
		fn
		(%Percept{about: :hungry, value: :very}, %{percepts: percepts }) ->
				if not any_memory?(
							percepts,
							:danger,
							5_000,
							fn(_value) -> true end) do
					Motive.on(:hunger) |> Motive.inhibit(:curiosity)
				else
					nil
				end
	  (%Percept{about: :hungry, value: :not}, _) ->
				Motive.off(:hunger)
	  (_,_) ->
				nil
		end
	end

	@doc "Fear motivation"
	def fear() do
		fn
		(%Percept{about: :danger, value: :high}, _) ->
				Motive.on(:fear) |> Motive.inhibit_all()
		(%Percept{about: :danger, value: :none}, _) ->
				Motive.off(:fear)
		(_,_) ->
				nil
		end
	end
	
end
