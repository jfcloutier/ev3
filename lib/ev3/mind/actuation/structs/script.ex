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
		%Ev3.Script{script | steps: script.steps ++ [%{motor_name: motor_name, command: command, params: params}]}
	end

	@doc "Execute the steps and run the motors where applicable"
	def execute(script) do
		updated_motors = Enum.reduce(
			script.steps,
			script.motors,
			fn(step, acc) ->
				motors = case step.motor_name do
									 :all -> Map.values(script.motors)
									 name -> [Map.get(acc, name)]
								 end
				Enum.reduce(
					motors,
					acc,
					fn(motor, acc1) ->
						updated_motor = LegoMotor.execute_command(motor, step.command, step.params)
						Map.put(acc1, step.motor_name, updated_motor)
					end
				)
			end
		)
		%Ev3.Script{script | motors: updated_motors}
	end
	
end
