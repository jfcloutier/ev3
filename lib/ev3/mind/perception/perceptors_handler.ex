defmodule Ev3.PerceptorsHandler do
	@moduledoc "Perceptors handler"

	use GenEvent
	require Logger

	alias Ev3.{Perceptor, CNS, Perception}

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

  def handle_event(:faint, state) do
		process_faint(state)
		{:ok, state}
	end

  def handle_event(:revive, state) do
		process_revive(state)
		{:ok, state}
	end

	def handle_event(_event, state) do
		{:ok, state} # ignored
	end

	### Private

  defp process_faint(%{perceptor_configs: perceptor_configs}) do
    perceptor_configs
    |> Enum.each(&(Perceptor.pause_perception(&1.name)))
  end

  defp process_revive(%{perceptor_configs: perceptor_configs}) do
    perceptor_configs
    |> Enum.each(&(Perceptor.resume_perception(&1.name)))
  end

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

end
