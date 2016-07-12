defmodule Ev3.PG2Communicator do
	@moduledoc "Communicating with other robots via pg2"

	@behaviour Ev3.Communicating
	use GenServer
	alias Ev3.Percept
	alias Ev3.CNS
  import Ev3.Utils
	require Logger

	@name __MODULE__

	### API

	@doc "Star the communication server"
	def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	@doc "Communicate a percept to the team"
	def communicate(device, info, team) do
		GenServer.cast(@name, {:communicate, device, info, team})
	end


	### CALLBACK

	def init([]) do
		group = Application.get_env(:ev3, :group)
		:pg2.start()
		:pg2.create(group)
		:pg2.join(group, self())
		{:ok, %{group: group}}
	end

	def handle_cast({:communicate, device, info, team}, state =  %{group: group}) do
		members = :pg2.get_members(group)
    beacon_channel = get_beacon_channel()
		members
		|> Enum.each(&(GenServer.cast(&1, {:communication, Node.self(), info, team, beacon_channel, device.props.ttl})))
		Logger.info("COMMUNICATOR  #{inspect Node.self()} communicated #{inspect info} to team #{team} in #{inspect members}")
		{:noreply, state}
	end

	def handle_cast({:communication, node, info, team, beacon_channel, ttl}, state) do # ttl for what's communicated
		if node != Node.self() do
			Logger.info("COMMUNICATOR #{inspect Node.self()} heard #{inspect info} for team #{team} from #{inspect node}")
			percept = Percept.new(about: :heard, value: %{robot: node, team: team, info: info, beacon_channel: beacon_channel})
			CNS.notify_perceived(%{percept |
														 ttl: ttl,
														 source: @name})
		end
		{:noreply, state}
	end		

end
