defmodule Ev3.Behaviors do
	@moduledoc "Provides the configurations of all behaviors to be activated"

	require Logger
	alias Ev3.BehaviorConfig
	alias Ev3.FSM
	alias Ev3.Transition

	@doc "Give the configurations of all benaviors to be activated"
  def behavior_configs() do
		[
				BehaviorConfig.new( # roam around
					name: :roam,
					motivated_by: [:curiosity],
					senses: [:collision, :time_elapsed],
					fsm: %FSM{
									 initial_state: :started,
									 transitions: [
										 %Transition{from: [:started, :roaming],
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
									 ]
							 }
					),
				BehaviorConfig.new( # look for food in bright places
					name: :forage,
					motivated_by: [:hunger],
					senses: [:food, :darker, :lighter],
					fsm: %FSM{
									 initial_state: :started,
									 transitions: [
										 %Transition{from: [:started, :on_track],
																 on: :lighter,
																 to: :on_track,
																 doing: stay_the_course()
																},
										 %Transition{from: [:started, :on_track, :off_track],
																 on: :darker,
																 to: :off_track,
																 doing: change_course()},
										 %Transition{from: [:started, :on_track, :off_track],
																 on: :food,
																 to: :feeding,
																 condition: fn(value) -> value == :plenty end,
																 doing: eat()},
										 %Transition{from: [:feeding],
																 on: :hungry,
																 condition: fn(value) -> value == :not end,
																 to: nil,
																 doing: nil}
									 ]
							 }
				),
		 BehaviorConfig.new( #now is the time to panic!
			 name: :run_around,
			 motivated_by: [:panic],
			 senses: [:ambient],
			 fsm: %FSM{
								initial_state: :started,
								transitions: [
									%Transition{from: [:started],
															on: :ambient,
															 condition: fn(value) -> value <= 50 end,
															 to: :panicking,
															 doing: flail()},
									%Transition{from: [:panicking],
															on: :ambient,
															 condition: fn(value) -> value > 50 end,
															 to: nil}
									]
								}
						) 
		 ] 
	end

	defp roam() do
		fn(percept) ->
			Logger.info("ROAMING from #{percept.about} = #{inspect percept.value}")
		end # TODO
	end

	defp avoid_collision() do
		fn(percept) ->
			Logger.info("AVOIDING COLLISION from #{percept.about} = #{inspect percept.value}")
		end # TODO
	end

	defp backoff() do
		fn(percept) ->
			Logger.info("BACKING OFF from #{percept.about} = #{inspect percept.value}")
		end # TODO
	end

	defp stay_the_course() do
		fn(percept) ->
			Logger.info("STAYING THE COURSE from #{percept.about} = #{inspect percept.value}")
		end # TODO
	end

	defp change_course() do
		fn(percept) ->
			Logger.info("CHANGING COURSE from #{percept.about} = #{inspect percept.value}")
		end # TODO
	end

	defp eat() do
		fn(percept) ->
			Logger.info("EATING from #{percept.about} = #{inspect percept.value}")
		end # TODO
	end

	defp flail() do
		fn(percept) ->
			Logger.info("FLAILING from #{percept.about} = #{inspect percept.value}")
		end # TODO
	end	
	
end
