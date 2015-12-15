defmodule Ev3.Behavior do
	@moduledoc "A behavior triggered by and meant to satisfy a motive"

	alias Ev3.Memory
	alias Ev3.Percept
	alias Ev3.Motive
	alias Ev3.Transition
	alias Ev3.FSM
	import Ev3.Utils
	require Logger

	@max_percept_age 1000 # percepts older than 1 sec are dropped
	@down_time 2000

	@doc "Start a behavior from a configuration"
	def start_link(behavior_config) do
		Logger.info("Starting #{__MODULE__} #{behavior_config.name}")
		Agent.start_link(fn() -> %{name: behavior_config.name,
															 fsm: behavior_config.fsm,
															 motives: [],
															 fsm_state: nil,
															 responsive: true } end,
										 [name: behavior_config.name])
	end

	@doc "A behavior responds to a motive by starting or stopping the fsm"
	def react_to_motive(name, %Motive{} = motive) do
		Agent.update(
			name,
			fn(state) ->
				if Motive.on?(motive) do
						start(motive, state) # if applicable
				else
						stop(motive, state) # if applicable
				end
			end)
	end

	def react_to_percept(name, %Percept{} = percept) do
		Agent.update(
			name,
			fn(state) ->
				case transit_on(percept, state) do
					%{fsm_state: final_state, fsm: %FSM{final_state: final_state}} = end_state ->
						final_transit(end_state)
					new_state ->
						new_state
				end
			end
		)
	end

	def actuator_overwhelmed(name) do
		Agent.update(
			name,
			fn(state) ->
				spawn_link(
					fn() -> # make sure to reactivate
						:timer.sleep(@down_time)
						reactivate(name)
					end)
				%{state | responsive: false}
			end)
	end

	def reactivate(name) do
		Agent.update(
			name,
			fn(state) ->
				%{state | responsive: true}
			end)
	end

	### Private

	defp percept_fresh?(percept) do
		(now() - percept.since) < @max_percept_age
	end

	defp inhibited?(%{motives: motives} = _state) do
		Enum.all?(motives, &Memory.inhibited?(&1.about))
	end

	defp start(on_motive,  %{fsm_state: nil} = state) do # might start only if not started yet
		if not Memory.inhibited?(on_motive.about) do
			if not on_motive in state.motives do
				Logger.info("STARTED behavior #{state.name}")
				initial_transit(%{state | motives: [on_motive | state.motives]})
			else
				state
			end
		else
			state
		end
	end

	defp start(_on_motive, state) do # don't start if already started
		state
	end

	defp stop(_off_motive, %{fsm_state: nil} = state) do # already stopped, do nothing
		state
	end
	
	defp stop(off_motive, state) do # might stop or do nothing
		surviving_motives = Enum.filter(state.motives, &(&1.about != off_motive.about))
		case surviving_motives do
			[] ->
				Logger.info("STOPPED behavior #{state.name}: #{off_motive.about} if off")
				final_transit(state)
				%{state | motives: [], fsm_state: nil}
			motives ->
				Logger.info("NOT STOPPED behavior #{state.name} because #{inspect surviving_motives}")
				%{state | motives: motives}
		end
	end

	defp initial_transit(%{fsm_state: nil, fsm: fsm} = state) do
		transition = find_initial_transition(fsm)
		if transition != nil do
			transition.doing.(nil, state)
		end
		%{state | fsm_state: fsm.initial_state}
	end

	defp final_transit(%{fsm: fsm} = state) do
		transition = find_final_transition(fsm)
		if transition != nil do
			transition.doing.(nil, state)
		end
		%{state | fsm_state: nil}
	end

	defp find_initial_transition(%FSM{initial_state: initial_state,
																		transitions: transitions}) do
		Enum.find(transitions,
							&(&1.from == nil and &1.to == initial_state and &1.doing != nil)
		)
	end

	defp find_final_transition(%FSM{final_state: final_state, transitions: transitions}) do
		Enum.find(transitions,
							&(&1.to == final_state and &1.doing != nil)
		)
	end

	defp transit_on(_percept, %{fsm_state: nil} = state) do # do nothing if not started
		state
	end

	defp transit_on(_percept, %{name: _name, responsive: false} = state) do
#		Logger.info("-- NOT RESPONSIVE: #{name}")
		state
	end
	
	defp transit_on(percept, state) do
		case find_transition(percept, state) do
			nil ->
				state
			transition ->
				if not inhibited?(state) do
					if percept_fresh?(percept) do
						apply_transition(transition, percept, state)
					else
						Logger.warn("STALE: Behavior #{state.name} not reacting to percept #{percept.about} = #{inspect percept.value}")
						state
					end
				else
					Logger.info("-- INHIBITED: behavior #{state.name}")
					state
				end
		end
	end

	defp find_transition(percept, %{fsm_state: fsm_state, fsm: fsm} = _state) do
		fsm.transitions
		|> Enum.find(fn(transition) ->
			transition.from != nil # else initial transition
			and fsm_state in transition.from
			and percept.about == transition.on
			and (transition.condition == nil or transition.condition.(percept.value))
		end)
	end

	defp apply_transition(%Transition{doing: nil} = transition, _percept, state) do
		%{state | fsm_state: transition.to}
	end

	defp apply_transition(%Transition{doing: action} = transition, percept, state) do
		action.(percept, state)
		%{state | fsm_state: transition.to}
	end
	
end
	
