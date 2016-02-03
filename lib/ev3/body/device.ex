defmodule Ev3.Device do
  @moduledoc "Data specifying a motor, sensor or LED, 
              and its current state."
  
  defstruct class: nil, path: nil, port: nil, type: nil, props: %{}, mock: false
        
  def mode(device_type) do
    case device_type do
      :infrared -> "ev3-uart"
      :touch -> "ev3-analog"
      :gyro -> "ev3-uart"
      :color -> "ev3-uart"
      :ultrasonic -> "ev3-uart"
      :large -> "tacho-motor"
      :medium -> "tacho-motor"
    end
  end
    
  def device_code(device_type) do
    case device_type do
      :infrared -> "lego-ev3-ir"
      :touch -> "lego-ev3-touch"
      :gyro -> "lego-ev3-gyro"
      :color -> "lego-ev3-color"
      :ultrasonic -> "lego-ev3-us"
      :large -> "lego-ev3-l-motor"
      :medium -> "lego-ev3-m-motor"
    end
  end

  def self_loading_on_brickpi?(device_type) do
    device_type == :touch
  end
	
end
