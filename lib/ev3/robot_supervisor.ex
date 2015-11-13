defmodule Ev3.RobotSupervisor do

	@name __MODULE__
	use Supervisor
	require Logger
	alias Ev3.EventManager
	alias Ev3.Memory
	alias Ev3.PerceptorsSupervisor
  alias Ev3.DetectorsSupervisor
#	alias Ev3.ActuatorsSupervisor
#	alias Ev3.Executor

	### Supervisor Callbacks

	@spec start_link() :: {:ok, pid}
  def start_link() do
		Logger.info("Starting #{@name}")
		{:ok, _pid} = Supervisor.start_link(@name, [], [name: @name])
	end 

	@spec init(any) :: {:ok, tuple}
	def init(_) do
		children = [	
			worker(EventManager, []),
			worker(Memory, []),
			supervisor(PerceptorsSupervisor, []),
			supervisor(DetectorsSupervisor, [])
#			supervisor(ActuatorsSupervisor, []),
#			worker(Executor, [])
					   ]
		opts = [strategy: :one_for_one]
		supervise(children, opts)
	end

end
	
