defmodule Ev3.Device do
  @moduledoc "Data specifying a motor or sensor."
  defstruct class: nil, path: nil, port: nil, type: nil, props: %{}, mock: false
	
end
