defmodule Ev3.CNS do
	@moduledoc "An event manager that acts as the robot's central nervous system"

	alias Ev3.PerceptorsHandler
	alias Ev3.MemoryHandler
  alias Ev3.ExecutiveHandler
	require Logger

  @name __MODULE__

	@doc "Start the event manager and register the event handlers"
	def start_link() do
    Logger.info("Starting #{@name}")
		{:ok, pid} = GenEvent.start_link(name: @name)
    register_handlers()
    {:ok, pid}
  end

	@doc "Handle notification of a new perception"
	def notify_perceived(percept) do
		# Logger.debug("#{inspect percept.sense} = #{inspect percept.value}")
		GenEvent.notify(@name, {:perceived, percept})
	end

	@doc "Handle notification of an new or extended memory change"
	def notify_memorized(memorization, percept) do
		Logger.info("===> #{memorization}: #{inspect percept.sense} = #{inspect percept.value}")
    GenEvent.notify(@name, {:memorized, memorization, percept})
	end

	### Private

	defp register_handlers() do
		GenEvent.add_handler(@name, MemoryHandler, [])
		GenEvent.add_handler(@name, PerceptorsHandler, [])
	  GenEvent.add_handler(@name, ExecutiveHandler, [])
	end

end
