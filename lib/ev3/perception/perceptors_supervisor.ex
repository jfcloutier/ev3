defmodule Ev3.PerceptorsSupervisor do
	@docmodule "Supervisor of dynamically started perceptors"

	@name __MODULE__
	use Supervisor
	alias Ev3.Perceptor
	require Logger

	def start_link() do
		Logger.info("Starting #{@name}")
		Supervisor.start_link(@name, [], [name: @name])
	end

	def init(_) do
		children = [worker(Perceptor, [], restart: :permanent)]
		supervise(children, strategy: :simple_one_for_one)
	end

	def start_perceptor(perceptor_def) do
		{:ok, _pid} = Supervisor.start_child(@name, [perceptor_def])
	end
	
end
