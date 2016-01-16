defmodule Ev3.SoundSpec do
  @moduledoc "Struct for sound player specifications"

  # properties name and props are required to be a *Spec
  defstruct name: nil, type: nil, props: %{volume: :normal, speed: :normal} #matching device has its props augmented by the spec's props

  @doc "Does a sound player match a spec?"
  def matches?(%Ev3.SoundSpec{} = sound_spec, device) do
    device.class == :sound and device.type == "#{sound_spec.type}"
  end

end
