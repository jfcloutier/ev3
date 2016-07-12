defmodule Ev3.Perceptor do
	@moduledoc "An analyzer and producer of percepts"

	alias Ev3.{Memory, CNS, Percept}
	require Logger
  
	@max_percept_age 1000

	@doc "Start a perceptor from a configuration"
	def start_link(perceptor_config) do
		Logger.info("Starting #{__MODULE__} #{perceptor_config.name}")
		Agent.start_link(fn() -> %{perceptor_config: perceptor_config, responsive: true} end,
										 [name: perceptor_config.name])
	end

	@doc "A perceptor analyzes a percept and returns either nil or a new percept"
	def analyze_percept(name, percept) do
		Agent.get_and_update(
			name,
			fn(state) ->
				percept_or_nil = analysis(name, percept, state)
				{percept_or_nil, state}
			end)
	end

    @doc "Stop the production of percepts"
  def pause_perception(name) do
    Logger.info("Pausing perceptor #{name}")
		Agent.update(
			name,
			fn(state) ->
				  %{state | responsive: false}
			end)
  end

  @doc "Resume producing percepts"
	def resume_perception(name) do
    Logger.info("Resuming perceptor #{name}")
		Agent.update(
			name,
			fn(state) ->
				%{state | responsive: true}
			end)
	end

	### Private

	defp analysis(name, percept, %{perceptor_config: config, responsive: responsive}) do
		if responsive and (Percept.sense(percept) in config.focus.senses) and check_freshness(name, percept) do
			memories = Memory.since(config.span,
                              senses: config.focus.senses,
                              motives: config.focus.motives,
                              intents: config.focus.intents)
			config.logic.(percept, memories)  # produces a percept or nil
		else
			nil
		  end
	end

  defp check_freshness(name, percept) do
    age = Percept.age(percept)
    if age > @max_percept_age do
      Logger.info("STALE percept #{inspect percept.about} #{age}")
      CNS.notify_overwhelmed(:perceptor, name)
      false
    else
      true
    end
	end
	
end
