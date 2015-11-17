defmodule Ev3.Detector do
	@moduledoc "A detector polling a sensor or motor for the value of a sense it implements"

	require Logger
	alias Ev3.LegoSensor
	alias Ev3.LegoMotor
  alias Ev3.Percept
	alias Ev3.CNS

	@retain 30000 # detected percept is retained for 30 secs

	@doc "Start a detector for all senses of a device, to be linked to its supervisor"
	def start_link(device) do
		senses = senses(device)
		name = name(device)
		{:ok, pid} = Agent.start_link(
			fn() -> %{device: device} end,
			[name: name])
		Logger.info("#{__MODULE__} started on #{inspect device.type} device")
		pause = pause(device)
	  pid = spawn_link(fn() -> poll(name, senses, pause) end)
		Process.register(pid, String.to_atom("polling #{device.path}"))
		{:ok, pid}
	end

	### Private

	defp senses(device) do
		case device.class do
							 :sensor -> LegoSensor.senses(device)
							 :motor -> LegoMotor.senses(device)
		end
	end

	defp read(device, sense) do
		case device.class do
							 :sensor -> LegoSensor.read(device, sense)
							 :motor -> LegoMotor.read(device, sense)
		end
	end

	defp sensitivity(device, sense) do
		case device.class do
							 :sensor -> LegoSensor.sensitivity(device, sense)
							 :motor -> LegoMotor.sensitivity(device, sense)
		end
	end

	defp pause(device) do
		case device.class do
							 :sensor -> LegoSensor.pause(device)
							 :motor -> LegoMotor.pause(device)
		end
	end

	defp name(device) do
		String.to_atom(device.path)
	end
	
	defp poll(name, senses, pause) do
		Enum.each(senses,
			fn(sense) ->
				detect_change(name, sense)
			end)
		:timer.sleep(pause)
		poll(name, senses, pause)
	end

	defp detect_change(name, sense) do
		Agent.get_and_update(
			name,
			fn(state) ->
				{value, updated_device} = read(state.device, sense)
				if value != nil do
					percept = Percept.new(sense: sense, value: value)
					CNS.notify_perceived(%Percept{percept |
																								 source: name,
																								 retain: @retain,
																								 resolution: sensitivity(updated_device, sense)})
					{:ok, %{state |
									device: updated_device}}
				else
					{:ok, %{state | device: updated_device}}
				end
			end)
		:ok
	end
													 	
end
