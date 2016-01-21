defmodule Ev3.DetectorsHandler do
	@moduledoc "Perceptors handler"

	use GenEvent
	require Logger

  alias Ev3.LegoSensor
  alias Ev3.LegoMotor
	alias Ev3.Detector

  ### Callbacks

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, %{}}
	end

  def handle_event(:faint, state) do
		process_faint()
		{:ok, state}
	end

  def handle_event(:revive, state) do
		process_revive()
		{:ok, state}
	end

  def handle_event(_event, state) do
    #		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end


  ### Private

	defp process_faint() do
		LegoSensor.sensors() ++ LegoMotor.motors()
		|> Enum.each(
			fn(device) ->
				Detector.pause_detection(Detector.name(device))
			end)
	end

	defp process_revive() do
		LegoSensor.sensors() ++ LegoMotor.motors()
		|> Enum.each(
			fn(device) ->
				Detector.resume_detection(Detector.name(device))
			end)
	end

end
