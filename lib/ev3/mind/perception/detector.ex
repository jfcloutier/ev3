defmodule Ev3.Detector do
	@docmodule "A detector polling a sensor for the value of a sense it implements"

	require Logger
	alias Ev3.LegoSensor
  alias Ev3.Percept
	alias Ev3.EventManager

	@retain 30000 # detected percept is retained for 30 secs

	@doc "Start a detector for all senses of a sensor, to be linked to its supervisor"
	def start_link(sensor) do
		senses = LegoSensor.senses(sensor)
		name = name(sensor)
		{:ok, pid} = Agent.start_link(
			fn() -> %{sensor: sensor} end,
			[name: name])
		Logger.info("#{__MODULE__} started on #{inspect sensor.type} sensor")
		pause = LegoSensor.pause(sensor)
	  spawn_link(fn() -> poll(name, senses, pause) end)
		{:ok, pid}
	end

	### Private

	defp name(sensor) do
		String.to_atom(sensor.path)
	end
	
	defp poll(name, senses, pause) do
		Enum.each(senses,
			fn(sense) ->
				detect_change(name, sense)
				:timer.sleep(pause)
			end)
		poll(name, senses, pause)
	end

	defp detect_change(name, sense) do
		Agent.get_and_update(
			name,
			fn(state) ->
				{value, updated_sensor} = LegoSensor.read(state.sensor, sense)
				if value != nil do
					percept = Percept.new(sense: sense, value: value)
					EventManager.notify_perceived(%Percept{percept |
																								 source: name,
																								 retain: @retain,
																								 resolution: LegoSensor.sensitivity(updated_sensor)})
					{:ok, %{state |
									sensor: updated_sensor}}
				else
					{:ok, %{state | sensor: updated_sensor}}
				end
			end)
		:ok
	end
													 	
end
