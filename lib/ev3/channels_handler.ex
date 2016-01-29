defmodule Ev3.ChannelsHandler do
	@moduledoc "Phoenix channels handler"

	use GenEvent
	require Logger
  alias Ev3.Endpoint

	### Callbacks

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, []}
	end

  def handle_event(:faint, state) do
    Endpoint.broadcast!("ev3:runtime", "active_state", %{active: false})
		{:ok, state}
	end

  def handle_event(:revive, state) do
    Endpoint.broadcast!("ev3:runtime", "active_state", %{active: true})
		{:ok, state}
	end

	def handle_event(_event, state) do
    #		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
