defmodule Ev3.CNS do
	@moduledoc "A resilient event manager that acts as the robot's central nervous system"

  alias Ev3.DetectorsHandler
	alias Ev3.PerceptorsHandler
	alias Ev3.MemoryHandler
  alias Ev3.InternalClockHandler
	alias Ev3.ActuatorsHandler
	alias Ev3.BehaviorsHandler
	alias Ev3.MotivatorsHandler
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
	def notify_realized(intent) do
		GenServer.cast(@name, {:notify_realized, intent})
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
		GenServer.cast(@name, {:overwhelmed, component_type, actuator_name})
	end

  @doc "Revive from fainting"
  def notify_revive() do
    GenServer.cast(@name, :notify_revive)
  end

	### Callbacks

	def init(_) do
		{:ok, _pid} = GenEvent.start_link(name: @dispatcher)
    register_handlers()
    {:ok, %{when_started: now(), overwhelmed: false}}
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
	
	def handle_cast({:notify_realized, intent}, state) do
	  Logger.info("Intent #{Intent.strength(intent)} realized #{intent.about} #{inspect intent.value} at #{delta(state)}")
		GenEvent.notify(@dispatcher, {:realized, intent})
		{:noreply, state}
	end
	
	def handle_cast({:notify_memorized, memorization, data}, state) do
		Logger.debug("Memorized ===> #{memorization} #{inspect type(data)} #{inspect data.about} = #{inspect data.value} at #{delta(state)}")
		GenEvent.notify(@dispatcher, {:memorized, memorization, data})
		{:noreply, state}
	end

	def handle_cast({:overwhelmed, component_type, name}, state) do
    Logger.info("OVERWHELMED - #{component_type} #{name} at #{delta(state)}")
    if not state.overwhelmed do
      Logger.info("FAINTING at #{delta(state)}")
		  GenEvent.notify(@dispatcher, :faint)
			spawn_link(
				fn() -> # make sure to revive
					:timer.sleep(@faint_duration)
					notify_revive()
				end)
		  {:noreply, %{state | overwhelmed: true}}
    else
      {:noreply, state}
    end
	end

  def handle_cast(:notify_revive, state) do
    Logger.info("REVIVING at #{delta(state)}")
    GenEvent.notify(@dispatcher, :revive)
    {:noreply, %{state | overwhelmed: false}}
  end

	def handle_info({:gen_event_EXIT, crashed_handler, error}, state) do
		Logger.error("#{crashed_handler} crashed. Restarting #{__MODULE__}.")		
		{:stop, {:handler_died, error}, state}
	end


	### Private

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
	end


end
