defmodule Ev3.MemoryHandler do
	@docmodule "The memory of percepts"

	use GenEvent
	require Logger
	alias Ev3.Memory

  ### Callbacks
	
	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, []}
	end

	def handle_event({:perceived, percept}, state) do
		Memory.store(percept)
		{:ok, state}
	end

	def handle_event(event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
