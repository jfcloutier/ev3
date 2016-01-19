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
		# Logger.info("Actuator #{actuator_name} is overwhelmed. Idling detection")
		LegoSensor.sensors() ++ LegoMotor.motors()
		|> Enum.each(
			fn(device) ->
				Detector.actuator_overwhelmed(Detector.name(device))
			end)
	end

end
