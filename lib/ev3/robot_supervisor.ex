defmodule Ev3.RobotSupervisor do

	@name __MODULE__
	use Supervisor
	require Logger
	alias Ev3.EventManager
	alias Ev3.Memory
	alias Ev3.PerceptorsSupervisor
  alias Ev3.DetectorsSupervisor
	alias Ev3.LegoSensor
	alias Ev3.Perception
#	alias Ev3.ActuatorsSupervisor
#	alias Ev3.Executive

	### Supervisor Callbacks

	@spec start_link() :: {:ok, pid}
	@doc "Start the robot supervisor, linking it to its parent supervisor"
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
#			worker(Executive, [])
					   ]
		opts = [strategy: :one_for_one]
		supervise(children, opts)
	end

	@doc "Start the robot's perception"
	def start_perception() do
		start_perceptors()
		start_detectors()
	end

	@doc "STart the robot's execution"
	def start_execution() do
		# TODO
	end

	### Private

	defp start_perceptors() do
		Perception.perceptor_configs()
		|> Enum.each(&(PerceptorsSupervisor.start_perceptor(&1)))
	end

	defp start_detectors() do
		LegoSensor.sensors()
		|> Enum.each(&(DetectorsSupervisor.start_detector(&1)))		
	end

end
	
