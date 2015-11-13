defmodule Ev3.EventManager do
	@moduledoc "An event manager acting as the central nervous system"

	alias Ev3.PerceptorsHandler
	alias Ev3.MemoryHandler
	require Logger

  @name __MODULE__

	@doc "Start the event manager and register the event handlers"
	def start_link() do
    Logger.info("Starting #{@name}")
		{:ok, pid} = GenEvent.start_link(name: @name)
    register_handlers()
    {:ok, pid}
  end

	@doc "Handle notification of a percept"
	def notify_percept(percept) do
		Logger.debug("Notified of #{inspect percept}")
		GenEvent.notify(@name, {:percept, percept})
	end

	### Private

	defp register_handlers() do
		GenEvent.add_handler(@name, MemoryHandler, [])
		GenEvent.add_handler(@name, PerceptorsHandler, [])
		# GenEvent.addHandler(@name, ExecutorHandler, [])
	end

end
