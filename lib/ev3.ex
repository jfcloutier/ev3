defmodule Ev3 do
  use Application
  require Logger
	alias Ev3.PerceptorsSupervisor
	alias Ev3.DetectorsSupervisor
	alias Ev3.LegoSensor
	alias Ev3.Perception

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Ev3.Endpoint, []),
			supervisor(Ev3.RobotSupervisor, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: :root_supervisor]
    result = Supervisor.start_link(children, opts)
		start_perceptors()
		start_detectors()
		result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Ev3.Endpoint.config_change(changed, removed)
    :ok
  end

	### Private

	defp start_perceptors() do
		perceptor_defs = Perception.perceptor_defs()
		Enum.map(perceptor_defs, &(PerceptorsSupervisor.start_perceptor(&1)))
	end

	defp start_detectors() do
		LegoSensor.sensors()
		|> Enum.each(fn(sensor) ->
			LegoSensor.senses(sensor)
			|> Enum.each(fn(sense) -> DetectorsSupervisor.start_detector(sensor, sense) end)
		end)		
	end
	


end
