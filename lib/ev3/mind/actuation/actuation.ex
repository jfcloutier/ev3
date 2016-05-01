defmodule Ev3.Actuation do
	@moduledoc "Provides the configurations of all actuators to be activated"

	require Logger

	alias Ev3.ActuatorConfig
	alias Ev3.MotorSpec
	alias Ev3.LEDSpec
  alias Ev3.SoundSpec
	alias Ev3.CommSpec
	alias Ev3.Activation
	alias Ev3.Script
	
	@doc "Give the configurations of all actuators to be activated"
  def actuator_configs() do
		[
			ActuatorConfig.new(name: :locomotion,
												 type: :motor,
												 specs: [  # to find and name motors from specs
													 %MotorSpec{name: :left_wheel, port: "outA"},
													 %MotorSpec{name: :right_wheel, port: "outB"}
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
												 type: :motor,
												 specs: [
													 %MotorSpec{name: :mouth, port: "outC"}
												 ],
												 activations: [
													 %Activation{intent: :eat,
																			 action: eating()}
												 ]),
			ActuatorConfig.new(name: :leds,
												 type: :led,
												 specs: [
													 %LEDSpec{name: :lr, position: :left, color: :red}, #ev3
													 %LEDSpec{name: :lg, position: :left, color: :green}, #ev3
													 %LEDSpec{name: :lb, position: :left, color: :blue}, #brickpi
													 %LEDSpec{name: :rr, position: :right, color: :red}, #ev3
													 %LEDSpec{name: :rg, position: :right, color: :green}, #ev3
													 %LEDSpec{name: :rb, position: :right, color: :blue} #brickpi
												 ],
												 activations: [
													 %Activation{intent: :green_lights,
																			 action: green_lights()},
													 %Activation{intent: :red_lights,
																			 action: red_lights()},
													 %Activation{intent: :orange_lights,
																			 action: orange_lights()}
												 ]),
      ActuatorConfig.new(name: :sounds,
                         type: :sound,
                         specs: [
                           %SoundSpec{name: :loud_speech, type: :speech, props: %{volume: :loud, speed: :normal, voice: "en-sc"}}
                         ],
                         activations: [
                           %Activation{intent: :say_hungry,
                                       action: say_hungry()},
                           %Activation{intent: :say_scared,
                                       action: say_scared()},
                           %Activation{intent: :say_curious,
                                       action: say_curious()},
                           %Activation{intent: :say_uh_oh,
                                       action: say_uh_oh()},
                           %Activation{intent: :say_stuck,
                                       action: say_stuck()},
                           %Activation{intent: :say_food,
                                       action: say_food()},
                           %Activation{intent: :eating_noises,
                                       action: eating_noises()},
                           %Activation{intent: :say,
                                       action: say()}
                         ]),
      ActuatorConfig.new(name: :communicators,
												 type: :comm,
												 specs: [
													 %CommSpec{name: :marvins, type: :pg2} # could set props.ttl to something other than 30 secs default
												 ],
												 activations: [
													 %Activation{intent: :communicate, # intent value = %{info: info, team: team}
																			 action: communicate()}
												 ])													 
		]
	end

	# locomotion

	defp going_forward() do
		fn(intent, motors) ->
			rps_speed = speed(intent.value.speed)
			how_long = round(intent.value.time * 1000)
			Script.new(:going_forward, motors)
			|> Script.add_step(:right_wheel, :set_speed, [:rps, rps_speed])
			|> Script.add_step(:left_wheel, :set_speed, [:rps, rps_speed])
			|> Script.add_step(:all, :run_for, [how_long] )
			#			|> Script.add_wait(how_long)
		end
	end

	defp speed(kind) do
		case kind do
			:very_fast -> 3
			:fast -> 2
      :normal -> 1
			:slow -> 0.5
			:very_slow -> 0.3
		end
	end

	defp going_backward() do
		fn(intent, motors) ->
			rps_speed = speed(intent.value.speed)
			how_long = round(intent.value.time * 1000)
			Script.new(:going_backward, motors)
			|> Script.add_step(:right_wheel, :set_speed, [:rps, rps_speed * -1])
			|> Script.add_step(:left_wheel, :set_speed, [:rps, rps_speed * -1])
			|> Script.add_step(:all, :run_for, [how_long])
		end
	end

	defp turning_right() do
		fn(intent, motors) ->
			how_long = round(intent.value * 1000)
			Script.new(:turning_right, motors)
			|> Script.add_step(:left_wheel, :set_speed, [:rps, 0.5])
			|> Script.add_step(:right_wheel, :set_speed, [:rps, -0.5])
			|> Script.add_step(:all, :run_for, [how_long])
		end
  end

	defp turning_left() do
		fn(intent, motors) ->
			how_long = round(intent.value * 1000)
			Script.new(:turning_left, motors)
			|> Script.add_step(:right_wheel, :set_speed, [:rps, 0.5])
			|> Script.add_step(:left_wheel, :set_speed, [:rps, -0.5])
			|> Script.add_step(:all, :run_for, [how_long])
		end
  end

	defp stopping() do
		fn(_intent, motors) ->
			Script.new(:stopping, motors)
			|> Script.add_step(:all, :coast)
			|> Script.add_step(:all, :reset)
		end
  end

	# manipulation

	defp eating() do
		fn(_intent, motors) ->
			Script.new(:eating, motors)
			|> Script.add_step(:mouth, :set_speed, [:rps, 1])
			|> Script.add_step(:mouth, :run_for, [1000])
		end
	end

	# light

  defp blue_lights() do
    if Ev3.platform != :brickpi do
      Logger.warn("Blue LEDs only on BrickPi. Using green instead.")
      green_lights()
    else
      fn(intent, leds) ->
        value = case intent.value do
                  :on -> 255
                  :off -> 0
                end
			  Script.new(:blue_lights, leds)
			  |> Script.add_step(:lb, :set_brightness, [value])
			  |> Script.add_step(:rb, :set_brightness, [value])
      end
    end
  end
  
	defp green_lights() do
    if Ev3.platform == :brickpi do
      Logger.warn("No green LEDs on BrickPi. Using blue instead.")
      blue_lights()
    else
		  fn(intent, leds) ->
			  value = case intent.value do
								  :on -> 255
								  :off -> 0
							  end
			  Script.new(:green_lights, leds)
			  |> Script.add_step(:lr, :set_brightness, [0])
			  |> Script.add_step(:rr, :set_brightness, [0])
			  |> Script.add_step(:lg, :set_brightness, [value])
			  |> Script.add_step(:rg, :set_brightness, [value])
		  end
    end
	end
	
	defp red_lights() do
    if Ev3.platform == :brickpi do
      Logger.warn("No red LEDs on BrickPi. Using blue instead.")
      blue_lights()
    else
		  fn(intent, leds) ->
			  value = case intent.value do
								  :on -> 255
								  :off -> 0
							  end
			  Script.new(:red_lights, leds)
			  |> Script.add_step(:lg, :set_brightness, [0])
			  |> Script.add_step(:rg, :set_brightness, [0])
			  |> Script.add_step(:lr, :set_brightness, [value])
			  |> Script.add_step(:rr, :set_brightness, [value])
		  end
    end
	end
	
	defp orange_lights() do
    if Ev3.platform == :brickpi do
      Logger.warn("No orange (green + red) LEDs on BrickPi. Using blue instead.")
      blue_lights()
    else
		  fn(intent, leds) ->
			  value = case intent.value do
								  :on -> 255
								  :off -> 0
							  end
			  Script.new(:orange_lights, leds)
			  |> Script.add_step(:all, :set_brightness, [value])
		  end
    end
	end

	# Sounds

  defp say_hungry() do
    fn(_intent, sound_players) ->
      Script.new(:say_hungry, sound_players)
      |> Script.add_step(:loud_speech, :speak, ["I am hungry"])
    end
  end
  
  defp say_scared() do
    fn(_intent, sound_players) ->
      Script.new(:say_scared, sound_players)
      |> Script.add_step(:loud_speech, :speak, ["I am scared"])
    end
  end
  
  defp say_curious() do
    fn(_intent, sound_players) ->
      Script.new(:say_curious, sound_players)
      |> Script.add_step(:loud_speech, :speak, ["Let's check things out"])
    end
  end
  
  defp say_uh_oh() do
    fn(_intent, sound_players) ->
      Script.new(:say_uh_oh, sound_players)
      |> Script.add_step(:loud_speech, :speak, ["Uh oh!"])
    end
  end
  
  defp say_stuck() do
    fn(_intent, sound_players) ->
      Script.new(:say_stuck, sound_players)
      |> Script.add_step(:loud_speech, :speak, ["I am stuck"])
    end
  end
  
  defp say_food() do
    fn(_intent, sound_players) ->
      Script.new(:say_food, sound_players)
      |> Script.add_step(:loud_speech, :speak, ["Food! I found food!"])
    end
  end
  
  defp say() do
    fn(intent, sound_players) ->
      Script.new(:say, sound_players)
      |> Script.add_step(:loud_speech, :speak, [intent.value])
    end
  end
  
  defp eating_noises() do
    fn(_intent, sound_players) ->
      Script.new(:say_eating, sound_players)
      |> Script.add_step(:loud_speech, :speak, ["Nom de nom de nom"])
    end
  end

	# communications
	
	defp communicate() do
		fn(intent, communicators) ->
			Script.new(:communicate, communicators)
			|> Script.add_step(:marvins, :communicate, [intent.value])
		end
	end
  
end
