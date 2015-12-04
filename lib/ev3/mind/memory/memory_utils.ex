defmodule Ev3.MemoryUtils do
	@moduledoc "Memory utility functions"

	import Ev3.Utils
	alias Ev3.Percept
	alias Ev3.Motive
	alias Ev3.Intent

	@doc "Do all memories in a recent past pass a given test?"
	def all_memories?(memories, about, past, test) do
		selection = select_memories(memories, about: about, since: past)
		Enum.count(selection) > 0 and Enum.all?(selection, fn(memory) -> test.(memory.value) end)
	end
	
  @doc "Select from memories those about something"
	def select_memories(memories, about: about) do
		Enum.filter(memories, &(&1.about == about))
	end

  @doc "Select from memories those about something since a past time"
	def select_memories(memories, about: about, since: past) do
		msecs = now()
		Enum.filter(memories, &(&1.about == about and (when_last_true(&1) + past) >= msecs))
	end

	@doc "Is the latest memory about something, if any, pass a given test?"
	def latest_memory?(memories, about, test) do
		case Enum.find(memories, &(&1.about == about)) do
			nil -> false
			memory -> test.(memory.value)
		end
	end

	@doc "Is there a memory about something in the past that passes a given test?"
	def any_memory?(memories, about, past, test) do
		select_memories(memories, about: about, since: past)
		|> Enum.any?(fn(memory) -> test.(memory.value) end)
	end

	@doc "The time elasped since the last remembered memory about something that passes the test. Return msecs or nil if none"
	def time_elapsed_since_last(memories, about, test) do
		candidates = select_memories(memories, about: about)
		case Enum.find(candidates, fn(memory) -> test.(memory.value) end) do
			nil -> nil
			memory -> now() - when_last_true(memory)
		end
	end

	def when_last_true(%Percept{until: until}) do
		until
	end

	def when_last_true(%Motive{since: since}) do
		since
	end
	
	def when_last_true(%Intent{since: since}) do
		since
	end
			
end
