defmodule Ev3.ChannelsHandler do
	@moduledoc "Phoenix channels handler"

	use GenEvent
	require Logger
  alias Ev3.Endpoint
  alias Ev3.Percept
  alias Ev3.Motive
  alias Ev3.Memory

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

  def handle_event({:perceived, %Percept{about: about, value: value}}, state) do
		Endpoint.broadcast!("ev3:runtime", "percept", %{about: stringify(about), value: stringify(value)})
		{:ok, state}
	end

	def handle_event({:motivated, %Motive{about: about, value: value}}, state) do
		Endpoint.broadcast!("ev3:runtime", "motive", %{about: stringify(about), on: value == :on, inhibited: Memory.inhibited?(about)})
		{:ok, state}
	end

  def handle_event({:behavior_started, name} ,state) do
    Endpoint.broadcast!("ev3:runtime", "behavior", %{name: name, event: "started", value: ""})
    {:ok, state}
  end
  
  def handle_event({:behavior_stopped, name} ,state) do
    Endpoint.broadcast!("ev3:runtime", "behavior", %{name: name, event: "stopped", value: ""})
    {:ok, state}
  end
  
  def handle_event({:overwhelmed, :behavior, name} ,state) do
    Endpoint.broadcast!("ev3:runtime", "behavior", %{name: name, event: "overwhelmed", value: ""})
    {:ok, state}
  end
  
  def handle_event({:behavior_inhibited, name} ,state) do
    Endpoint.broadcast!("ev3:runtime", "behavior", %{name: name, event: "inhibited", value: ""})
    {:ok, state}
  end
  
  def handle_event({:behavior_transited, name, to_state} ,state) do
    Endpoint.broadcast!("ev3:runtime", "behavior", %{name: name, event: "transited", value: to_state})
    {:ok, state}
  end
  
	def handle_event(_event, state) do
    #		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

  ### PRIVATE

  defp stringify(x) do
    case x do
      s when is_binary(s) -> s
      y when is_atom(y) or is_number(y) -> to_string(y)
      {a, v1, nil} -> "{#{stringify(a)}, #{stringify(v1)}}"
      {a, v1, v2} -> "{#{stringify(a)}, #{stringify(v1)}, #{stringify(v2)}}"
      {a, v} -> "{#{stringify(a)}, #{stringify(v)}}"
      z -> "#{inspect z}"
    end
  end

end
