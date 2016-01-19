defmodule Ev3.InternalClockHandler do
	@moduledoc "Internal clock handler"

	use GenEvent
	require Logger
  alias Ev3.InternalClock

   ### Callbacks

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, %{}}
	end

  def handle_event({:overwhelmed, :actuator, _actuator_name}, state) do
		process_actuator_overwhelmed()
		{:ok, state}
	end

  def handle_event(_event, state) do
    #		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end


  ### Private

	defp process_actuator_overwhelmed() do
		# Logger.info("An actuator is overwhelmed. Idling ticking")
	  InternalClock.actuator_overwhelmed()
	end

end
