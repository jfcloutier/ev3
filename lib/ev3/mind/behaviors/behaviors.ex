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
																 doing: backoff(true)
																},
										 %Transition{from: [:roaming],
																 on: :stuck,
																 to: :roaming,
                                 condition: fn(value) -> value end, # true or false
																 doing: unstuck()
																},
										 %Transition{to: :ended,
																 doing: nothing()}
									 ]
							 }
				),
				BehaviorConfig.new( # look for food in bright places
					name: :foraging,
					motivated_by: [:hunger],
					senses: [:food, :scent_strength, :scent_direction, :collision, :stuck],
					fsm: %FSM{
									 initial_state: :started,
									 final_state: :ended,
									 transitions: [
										 %Transition{to: :started,
																 doing: start_foraging() },																 
										 %Transition{from: [:started, :on_track],
																 on: :scent_strength,
																 to: :on_track,
																 doing: stay_the_course() # faster or slower according to closer or farther
																},
										 %Transition{from: [:off_track],
																 on: :scent_direction,
																 to: :on_track,
																	condition: fn({orientation, _value, _strength}) -> orientation == :ahead end
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :scent_direction,
																 to: :off_track,
																	condition: fn({orientation, _value, _strength}) -> orientation != :ahead end,
																	doing: change_course()
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :scent_strength,
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
																	doing: backoff(true)
																},
										 %Transition{from: [:on_track, :off_track],
																 on: :stuck,
																 to: :off_track,
                                 condition: fn(value) -> value end, # true or false
																 doing: unstuck()
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
																	doing: backoff(false)
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
																 doing: start_panicking()},																 
										 %Transition{from: [:started, :panicking],
																 on: :time_elapsed,
																 to: :panicking,
																 doing: panic()},
										 %Transition{from: [:panicking],
																 on: :danger,
																 to: :ended,
																	condition: fn(value) -> value == :none end,
																	doing: nil},
										 %Transition{to: :ended,
																 doing: calm_down()
																}

									 ]
							 }
				) 
		] 
	end

  @doc "Find all senses used for behaviors"
  def used_senses() do
    behavior_configs()
    |> Enum.map(&(Map.get(&1, :senses, [])))
    |> List.flatten()
    |> MapSet.new()
    |> MapSet.to_list()
  end
 
  ### Private

  defp generate_intent(about) do
    generate_intent(about, nil)
  end
  
  defp generate_intent(about, value, strong? \\ false) do
    if strong? do
      Intent.new_strong(about: about, value: value)
    else
      Intent.new(about: about, value: value)
    end
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
      green_lights()
      # generate_intent(:say_curious)
    end
  end

	defp roam() do
		fn(percept, _state) ->
			Logger.info("ROAMING from #{percept.about} = #{inspect percept.value}")
			green_lights()
			if :random.uniform(2) == 1 do
				turn_where = case :random.uniform(2) do
											 1 -> :turn_left
											 2 -> :turn_right
										 end
        generate_intent(turn_where, :random.uniform(10))
			end
      generate_intent(:go_forward,  %{speed: :normal, time: 1})
		end
	end

	defp avoid_collision() do
		fn(percept, _state) ->
			Logger.info("AVOIDING COLLISION from #{percept.about} = #{inspect percept.value}")
      generate_intent(:say_uh_oh)
			turn_where = case :random.uniform(2) do
										 1 -> :turn_left
										 2 -> :turn_right
									 end
      generate_intent(turn_where, 4)
		end
	end

  defp unstuck() do
    fn(_percept, _state) ->
      Logger.info("GETTING UNSTUCK")
      generate_intent(:say_stuck)
      intend_backoff(true)
    end
  end

  defp intend_backoff(strong?) do
		how_long = 10 + :random.uniform(6) # secs
    generate_intent(:go_backward,  %{speed: :slow, time: how_long}, strong?)
		turn_where = case :random.uniform(2) do
									 1 -> :turn_left
									 2 -> :turn_right
								 end
		generate_intent(turn_where, :random.uniform(5) + 4, strong?)
  end    


	defp backoff(strong?) do
		fn(percept, _state) ->
			Logger.info("BACKING OFF from #{percept.about} = #{inspect percept.value}")
      intend_backoff(strong?)
		end 
	end

	defp stay_the_course() do
		fn(%Percept{about: :scent_strength, value: value} = percept, _state) ->
			Logger.info("STAYING THE COURSE from #{percept.about} = #{inspect percept.value}")
			speed = case value do
								:unknown -> :very_fast
								:very_weak -> :very_fast
								:weak -> :fast
								:strong -> :slow
								:very_strong -> :very_slow
							end
			generate_intent(:go_forward, %{speed: speed, time: 1})
		end 
	end

	defp change_course() do
		fn
		(%Percept{about: :scent_direction, value: {orientation, value, strength}} = percept, _state) ->
			  Logger.info("CHANGING COURSE from #{percept.about} = #{inspect percept.value}")
        factor = case strength do
                   nil -> 1
                   :very_strong -> 1.5
                   :strong -> 1.2
                   :weak -> 1
                   :very_weak -> 1
                   :unknown -> 1
                 end
			{turn_where, how_much} = case orientation do
										 :left -> {:turn_left, factor * value / 60}
										 :right -> {:turn_right, factor * value / 60}
										 :ahead -> {:turn_right, 0}
									 end
			generate_intent(turn_where, how_much)
			
		(%Percept{about: :scent_strength, value: _value} = percept, _state) ->
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
      Logger.info("START FORAGING")
      green_lights()
      generate_intent(:say_hungry)
    end
  end

	defp eat() do
		fn(%Percept{about: :food, value: value}, _state) ->
			Logger.info("EATING from food = #{inspect value}")
			orange_lights()
			generate_intent(:stop, nil, true)
			how_much = case value do
									 :plenty -> :lots
									 :little -> :some
								 end
      generate_intent(:eating_noises)
			generate_intent(:eat, how_much)
		end
	end

  defp start_panicking() do
    fn(_percept, _state) ->
       red_lights()
			 Logger.info("PANICKING")
       generate_intent(:say_scared)
    end
  end
			
	defp panic() do
		fn(_percept, _state) ->
			red_lights()
      for _n <- 1 .. :random.uniform(4) do
			  generate_intent(:go_backward, %{speed: :fast, time: 1}, true)
			  turn_where = case :random.uniform(2) do
									   1 -> :turn_left
									   2 -> :turn_right
								   end
		    generate_intent(turn_where, :random.uniform(5) + 2, true)
      end
		end
	end

	def calm_down() do
		fn(_percept, _state) ->
			Logger.info("CALMING DOWN")
			green_lights()
		end
	end

  defp red_lights() do
		Logger.info("TURNING ON RED LIGHTS")
		generate_intent(:red_lights, :on, true)
	end
			

	defp green_lights() do
		Logger.info("TURNING ON GREEN LIGHTS")
		generate_intent(:green_lights, :on, true)
	end

	defp orange_lights() do
		Logger.info("TURNING ON ORANGE LIGHTS")
		generate_intent(:orange_lights, :on, true)
	end

end
