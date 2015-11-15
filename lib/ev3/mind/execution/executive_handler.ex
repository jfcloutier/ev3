defmodule Ev3.ExecutiveHandler do

	require Logger
	use GenEvent
	alias Ev3.Executive

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, []}
	end

	def handle_event({:memorized, memorization, percept}, state) do
		Executive.react_to(memorization, percept) 
		{:ok, state}
	end

	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
