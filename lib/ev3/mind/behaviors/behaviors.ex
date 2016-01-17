defmodule Ev3.Behaviors do
	@moduledoc "Provides the configurations of all behaviors to be activated"

	require Logger
	alias Ev3.BehaviorConfig
	alias Ev3.FSM
	alias Ev3.Transition
	alias Ev3.CNS
	alias Ev3.Percept
	alias Ev3.Intent

	@doc "Give the configurations of all benaviors to be activated by motives and driven by percepts"
  def behavior_configs() do
		[
				BehaviorConfig.new( # roam around
					name: :exploring,
					motivated_by: [:curiosity],
					senses: [:collision, :time_elapsed, :stuck],
					fsm: %FSM{
									 initial_state: :started,
									 final_state: :ended,
									 transitions: [
										 %Transition{to: :started,
																 doing: start_roaming()},																 
										 %Transition{from: [:started],
																 on: :time_elapsed,
																 to: :roaming,
																 doing: nil
																},
										 %Transition{from: [:roaming],
																 on: :time_elapsed,
																 to: :roaming,
																 doing: roam()
																},
										 %Transition{from: [:roaming],
																 on: :collision,
																 to: :roaming,
																 condition: fn(value) -> value == :imminent end,
																 doing: avoid_collision()
																},
										 %Transition{from: [:roaming],
																 on: :collision,
																 to: :roaming,
																 condition: fn(value) -> value == :now end,
																 doing: backoff()
																},
										 %Transition{from: [:roaming],
																 on: :stuck,
																 to: :roaming,
																 doing: backoff()
																},
										 %Transition{to: :ended,
																 doing: nothing()}
									 ]
							 }
				),
				BehaviorConfig.new( # look for food in bright places
					name: :foraging,
					motivated_by: [:hunger],
					senses: [:food, :distance, :direction, :collision, :stuck],
					fsm: %FSM{
									 initial_state: :started,
									 final_state: :ended,
									 transitions: [
										 %Transition{to: :started,
																 doing: start_foraging() },																 
										 %Transition{from: [:started, :on_track],
																 on: :distance,
																 to: :on_track,
																 doing: stay_the_course() # faster or slower according to closer or farther
																},
										 %Transition{from: [:off_track],
																 on: :direction,
																 to: :on_track,
																	condition: fn({orientation, _value}) -> orientation == :ahead end
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :direction,
																 to: :off_track,
																	condition: fn({orientation, _value}) -> orientation != :ahead end,
																	doing: change_course()
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :distance,
																 to: :off_track,
																	condition: fn(value) -> value == :unknown end,
																	doing: change_course()
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :collision,
																 to: :off_track,
																	condition: fn(value) -> value == :imminent end,
																	doing: avoid_collision()
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :collision,
																 to: :off_track,
																	condition: fn(value) -> value == :now end,
																	doing: backoff()
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :stuck,
																 to: :off_track,
																	doing: backoff()
																},
										 %Transition{from: [:on_track, :off_track, :feeding],
																 on: :food,
																	condition: fn(value) -> value != :none end,
																	to: :feeding,
																	doing: eat()
																},
										 %Transition{from: [:feeding],
																 on: :food,
																	condition: fn(value) -> value == :none end,
																	to: :off_track,
																	doing: nil
																},
										 %Transition{to: :ended,
																 doing: turn_on_green_leds()
																}
									 ]
							 }
				),
				BehaviorConfig.new( # now is the time to panic!
					name: :panicking,
					motivated_by: [:fear],
					senses: [:light, :time_elapsed],
					fsm: %FSM{
									 initial_state: :started,
									 final_state: :ended,
									 transitions: [
										 %Transition{to: :started,
																 doing: turn_on_red_leds()},																 
										 %Transition{from: [:started],
																 on: :time_elapsed,
																 to: :panicking,
																 doing: panic()},
										 %Transition{from: [:panicking],
																 on: :light,
																 to: :ended,
																	condition: fn(value) -> value == :lighter end,
																	doing: nil},
										 %Transition{to: :ended,
																 doing: calm_down()
																}

									 ]
							 }
				) 
		] 
	end

  ### Private

  defp generate_intent(about, value \\ nil) do
    Intent.new(about: about, value: value)
    |> CNS.notify_intended()
  end

  defp generate_strong_intent(about, value \\ nil) do
    Intent.new_strong(about: about, value: value)
    |> CNS.notify_intended()
  end

	defp nothing() do
		fn(_percept, _state) ->
			Logger.info("Doing NOTHING")
		end
	end

	defp turn_on_green_leds() do
		fn(_percept, _state) ->
			green_lights()
		end
	end

	defp turn_on_red_leds() do
		fn(_percept, _state) ->
			red_lights()
		end
	end

  defp start_roaming() do
		fn(_percept, _state) ->
			Logger.info("START ROAMING")
      turn_on_green_leds()
      generate_strong_intent(:say_curious)
    end
  end

	defp roam() do
		fn(percept, _state) ->
			Logger.info("ROAMING from #{percept.about} = #{inspect percept.value}")
			#			green_lights()
			if :random.uniform(3) == 1 do
				turn_where = case :random.uniform(2) do
											 1 -> :turn_left
											 2 -> :turn_right
										 end
        generate_intent(turn_where, :random.uniform(2))
			end
			how_long = :random.uniform(3) # secs
      generate_intent(:go_forward,  %{speed: :fast, time: how_long})
		end
	end

	defp avoid_collision() do
		fn(percept, _state) ->
			Logger.info("AVOIDING COLLISION from #{percept.about} = #{inspect percept.value}")
			turn_where = case :random.uniform(2) do
										 1 -> :turn_left
										 2 -> :turn_right
									 end
      generate_strong_intent(turn_where, 2)
		end
	end

	defp backoff() do
		fn(percept, _state) ->
			Logger.info("BACKING OFF from #{percept.about} = #{inspect percept.value}")
			how_long = 3 + :random.uniform(4) # secs
      generate_strong_intent(:go_backward,  %{speed: :slow, time: how_long})
			turn_where = case :random.uniform(2) do
										 1 -> :turn_left
										 2 -> :turn_right
									 end
			generate_intent(turn_where, :random.uniform(4) - 1)
		end 
	end

	defp stay_the_course() do
		fn(%Percept{about: :distance, value: value} = percept, _state) ->
			Logger.info("STAYING THE COURSE from #{percept.about} = #{inspect percept.value}")
			speed = case value do
								:unknown -> :very_fast
								:very_far -> :very_fast
								:far -> :fast
								:close -> :slow
								:very_close -> :very_slow
							end
			generate_intent(:go_forward, %{speed: speed, time: 1})
		end 
	end

	defp change_course() do
		fn
		(%Percept{about: :direction, value: {orientation, value}} = percept, _state) ->
			Logger.info("CHANGING COURSE from #{percept.about} = #{inspect percept.value}")
			{turn_where, how_much} = case orientation do
										 :left -> {:turn_left, value / 60}
										 :right -> {:turn_right, value / 60}
										 :ahead -> {:turn_right, 0}
									 end
			generate_intent(turn_where, how_much)
			
		(%Percept{about: :distance, value: _value} = percept, _state) ->
			Logger.info("CHANGING COURSE from #{percept.about} = #{inspect percept.value}")
			turn_where = case :random.uniform(2) do
										 1 -> :turn_left
										 2 -> :turn_right
									 end
			how_much = round(:random.uniform(5) / 3)
			generate_intent(turn_where, how_much)
		end
	end

  defp start_foraging() do
		fn(_percept, _state) ->
      Logger.info("START FORAGIN")
      turn_on_green_leds()
      generate_strong_intent(:say_hungry)
    end
  end

	defp eat() do
		fn(%Percept{about: :food, value: value}, _state) ->
			Logger.info("EATING from food = #{inspect value}")
			orange_lights()
      generate_strong_intent(:say_food)
			generate_strong_intent(:stop)
			how_much = case value do
									 :plenty -> :lots
									 :little -> :some
								 end
      generate_strong_intent(:eating_noises)
			generate_strong_intent(:eat, how_much)
		end
	end
			
	defp panic() do
		fn(_percept, _state) ->
			Logger.info("PANICKING!")
      generate_strong_intent(:say_scared)
			red_lights()
			generate_intent(:go_backward, %{speed: :slow, time: 2})
			for _n <- [1 .. :random.uniform(5)] do
				intend_to_change_course()
			end
		end
	end

	def calm_down() do
		fn(_percept, _state) ->
			Logger.info("CALMING DOWN")
			green_lights()
		end
	end

	defp intend_to_change_course() do
		turn_where = case :random.uniform(2) do
									 1 -> :turn_left
									 2 -> :turn_right
								 end
		generate_intent(turn_where, :random.uniform(2))
	end

  defp red_lights() do
		Logger.info("TURNING ON RED LIGHTS")
		generate_intent(:red_lights, :on)
	end
			

	defp green_lights() do
		Logger.info("TURNING ON GREEN LIGHTS")
		generate_intent(:green_lights, :on)
	end

	defp orange_lights() do
		Logger.info("TURNING ON ORANGE LIGHTS")
		generate_intent(:orange_lights, :on)
	end

end
