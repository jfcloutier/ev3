defmodule Ev3.RobotSupervisor do

	@name __MODULE__
	use Supervisor
	require Logger
	alias Ev3.CNS
	alias Ev3.Memory
	alias Ev3.PerceptorsSupervisor
  alias Ev3.DetectorsSupervisor
	alias Ev3.LegoSensor
	alias Ev3.LegoMotor
	alias Ev3.Perception
	alias Ev3.MotivatorsSupervisor
	alias Ev3.BehaviorsSupervisor
	alias Ev3.ActuatorsSupervisor
	alias Ev3.Motivation
	alias Ev3.Behaviors
	alias Ev3.Actuation

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
			worker(CNS, []),
			worker(Memory, []),
			supervisor(PerceptorsSupervisor, []),
			supervisor(DetectorsSupervisor, []),
			supervisor(MotivatorsSupervisor, []),
			supervisor(BehaviorsSupervisor, []),
			supervisor(ActuatorsSupervisor, [])
					   ]
		opts = [strategy: :one_for_one]
		supervise(children, opts)
	end

	@doc "Start the robot's perception"
	def start_perception() do
		Logger.info("Starting perception")
		start_perceptors()
		start_detectors()
	end

	@doc "Start the robot's execution"
	def start_execution() do
		Logger.info("Starting execution")
		start_actuators()
		start_behaviors()
		start_motivators()
	end

	### Private

	defp start_perceptors() do
		Perception.perceptor_configs()
		|> Enum.each(&(PerceptorsSupervisor.start_perceptor(&1)))
	end

	defp start_detectors() do
		devices = LegoSensor.sensors() ++ LegoMotor.motors()
		Enum.each(devices, &(DetectorsSupervisor.start_detector(&1)))		
	end

  defp start_motivators() do
		Motivation.motivator_configs()
		|> Enum.each(&(MotivatorsSupervisor.start_motivator(&1)))
	end

  defp start_behaviors() do
		Behaviors.behavior_configs()
		|> Enum.each(&(BehaviorsSupervisor.start_behavior(&1)))
	end

  defp start_actuators() do
		Actuation.actuator_configs()
		|> Enum.each(&(ActuatorsSupervisor.start_actuator(&1)))
	end

end
	
