defmodule Ev3.MemoryHandler do
	@docmodule "The memory of percepts"

	use GenEvent
	require Logger
	alias Ev3.Memory

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, []}
	end

	def handle_event({:percept, percept}, state) do
		Memory.store(percept)
		{:ok, state}
	end

	def handle_event(_, state) do
    {:ok, state}
  end


end
