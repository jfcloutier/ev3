defmodule Ev3.Device do
  @moduledoc "Data specifying a motor, sensor or LED, 
              and its current state."
  
  defstruct class: nil, path: nil, port: nil, type: nil,
            props: %{}, mock: false
	
end
