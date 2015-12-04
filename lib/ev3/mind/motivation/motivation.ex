defmodule Ev3.Motivation do
	@moduledoc "Provides the configurations of all motivators to be activated"

	require Logger

	alias Ev3.MotivatorConfig
	alias Ev3.Motive
	alias Ev3.Percept
	import Ev3.MemoryUtils
	
	@doc "Give the configurations of all motivators to be activated"
  def motivator_configs() do
		[
				# A curiosity motivator
				MotivatorConfig.new(
					name: :curiosity_motivator,
					focus: %{senses: [:time_elapsed], motives: [], intents: []},
					span: nil,
					logic: curiosity()
				),
				# A hunger motivator
				MotivatorConfig.new(
					name: :feeding_motivator,
					focus: %{senses: [:hungry, :sated], motives: [], intents: []},
					span: nil, # for as long as we can remember
					logic: hunger(),
				),
				# A panic motivator
				MotivatorConfig.new(
					name: :panic_motivator,
					focus: %{senses: [:scared], motives: [], intents: []},
					span: nil, # for as long as we can remember
					logic: panic()
				)
		]
	end

	@doc "Curiosity motivation"
	def curiosity() do
		fn
		(%Percept{about: :time_elapsed}, _) ->
				Motive.on(:curiosity)
		end
	end
	
	@doc "Feeding motivation"
	def hunger() do
		fn
		(%Percept{about: :hungry, value: :very}, %{percepts: percepts }) ->
				if not any_memory?(
							percepts,
							:scared,
							5_000,
							fn(value) -> value == :very end) do
					Motive.on(:hunger) |> Motive.inhibit(:curiosity)
				else
					nil
				end
	  (%Percept{about: :hungry, value: :not}, __) ->
				Motive.off(:hunger)
	  (_,_) ->
				nil
		end
	end

	@doc "Panic motivation"
	def panic() do
		fn
		(%Percept{about: :scared, value: :very}, _) ->
				Motive.on(:panic) |> Motive.inhibit_all()
		(%Percept{about: :scared, value: :not}, _) ->
				Motive.off(:panic)
		(_,_) ->
				nil
		end
	end
	
end
