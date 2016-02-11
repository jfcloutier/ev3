defmodule Ev3.Actuator do
	@moduledoc "An actuator that translates intents into commands sent to motors"

	require Logger
	alias Ev3.LegoMotor
	alias Ev3.Script
  alias Ev3.Device
	alias Ev3.MotorSpec
	alias Ev3.LEDSpec
  alias Ev3.SoundSpec
	alias Ev3.LegoLED
  alias Ev3.LegoSound
	alias Ev3.CNS
  alias Ev3.Intent

	@max_intent_age 2000 # intents older than 1 sec are stale
  @strong_intent_factor 2 # strong intents last longer before becoming stale
  
	@doc "Start an actuator from a configuration"
	def start_link(actuator_config) do
		Logger.info("Starting #{__MODULE__} #{actuator_config.name}")
		Agent.start_link(
      fn() ->
        case actuator_config.type do
          :motor ->
						%{actuator_config: actuator_config,
							devices: find_motors(actuator_config.specs)}
			    :led ->
						%{actuator_config: actuator_config,
							devices: find_leds(actuator_config.specs)}
          :sound ->
            %{actuator_config: actuator_config,
              devices: find_sound_players(actuator_config.specs)}
				end
      end,
      [name: actuator_config.name])
	end

	def realize_intent(name, intent) do
		Agent.update(
			name,
			fn(state) ->
        if check_freshness(name, intent) do
				  state.actuator_config.activations
				  |> Enum.filter_map(
					  fn(activation) -> activation.intent == intent.about end,
					  fn(activation) -> activation.action end)
				  |> Enum.each( # execute activated actions sequentially
					  fn(action) ->
						  script = action.(intent, state.devices)
						  Script.execute(state.actuator_config.type, script)
						  CNS.notify_realized(name, intent) # This will have the intent stored in memory. Unrealized intents are not retained in memory.
					  end)
        end
        state
			end,
			30_000
		)
	end

	### Private

	defp check_freshness(name, intent) do
    age = Intent.age(intent)
    factor = if intent.strong, do: @strong_intent_factor, else: 1
    if age > @max_intent_age * factor do
      Logger.info("STALE #{Intent.strength(intent)} intent #{inspect intent.about} #{age}")
      CNS.notify_overwhelmed(:actuator, name)
      false
    else
      true
    end
  end

	defp find_motors(motor_specs) do
		all_motors = LegoMotor.motors()
		found = Enum.reduce(
			motor_specs,
			%{},
			fn(motor_spec, acc) ->
				motor = Enum.find(all_motors,
													&(MotorSpec.matches?(motor_spec, &1)))
				if motor == nil do
					Logger.warn("Motor not found matching #{inspect motor_spec} in #{inspect all_motors}")
          acc
				else
				  Map.put(acc, motor_spec.name, update_props(motor, motor_spec.props))
        end
			end)
		found
	end

	defp find_leds(led_specs) do
		all_leds = LegoLED.leds()
		found = Enum.reduce(
			led_specs,
			%{},
			fn(led_spec, acc) ->
				led = Enum.find(all_leds,
													&(LEDSpec.matches?(led_spec, &1)))
				if led == nil do
					Logger.warn("LED not found matching #{inspect led_spec} in #{inspect all_leds}")
          acc
				else
				  Map.put(acc, led_spec.name, update_props(led, led_spec.props))
        end
			end)
		found
	end

  defp find_sound_players(sound_specs) do
    all_sound_players = LegoSound.sound_players()
    found = Enum.reduce(
      sound_specs,
      %{},
      fn(sound_spec, acc) ->
        sound_player = Enum.find(all_sound_players,
                                 &(SoundSpec.matches?(sound_spec, &1)))
        if sound_player == nil do
          Logger.warn("Sound player not found matching #{inspect sound_spec} in #{inspect all_sound_players}")
          acc
        else
          Map.put(acc, sound_spec.name, update_props(sound_player, sound_spec.props))
        end
      end)
    found
  end

  defp update_props(device, props) do
    Enum.reduce(
      Map.keys(props),
      device,
      fn(key, dev) ->
        %Device{dev | props: Map.put(dev.props, key, Map.get(props, key, nil))}
      end
    )
  end

end
