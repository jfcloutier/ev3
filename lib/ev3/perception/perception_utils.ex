defmodule Ev3.PerceptionUtils do

	def now() do
		Timex.Time.now() |> Timex.Time.to_msecs()
	end

	def all_percepts_since?(percepts, sense, window, test) do
		select_percepts(percepts, sense: sense, window: window)
		|> Enum.all?(fn(percept) -> test.(percept) end)
	end
	

	def select_percepts(percepts, sense: sense) do
		Enum.filter(percepts, &(&1.sense == sense))
	end

	def select_percepts(percepts, sense: sense, window: window) do
		msecs = now()
		Enum.filter(percepts, &(&1.sense == sense and (&1.until + window) >= msecs))
	end

	def latest_percept?(percepts, sense, test) do
		case Enum.find(percepts, &(&1.sense == sense)) do
			nil -> false
			percept -> test.(percept)
		end
	end
			
end
