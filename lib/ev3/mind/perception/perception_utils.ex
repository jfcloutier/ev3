defmodule Ev3.PerceptionUtils do
	@moduledoc "Perception utility functions"

	@doc "The time now in msecs"
	def now() do
		{mega, secs, micro} = :os.timestamp()
		((mega * 1_000_000) + secs) * 1000 + div(micro, 1000)
	end

	@doc "Do all percepts from a sense in the past pass a given test?"
	def all_percepts?(percepts, sense, past, test) do
		selection = select_percepts(percepts, sense: sense, since: past)
		Enum.count(selection) > 0 and Enum.all?(selection, fn(percept) -> test.(percept.value) end)
	end
	
  @doc "Select from percepts those from a given sense"
	def select_percepts(percepts, sense: sense) do
		Enum.filter(percepts, &(&1.sense == sense))
	end

  @doc "Select from percepts those from a given sense since a past time"
	def select_percepts(percepts, sense: sense, since: past) do
		msecs = now()
		Enum.filter(percepts, &(&1.sense == sense and (&1.until + past) >= msecs))
	end

	@doc "Is the latest percept from a sense, if any, pass a given test?"
	def latest_percept?(percepts, sense, test) do
		case Enum.find(percepts, &(&1.sense == sense)) do
			nil -> false
			percept -> test.(percept.value)
		end
	end

	@doc "Is there a percept from a sense in the past that passes a given test?"
	def any_percept?(percepts, sense, past, test) do
		select_percepts(percepts, sense: sense, since: past)
		|> Enum.any?(fn(percept) -> test.(percept.value) end)
	end
			
end
