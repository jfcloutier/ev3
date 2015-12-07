defmodule Ev3.Actuation do
	@moduledoc "Provides the configurations of all actuators to be activated"

	require Logger

	alias Ev3.ActuatorConfig
	alias Ev3.MotorSpec
	alias Ev3.Activation
	alias Ev3.Script
	
	@doc "Give the configurations of all actuators to be activated"
  def actuator_configs() do
		[
				ActuatorConfig.new(name: :locomotion,
													 motor_specs: [  # to find and name motors from specs
														 %MotorSpec{name: :left_wheel, port: "A"},
														 %MotorSpec{name: :right, port: "B"}
													 ],
													 activations: [ # scripted actions to be taken upon receiving intents
														 %Activation{intent: :go_forward,
																				 action: going_forward()},
														 %Activation{intent: :go_backward,
																				 action: going_backward()},
														 %Activation{intent: :turn_right,
																				 action: turning_right()},
														 %Activation{intent: :turn_left,
																				 action: turning_left()},
														 %Activation{intent: :stop,
																				 action: stopping()}
													 ]),
				ActuatorConfig.new(name: :manipulation,
													 motor_specs: [ # todo
													 ],
													 activations: [ # todo
													 ])														 
		]
	end

	def going_forward() do
		fn(intent, motors) ->
			rps_speed = case intent.value.speed do
										:fast -> 3
										:slow -> 1
									end
			how_long = intent.value.time * 1000
			Script.new(:going_forward, motors)
			|> Script.add_step(:all, :set_speed, [:rps, rps_speed])
			|> Script.add_step(:all, :run_for, [how_long] )
			|> Script.add_wait(how_long)
		end
	end

	def going_backward() do
		fn(intent, motors) ->
			rps_speed = case intent.value.speed do
										:fast -> 3
										:slow -> 1
									end
			how_long = intent.value.time * 1000
			Script.new(:going_backward, motors)
			|> Script.add_step(:all, :reset)
			|> Script.add_step(:all, :reverse_polarity)
			|> Script.add_step(:all, :set_speed, [:rps, rps_speed])
			|> Script.add_step(:all, :run_for, [how_long])
			|> Script.add_step(:all, :reverse_polarity)
		end
	end

	def turning_right() do
		fn(intent, motors) ->
			IO.puts("UNDEFINED :turning_right")
			Script.new(:turning_right, motors)
		end
		# todo
  end

	def turning_left() do
		fn(intent, motors) ->
			IO.puts("UNDEFINED :turning_left")
			Script.new(:turning_left, motors)
		end
		# todo
  end

	def stopping() do
		fn(intent, motors) ->
			IO.puts("UNDEFINED :stop")
			Script.new(:stopping, motors)
		end
		# todo
  end
	
end
