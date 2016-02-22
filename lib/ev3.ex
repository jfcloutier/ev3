defmodule Ev3 do
	@moduledoc "The Ev3 command and control application"
	
  use Application
  require Logger
	alias Ev3.Endpoint
	alias Ev3.RobotSupervisor
  alias Ev3.CNS
  alias Ev3.Sysfs
  alias Ev3.LegoSensor

  @robot_config "robot_config.exs"
  @poll_runtime_delay 5000

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    if not testing?() and platform() == :brickpi do
      initialize_brickpi_ports()
    end
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
    Process.spawn(fn -> push_runtime_stats() end, [])
		result
  end

  def ports_config() do
      {config, _} = Code.eval_file(@robot_config)
      config
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

  @doc "The runtime platform. Returns one of :brickpi, :ev3, :dev"
  def platform() do
    Application.get_env(:ev3, :platform)
  end

  @doc "Return ERTS runtime stats"
  def runtime_stats() do  # In camelCase for Elm's automatic translation
    stats = mem_stats()
    %{ramFree: stats.mem_free,
      ramUsed:  stats.mem_used,
      swapFree: stats.swap_free,
      swapUsed: stats.swap_used}
  end

  @doc "Loop pushing runtime stats every @poll_runtime_delay seconds"
  def push_runtime_stats() do
    CNS.notify_runtime_stats(runtime_stats())
    :timer.sleep(@poll_runtime_delay)
    push_runtime_stats()
  end

  ### Private

  defp mem_stats() do
    {res, 0} = System.cmd("free", ["-m"])
    [_labels, mem, _buffers, swap, _] = String.split(res, "\n")
    [_, _mem_total, mem_used, mem_free, _, _, _] = String.split(mem) 
	  [_, _swap_total, swap_used, swap_free] = String.split(swap)
    %{mem_free: to_int!(mem_free),
      mem_used: to_int!(mem_used),
      swap_free: to_int!(swap_free),
      swap_used: to_int!(swap_used)}
  end

  defp to_int!(s) do
    {i, _} = Integer.parse(s)
    i
  end

  defp initialize_brickpi_ports() do
    Enum.each(
      ports_config(),
      fn(%{port: port_name, device: device_type}) ->
        if LegoSensor.sensor?(device_type) do # motor ports are preset to NXT
          Sysfs.set_brickpi_port(port_name, device_type)
        end
      end)
  end
  
end
