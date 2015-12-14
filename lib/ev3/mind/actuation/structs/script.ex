defmodule Ev3.Script do
	@moduledoc "Activation script"

	alias Ev3.LegoMotor
	alias Ev3.LegoLED

	defstruct name: nil, steps: [], devices: nil
	
	@doc "Make a new script"
	def new(name, devices) do
	  %Ev3.Script{name: name, devices: devices}
	end

	@doc "Add a step to the script"
	def add_step(script, device_name, command) do
		add_step(script, device_name, command, [])
	end

	def add_step(script, device_name, command, params) do
		cond do
			device_name == :all or device_name in Map.keys(script.devices) ->
				%Ev3.Script{script | steps: script.steps ++ [%{device_name: device_name, command: command, params: params}]}
			true ->
				throw "Unknown device #{device_name}"
		end
	end

	@doc "Add a timer wait to the script"
	def add_wait(script, msecs) do
		%Ev3.Script{script | steps: script.steps ++ [%{sleep: msecs}]}
	end

	def add_wait(script, device_name, property, test) do
		cond do
			device_name == :all or device_name in Map.keys(script.devices) ->
				%Ev3.Script{script | steps: script.steps ++ [%{wait_on: device_name, property: property, test: test}]}
			true ->
				throw "Unknown device #{device_name}"
		end
	end

	@doc "Execute the steps and waits of the script"
	def execute(actuator_type, script) do
		updated_devices = Enum.reduce(
			script.steps,
			script.devices,
			fn(step, acc) ->
				case step do
					%{device_name: device_name, command: command, params: params} ->
						execute_command(actuator_type, device_name, command, params, acc)
					%{sleep: msecs} ->
						sleep(msecs, acc)
					%{wait_on: device_name, property: property, test: test, timeout: timeout} ->
						wait_on(device_name, property, test, timeout, acc)
				end
			end
		)
		%Ev3.Script{script | devices: updated_devices}
	end

	### Private

	defp execute_command(actuator_type, device_name, command, params, all_devices) do
		devices = case device_name do
								:all -> Map.values(all_devices)
								name -> [Map.get(all_devices, name)]
							end
		Enum.reduce(
			devices,
			all_devices,
			fn(device, acc) ->
				updated_device =
					case actuator_type do
						:motor ->
							LegoMotor.execute_command(device, command, params)
						:led ->
							LegoLED.execute_command(device, command, params)
					end
				Map.put(acc, device_name, updated_device)
			end
		)
	end


	
	defp sleep(msecs, all_devices) do
		IO.puts("SLEEPING for #{msecs}")
		:timer.sleep(msecs)
		all_devices
	end

	defp wait_on(_device_name, _property, _test, _timeout, all_devices) do
		# TODO
    all_devices
	end
				
end
