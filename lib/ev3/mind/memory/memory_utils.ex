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

	@doc "Count applicable memories"
	def count(memories, about, past, test) do
		select_memories(memories, about: about, since: past)
		|> Enum.filter(&(test.(&1.value)))
		|> Enum.count()
	end								 

	@doc "Is the latest memory about something, if any, pass a given test?"
	def latest_memory?(memories, about, test) do
		case Enum.find(memories, &(&1.about == about)) do
			nil -> false
			memory -> test.(memory.value)
		end
	end

	@doc "Find the last memory about something"
	def last_memory(memories, about) do 
	   Enum.find(memories, &(&1.about == about))
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

	@doc "Get the average value for selected memories"
	def average(memories, about, past, valuation, default \\ nil) do
		list = select_memories(memories, about: about, since: past)
		case sum(list, valuation, default) do
			nil -> nil
			n -> n / Enum.count(list)
		end
	end

  @doc "Get the numerical range of values for selected memories, or default if none"
  def range(memories, about, past, valuation, default) do
    list = select_memories(memories, about: about, since: past)
    if Enum.count(list) == 0 do
      default
    else
      Enum.reduce(
        list,
        {+10_000_000, -10_000_000},
        fn(memory, {low, high}) ->
          n = valuation.(memory.value)
          {min(n, low), max(n, high)}
        end
      )
    end
  end

	@doc "Summation over selected memories"
	def summation(memories, about, past, valuation, default \\ nil) do
		select_memories(memories, about: about, since: past)
		|> sum(valuation, default)
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

	### Private

	defp sum([], _valuation, default) do
		default
	end

	defp sum([memory | rest], valuation, _default) do
		Enum.reduce(
			rest,
			valuation.(memory.value),
			fn(other, acc) ->
				value = valuation.(other.value)
				acc + value
			end)
	end


			
end
