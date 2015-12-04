defmodule Ev3.MotivatorsSupervisor do
	@moduledoc "Supervisor of dynamically started motivators"

	@name __MODULE__
	use Supervisor
	alias Ev3.Motivator
	require Logger

	@doc "Start the motivators supervisor, linking it to its parent supervisor"
	def start_link() do
		Logger.info("Starting #{@name}")
		Supervisor.start_link(@name, [], [name: @name])
	end

	@doc "Start a motivator on a configuration, linking it to this supervisor"
	def start_motivator(motivator_conf) do
		{:ok, _pid} = Supervisor.start_child(@name, [motivator_conf])
	end

	### Callbacks

	def init(_) do
		children = [worker(Motivator, [], restart: :permanent)]
		supervise(children, strategy: :simple_one_for_one)
	end

end
