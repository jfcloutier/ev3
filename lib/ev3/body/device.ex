defmodule Ev3.Device do
  @moduledoc "Data specifying a motor, sensor or LED."
  
  @doc """
  class - :sensor, :motor or :led
  path - sys file path
  port - the name of the port the device is connected to
  type - the type of motor, sensor or led
  props - idiosyncratic properties of the device
  mock - whether this is a mock device or a real one
  """
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

	#### TODO
	
  def mode(device_type, :nxt) do
    case device_type do
      :infrared -> "nxt-i2c"
      :touch -> "nxt-analog" # works
      :gyro -> "nxt-analog"
   #   :color -> "???" # NOT SUPPORTED but EV3 Color sensor works on brickpi
      :ultrasonic -> "nxt-i2c"
      :large -> "tacho-motor" # automatically detected
   #   :medium -> "tacho-motor" # does not exist
    end
  end
    
  def device_code(device_type, :nxt) do
    case device_type do
      :infrared -> "ht-nxt-ir-receiver 0x01" # HiTechnic NXT IRReceiver Sensor
      :touch -> "lego-nxt-touch"
      :gyro -> "ht-nxt-gyro"
    #  :color -> "???" # NXT Color sensor not supported
      :ultrasonic -> "lego-nxt-us"
      :large -> "lego-ev3-l-motor"  # automatically detected as Lego EV3 Large motors
   #   :medium -> "lego-ev3-m-motor" # does not exist
    end
  end

  def self_loading_on_brickpi?(device_type) do
    device_type == :touch
  end
	
end
