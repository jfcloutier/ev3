defmodule Ev3.PerceptorsSupervisor do
	@moduledoc "Supervisor of dynamically started perceptors"

	@name __MODULE__
	use Supervisor
	alias Ev3.Perceptor
	require Logger

	@doc "Start the perceptors supervisor, linking it to its parent supervisor"
	def start_link() do
		Logger.info("Starting #{@name}")
		Supervisor.start_link(@name, [], [name: @name])
	end

	@doc "Start a perceptor on a configuration, linking it to this supervisor"
	def start_perceptor(perceptor_conf) do
		{:ok, _pid} = Supervisor.start_child(@name, [perceptor_conf])
	end

	### Callbacks

	def init(_) do
		children = [worker(Perceptor, [], restart: :permanent)]
		supervise(children, strategy: :simple_one_for_one)
	end

end
