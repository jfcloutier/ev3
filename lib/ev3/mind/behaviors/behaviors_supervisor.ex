defmodule Ev3.BehaviorsSupervisor do
	@moduledoc "Supervisor of dynamically started behaviors"

	@name __MODULE__
	use Supervisor
	alias Ev3.Behavior
	require Logger

	@doc "Start the behaviors supervisor, linking it to its parent supervisor"
	def start_link() do
		Logger.info("Starting #{@name}")
		Supervisor.start_link(@name, [], [name: @name])
	end

	@doc "Start a behavior on a configuration, linking it to this supervisor"
	def start_behavior(behavior_conf) do
		{:ok, _pid} = Supervisor.start_child(@name, [behavior_conf])
	end

	### Callbacks

	def init(_) do
		children = [worker(Behavior, [], restart: :permanent)]
		supervise(children, strategy: :simple_one_for_one)
	end

end
