defmodule Ev3.PerceptorsHandler do
	@moduledoc "Perceptors handler"

	use GenEvent
	require Logger

	alias Ev3.Perceptor
	alias Ev3.CNS
	alias Ev3.Perception

	### Callbacks

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		perceptor_configs = Perception.perceptor_configs()
		{:ok, %{perceptor_configs: perceptor_configs}}
	end

	def handle_event({:perceived, percept}, state) do
		process_percept(percept, state)
		{:ok, state}
	end

	def handle_event({:overwhelmed, :actuator, name}, state) do
		process_actuator_overwhelmed(name, state)
		{:ok, state}
	end


	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

	### Private

	defp process_percept(percept, %{perceptor_configs: perceptor_configs}) do
		perceptor_configs
		|> Enum.filter(&(percept.about in &1.focus.senses))
		|> Enum.each(
			fn(perceptor_config) ->
				Process.spawn( # allow parallelism
					fn() ->
						case Perceptor.analyze_percept(perceptor_config.name, percept) do
							nil -> :ok
							new_percept ->
								CNS.notify_perceived(%{new_percept |
																			 ttl: perceptor_config.ttl,
																			 source: perceptor_config.name} )
						end
					end,
					[:link])
			end)
	end

	defp process_actuator_overwhelmed(actuator_name, %{perceptor_configs: perceptor_configs}) do
		Logger.info("Actuator #{actuator_name} is overwhelmed. Idling perception")
		perceptor_configs
		|> Enum.each(
			fn(perceptor_config) ->
				Perceptor.actuator_overwhelmed(perceptor_config.name)
			end)
	end


end
