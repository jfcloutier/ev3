defmodule Ev3.BehaviorsHandler do
  @moduledoc "The motivators event handler"
	
	require Logger
	use GenEvent
	alias Ev3.Behavior
	alias Ev3.Behaviors

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		behavior_configs = Behaviors.behavior_configs()
		{:ok, %{behavior_configs: behavior_configs}}
	end

	def handle_event({:perceived, percept}, state) do
		process_percept(percept, state)
		{:ok, state}
	end

	def handle_event({:motivated, motive}, state) do
		process_motive(motive, state)
		{:ok, state}
	end

	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

  ### Private

	defp process_percept(percept, %{behavior_configs: behavior_configs}) do # Can stimulate started behaviors
		behavior_configs
		|> Enum.filter(&(percept.about in &1.senses))
		|> Enum.each(
			fn(behavior_config) ->
				Process.spawn( # allow parallelism
					fn() ->
						Behavior.react_to_percept(behavior_config.name, percept)
					end,
					[:link])
			end)
	end

	defp process_motive(motive, %{behavior_configs: behavior_configs}) do # Can stop or start behaviors
		behavior_configs
		|> Enum.filter(&(motive.about in &1.motivated_by))
		|> Enum.each(
			fn(behavior_config) ->
				Behavior.react_to_motive(behavior_config.name, motive)
			end)
	end

end
