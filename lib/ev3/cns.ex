defmodule Ev3.CNS do
	@moduledoc "A resilient event manager that acts as the robot's central nervous system"

  alias Ev3.DetectorsHandler
	alias Ev3.PerceptorsHandler
	alias Ev3.MemoryHandler
  alias Ev3.InternalClockHandler
	alias Ev3.ActuatorsHandler
	alias Ev3.BehaviorsHandler
	alias Ev3.MotivatorsHandler
  alias Ev3.ChannelsHandler
	alias Ev3.Percept
	alias Ev3.Motive
	alias Ev3.Intent
	require Logger
	use GenServer
	import Ev3.Utils

  @name __MODULE__
	@dispatcher :dispatcher
  @faint_duration 2500

	@doc "Start the event manager and register the event handlers"
	def start_link() do
    Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
  end

	@doc "Handle notification of a new perception"
	def notify_perceived(percept) do
		GenServer.cast(@name, {:notify_perceived, percept})
	end

	@doc "Handle notification of a new motive"
	def notify_motivated(motive) do
		GenServer.cast(@name, {:notify_motivated, motive})
	end

	@doc "Handle notification of a new intent"
	def notify_intended(intent) do
		GenServer.cast(@name, {:notify_intended, intent})
	end

		@doc "Handle notification of an intent realized"
	def notify_realized(actuator_name, intent) do
		GenServer.cast(@name, {:notify_realized, actuator_name, intent})
	end

	@doc "Handle notification of an new or extended memory change"
	def notify_memorized(memorization, %Percept{} = percept) do
		GenServer.cast(@name, {:notify_memorized, memorization, percept})
	end

	@doc "Handle notification of a  motive"
	def notify_memorized(memorization, %Motive{} = motive) do
		GenServer.cast(@name, {:notify_memorized, memorization, motive})
	end

	@doc "Handle notification of an intent"
	def notify_memorized(memorization, %Intent{} = intent) do
		GenServer.cast(@name, {:notify_memorized, memorization, intent})
	end

	@doc "A component is overwhelmed"
	def notify_overwhelmed(component_type, actuator_name) do
		GenServer.cast(@name, {:notify_overwhelmed, component_type, actuator_name})
	end

  @doc "A behavior started"
  def notify_started(:behavior, behavior_name) do
    GenServer.cast(@name, {:notify_behavior_started, behavior_name})
  end

  @doc "A behavior stopped"
  def notify_stopped(:behavior, behavior_name) do
    GenServer.cast(@name, {:notify_behavior_stopped, behavior_name})
  end

  @doc "A behavior inhibited"
  def notify_inhibited(:behavior, behavior_name) do
    GenServer.cast(@name, {:notify_behavior_inhibited, behavior_name})
  end

  @doc "A behavior transited to a new state"
  def notify_transited(:behavior, behavior_name, state_name) do
    GenServer.cast(@name, {:notify_behavior_transited, behavior_name, state_name})
  end

  @doc "Revive from fainting"
  def notify_revive() do
    GenServer.cast(@name, :notify_revive)
  end

  @doc "Is the robot paused?"
  def paused?() do
    GenServer.call(@name, :paused?, 15_000)
  end

  @doc "Toggle the robot between paused and active"
  def toggle_paused() do
    GenServer.call(@name, :toggle_paused, 15_000)
  end

  @doc "Notified of new runtime stats"
  def notify_runtime_stats(stats) do
    GenServer.cast(@name, {:notify_runtime_stats, stats})
  end

	### Callbacks

	def init(_) do
		{:ok, _pid} = GenEvent.start_link(name: @dispatcher)
    register_handlers()
    {:ok, %{when_started: now(), overwhelmed: false, paused: false}}
	end
	
	def handle_cast({:notify_perceived, percept}, state) do
		Logger.info("Percept #{inspect percept.about} #{inspect percept.value} at #{delta(state)}")
		GenEvent.notify(@dispatcher, {:perceived, percept})
		{:noreply, state}
	end	

	def handle_cast({:notify_motivated, motive}, state) do
		Logger.info("Motive #{motive.about} #{inspect motive.value} at #{delta(state)}")
		GenEvent.notify(@dispatcher, {:motivated, motive})
		{:noreply, state}
	end
	
	def handle_cast({:notify_intended, intent}, state) do
		Logger.info("Intent #{intent.about} #{Intent.strength(intent)} at #{delta(state)}")
		GenEvent.notify(@dispatcher, {:intended, intent})
		{:noreply, state}
	end
	
	def handle_cast({:notify_realized, actuator_name, intent}, state) do
	  Logger.info("Intent #{Intent.strength(intent)} realized #{intent.about} #{inspect intent.value} by #{actuator_name} at #{delta(state)}")
		GenEvent.notify(@dispatcher, {:realized, actuator_name, intent})
		{:noreply, state}
	end
	
	def handle_cast({:notify_memorized, memorization, data}, state) do
		Logger.debug("Memorized ===> #{memorization} #{inspect type(data)} #{inspect data.about} = #{inspect data.value} at #{delta(state)}")
		GenEvent.notify(@dispatcher, {:memorized, memorization, data})
		{:noreply, state}
	end

	def handle_cast({:notify_overwhelmed, component_type, name}, state) do
    Logger.info("OVERWHELMED - #{component_type} #{name} at #{delta(state)}")
    GenEvent.notify(@dispatcher, {:overwhelmed, component_type, name})
    if not state.overwhelmed and not state.paused do
      Logger.info("FAINTING at #{delta(state)}")
		  GenEvent.notify(@dispatcher, :faint)
      set_alarm_clock(@faint_duration)
		  {:noreply, %{state | overwhelmed: true}}
    else
      {:noreply, state}
    end
	end

  def handle_cast({:notify_behavior_started, name}, state) do
    GenEvent.notify(@dispatcher, {:behavior_started, name})
    {:noreply, state}
  end

  def handle_cast({:notify_behavior_stopped, name}, state) do
    GenEvent.notify(@dispatcher, {:behavior_stopped, name})
    {:noreply, state}
  end

  def handle_cast({:notify_behavior_inhibited, name}, state) do
    GenEvent.notify(@dispatcher, {:behavior_inhibited, name})
    {:noreply, state}
  end

  def handle_cast({:notify_behavior_transited, name, state_name}, state) do
    GenEvent.notify(@dispatcher, {:behavior_transited, name, state_name})
    {:noreply, state}
  end

  def handle_cast(:notify_revive, state) do
    Logger.info("REVIVING at #{delta(state)}")
    if not state.paused, do: GenEvent.notify(@dispatcher, :revive)
    {:noreply, %{state | overwhelmed: false}}
  end

  def handle_cast({:notify_runtime_stats, stats}, state) do
    GenEvent.notify(@dispatcher, {:runtime_stats, stats})
    {:noreply, state}
  end

	def handle_info({:gen_event_EXIT, crashed_handler, error}, state) do
		Logger.error("#{crashed_handler} crashed. Restarting #{__MODULE__}.")		
		{:stop, {:handler_died, error}, state}
	end

  def handle_call(:paused?, _from, state) do
    {:reply, state.paused, state}
  end

  def handle_call(:toggle_paused, _from, state) do
   new_state = toggle_pause(state)
    {:reply, :ok, new_state}
  end


	### Private

  defp toggle_pause(state) do
    if state.paused do
      GenEvent.notify(@dispatcher, :revive)
      %{state | paused: false, overwhelmed: false}
    else
      GenEvent.notify(@dispatcher, :faint)
      %{state | paused: true}
    end
  end

  defp set_alarm_clock(msecs) do
    spawn_link(
			fn() -> # make sure to revive
				:timer.sleep(msecs)
				notify_revive()
			end)
  end

	defp delta(%{when_started: time}) do
		(now() - time) / 1000
	end

	defp type(memory) do
		case memory do
			%Percept{} -> "PERCEPT"
			%Motive{} -> "MOTIVE"
			%Intent{} -> "INTENT"
		end
	end

	defp register_handlers() do
		# Add monitored handlers. Any crash will cause a message to be sent to the CNS.
		:ok = GenEvent.add_mon_handler(@dispatcher, MemoryHandler, [])
    :ok = GenEvent.add_mon_handler(@dispatcher, InternalClockHandler, [])
		:ok = GenEvent.add_mon_handler(@dispatcher, ActuatorsHandler, [])
		:ok = GenEvent.add_mon_handler(@dispatcher, BehaviorsHandler, [])
		:ok = GenEvent.add_mon_handler(@dispatcher, MotivatorsHandler, [])
		:ok = GenEvent.add_mon_handler(@dispatcher, PerceptorsHandler, [])
		:ok = GenEvent.add_mon_handler(@dispatcher, DetectorsHandler, [])
		:ok = GenEvent.add_mon_handler(@dispatcher, ChannelsHandler, [])
	end


end
