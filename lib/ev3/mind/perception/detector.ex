defmodule Ev3.Detector do
	@moduledoc "A detector polling a sensor or motor for the value of a sense it implements"

	require Logger
	alias Ev3.LegoSensor
	alias Ev3.LegoMotor
  alias Ev3.Percept
	alias Ev3.CNS
  alias Ev3.Device

	@ttl 10_000 # detected percept is retained for 10 secs

	@doc "Start a detector for all senses of a device, to be linked to its supervisor"
	def start_link(device, used_senses) do
		senses = senses(device, used_senses)
		name = name(device)
		{:ok, pid} = Agent.start_link(
			fn() ->
				poll_pid = spawn_link(fn() -> poll(name, senses, pause(device)) end)
				Process.register(poll_pid, String.to_atom("polling #{device.path}"))
				%{device: device, responsive: true, previous_values: %{}}
			end,
			[name: name])
		Logger.info("#{__MODULE__} started on #{inspect device.type} device")
		{:ok, pid}
	end

  @doc "Stop the detection of percepts"
  def pause_detection(name) do
    Logger.info("Pausing detector #{name}")
		Agent.update(
			name,
			fn(state) ->
				  %{state | responsive: false}
			end)
  end

  @doc "Resume producing percepts"
	def resume_detection(name) do
    Logger.info("Resuming detector #{name}")
		Agent.update(
			name,
			fn(state) ->
				%{state | responsive: true}
			end)
	end

  @doc "Detector's name from the device"
	def name(device) do
		String.to_atom(device.path)
	end
												 	
	### Private

	defp senses(device, used_senses) do
		device_senses = case device.class do
							        :sensor -> LegoSensor.senses(device)
							        :motor -> LegoMotor.senses(device)
		                end
    Enum.filter(device_senses, &(unqualified_sense(&1) in used_senses))
	end

	defp unqualified_sense(full_sense) do
		case full_sense do
			{sense, _qualifier} -> sense
			sense when is_atom(sense) -> sense
		end
	end

	defp read(device, sense) do
		case device.class do
			:sensor -> LegoSensor.read(device, sense)
			:motor -> LegoMotor.read(device, sense)
		end
	end

  defp nudge(%Device{mock: true} = mock_device, sense, value, previous_value) do
    case mock_device.class do
      :sensor -> LegoSensor.nudge(mock_device, sense, value, previous_value)
      :motor -> LegoMotor.nudge(mock_device, sense, value, previous_value)
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
        if state.responsive do
				  {value, updated_device} = read(state.device, sense)
				  if value != nil do
					  percept = if updated_device.mock do
                        previous_value = Map.get(state.previous_values, sense, nil)
                        mocked_value = nudge(updated_device, sense, value, previous_value)
                        Percept.new(about: sense, value: mocked_value)
                      else
                        Percept.new(about: sense, value: value)
                      end
            %Percept{percept |
										 source: name,
										 ttl: @ttl,
										 resolution: sensitivity(updated_device, sense)}
					  |> CNS.notify_perceived()
					  {:ok, %{state |
									  device: updated_device,
                    previous_values: Map.put(state.previous_values, sense, percept.value)}}
				  else
					  {:ok, %{state | device: updated_device}}
				  end
        else
          {:ok, state}
        end
			end)
		:ok
	end

end
