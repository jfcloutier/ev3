defmodule Ev3.Behavior do
	@moduledoc "A behavior triggered by and meant to satisfy a motive"

	alias Ev3.Memory
	alias Ev3.Percept
	alias Ev3.Motive
	alias Ev3.Transition
	require Logger

	@doc "Start a behavior from a configuration"
	def start_link(behavior_config) do
		Logger.info("Starting #{__MODULE__} #{behavior_config.name}")
		Agent.start_link(fn() -> %{name: behavior_config.name,
															 fsm: behavior_config.fsm,
															 motives: [],
															 fsm_state: nil} end,
										 [name: behavior_config.name])
	end

	@doc "A behavior responds to a motive by starting or stopping the fsm"
	def react_to_motive(name, %Motive{} = motive) do
		Agent.update(
			name,
			fn(state) ->
				if Motive.on?(motive) do
						start(motive, state) # maybe
				else
						stop(motive, state) # maybe
				end
			end)
	end

	def react_to_percept(name, %Percept{} = percept) do
		Agent.update(
			name,
			fn(state) ->
				transit_on(percept, state)
			end
		)
	end

	### Private

	defp inhibited?(%{motives: motives} = state) do
		Enum.all?(motives, &Memory.inhibited?(&1.about))
	end

	defp start(on_motive,  %{fsm_state: nil} = state) do # might start only if not started yet
		if not Memory.inhibited?(on_motive.about) do
			if not on_motive in state.motives do
				Logger.info("STARTED behavior #{state.name}")
				%{state | motives: [on_motive | state.motives], fsm_state: state.fsm.initial_state}
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
				Logger.info("STOPPED behavior #{state.name}")
				%{state | motives: [], fsm_state: nil}
			motives ->
				%{state | motives: motives}
		end
	end

	defp transit_on(_percept, %{fsm_state: nil} = state) do # do nothing if not started
		state
	end
	
	defp transit_on(percept, state) do
		case find_transition(percept, state) do
			nil ->
				state
			transition ->
				if not inhibited?(state) do
					apply_transition(transition, percept, state)
				else
					Logger.info("INHIBITED behavior #{state.name}")
					state
				end
		end
	end

	defp find_transition(percept, %{fsm_state: fsm_state, fsm: fsm} = state) do
		fsm.transitions
		|> Enum.find(fn(transition) ->
			fsm_state in transition.from
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
	
