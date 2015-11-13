defmodule Ev3.Detector do

	require Logger
	alias Ev3.LegoSensor
  alias Ev3.Percept
	
	def start_link(sensor, sense) do
		{:ok, pid} = Agent.start_link(fn() -> %{sensor: sensor, sense: sense, last_value: nil} end, [name: name(sensor, sense)])
		Logger.debug("DETECTOR PID = #{inspect pid}")
	  spawn_link(fn() -> detect(sensor, sense) end)
		{:ok, pid}
	end


	### Private

	defp name(sensor, sense) do
		String.to_atom("#{sensor.path}[#{inspect sense}]")
	end
	
	defp detect(sensor, sense) do
		:timer.sleep(LegoSensor.pause(sensor))
		sense(sensor, sense)
		detect(sensor, sense)
	end

	defp sense(sensor, sense) do
		value = LegoSensor.read(sensor, sense)
		name = name(sensor, sense)
		if value != nil do
			Agent.get_and_update(
				name,
				fn(state) ->
					if state.last_value == nil or state.last_value != value do
						percept = Percept.new(sense: sense, value: value)
						EventManager.notify_percept(%Percept{percept | source: name})
						{value, %{state | last_value: value}}
					else
						{value, state}
					end
				end)
		end
		:ok
	end
													 
	
end
