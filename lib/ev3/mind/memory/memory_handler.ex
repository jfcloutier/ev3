defmodule Ev3.MemoryHandler do
	@moduledoc "The memory of percepts"

	use GenEvent
	require Logger
	alias Ev3.Memory

  ### Callbacks
	
	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, []}
	end

	def handle_event({:perceived, percept}, state) do
		if not percept.transient do
			Memory.store(percept)
		end
		{:ok, state}
	end

	def handle_event({:motivated, motive}, state) do
		Memory.store(motive)
		{:ok, state}
	end

	def handle_event({:intended, intent}, state) do
		Memory.store(intent)
		{:ok, state}
	end

	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
