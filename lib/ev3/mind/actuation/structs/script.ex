defmodule Ev3.Script do
	@moduledoc "Activation script"

	alias Ev3.LegoMotor

	defstruct name: nil, steps: [], motors: nil
	
	@doc "Make a new script"
	def new(name, motors) do
	  %Ev3.Script{name: name, motors: motors}
	end

	@doc "Add a step to the script"
	def add_step(script, motor_name, command) do
		add_step(script, motor_name, command, [])
	end

	def add_step(script, motor_name, command, params) do
		cond do
			motor_name == :all or motor_name in Map.keys(script.motors) ->
				%Ev3.Script{script | steps: script.steps ++ [%{motor_name: motor_name, command: command, params: params}]}
			true ->
				throw "Unknown motor #{motor_name}"
		end
	end

	@doc "Add a timer wait to the script"
	def add_wait(script, msecs) do
		%Ev3.Script{script | steps: script.steps ++ [%{sleep: msecs}]}
	end

	def add_wait(script, motor_name, property, test) do
		cond do
			motor_name == :all or motor_name in Map.keys(script.motors) ->
				%Ev3.Script{script | steps: script.steps ++ [%{wait_on: motor_name, property: property, test: test}]}
			true ->
				throw "Unknown motor #{motor_name}"
		end
	end

	@doc "Execute the steps and waits of the script"
	def execute(script) do
		updated_motors = Enum.reduce(
			script.steps,
			script.motors,
			fn(step, acc) ->
				case step do
					%{motor_name: motor_name, command: command, params: params} ->
						execute_command(motor_name, command, params, acc)
					%{sleep: msecs} ->
						sleep(msecs, acc)
					%{wait_on: motor_name, property: property, test: test, timeout: timeout} ->
						wait_on(motor_name, property, test, timeout, acc)
				end
			end
		)
		%Ev3.Script{script | motors: updated_motors}
	end

	### Private

	defp execute_command(motor_name, command, params, all_motors) do
		motors = case motor_name do
							 :all -> Map.values(all_motors)
							 name -> [Map.get(all_motors, name)]
						 end
		Enum.reduce(
			motors,
			all_motors,
			fn(motor, acc) ->
				updated_motor = LegoMotor.execute_command(motor, command, params)
				Map.put(acc, motor_name, updated_motor)
			end
		)
	end

	defp sleep(msecs, all_motors) do
		IO.puts("SLEEPING for #{msecs}")
		:timer.sleep(msecs)
		all_motors
	end

	defp wait_on(motor_name, property, test, timeout, all_motors) do
		# TODO
    all_motors
	end
		
			
end
