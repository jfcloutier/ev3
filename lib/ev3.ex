defmodule Ev3 do
	@moduledoc "The Ev3 command and control application"
	
  use Application
  require Logger
	alias Ev3.Endpoint
	alias Ev3.RobotSupervisor

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Endpoint, []),
			supervisor(RobotSupervisor, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: :root_supervisor]
    result = Supervisor.start_link(children, opts)
		RobotSupervisor.start_execution()
		RobotSupervisor.start_perception()
		result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

	@doc "Whether in test mode"
	def testing?() do
		Application.get_env(:ev3, :mock)
	end
	
end
