defmodule Ev3.LegoCommunication do
	@moduledoc "Lego inter-robot communication"

	require Logger
	alias Ev3.Device

	@doc "Get all available communicator"
  def communicators() do
		[:pg2]
		|> Enum.map(&(init_communicator("#{&1}", module_for(&1))))
	end

	@doc"Find a communicator device by type"
	def communicator(type: type) do
		communicators()
		|> Enum.find(&(type(&1) == type))
	end

	  @doc "Get the type of the communicator device"
  def type(communicator) do
    communicator.type
  end

  @doc "Execute a cound command"
  def execute_command(communicator, command, params) do
    apply(Ev3.LegoCommunication, command, [communicator | params])
    communicator
  end

	@doc "Communicate through a communicator"
	def communicate(communicator_device, %{info: info, team: team}) do
		apply(communicator_device.path, :communicate, [communicator_device, info, team])
	end

	### Private

  defp init_communicator(type, module) do
    %Device{class: :comm,
            path: module,
            port: nil,
            type: type
           }
  end

	defp module_for(type) do
		case type do
			:pg2 -> Ev3.PG2Communicator
		  other ->
				error = "Unknown type #{type} of communicator"
				Logger.error(error)
				raise error
		end
	end
	
end
