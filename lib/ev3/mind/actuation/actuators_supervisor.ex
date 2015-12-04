defmodule Ev3.ActuatorsSupervisor do
	@moduledoc "Supervisor of dynamically started actuators"

	@name __MODULE__
	use Supervisor
	alias Ev3.Actuator
	require Logger

	@doc "Start the actuators supervisor, linking it to its parent supervisor"
	def start_link() do
		Logger.info("Starting #{@name}")
		Supervisor.start_link(@name, [], [name: @name])
	end

	@doc "Start an actuator on a configuration, linking it to this supervisor"
	def start_actuator(actuator_conf) do
		{:ok, _pid} = Supervisor.start_child(@name, [actuator_conf])
	end

	### Callbacks

	def init(_) do
		children = [worker(Actuator, [], restart: :permanent)]
		supervise(children, strategy: :simple_one_for_one)
	end

end
