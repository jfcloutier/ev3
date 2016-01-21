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

  def handle_event(:faint, state) do
		InternalClock.pause()
		{:ok, state}
	end

  def handle_event(:revive, state) do
		InternalClock.resume()
		{:ok, state}
	end

  def handle_event(_event, state) do
    #		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
