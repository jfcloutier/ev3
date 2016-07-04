defmodule Ev3.RobotSupervisor do

	use Supervisor
	require Logger
	alias Ev3.{CNS, Memory, PerceptorsSupervisor, DetectorsSupervisor, LegoSensor, LegoMotor, Perception, MotivatorsSupervisor, BehaviorsSupervisor, ActuatorsSupervisor, Motivation, Behaviors, Actuation, InternalClock, PG2Communicator}

	@name __MODULE__

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
      worker(InternalClock, []),
			worker(PG2Communicator, []),
			supervisor(ActuatorsSupervisor, []),
			supervisor(BehaviorsSupervisor, []),
			supervisor(MotivatorsSupervisor, []),
			supervisor(DetectorsSupervisor, []),
			supervisor(PerceptorsSupervisor, [])
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
		sensing_devices = LegoSensor.sensors() ++ LegoMotor.motors()
    used_senses = all_used_senses()
		Enum.each(sensing_devices, &(DetectorsSupervisor.start_detector(&1, used_senses)))		
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

  defp all_used_senses() do
    MapSet.new(
      Perception.used_senses() ++ Motivation.used_senses() ++ Behaviors.used_senses())
    |> MapSet.to_list()
  end
  
end
	
