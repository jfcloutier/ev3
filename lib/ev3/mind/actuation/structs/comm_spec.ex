defmodule Ev3.CommSpec do
  @moduledoc "Struct for communicator specifications"

  # properties name and props are required to be a *Spec
  defstruct name: nil, type: nil, props: %{ttl: {30, :secs}} #matching device has its props augmented by the spec's props

  @doc "Does a communicator match a spec?"
  def matches?(%Ev3.CommSpec{type: type} = comm_spec, device) do
    device.class == :comm and device.type == "#{type}"
  end

end
