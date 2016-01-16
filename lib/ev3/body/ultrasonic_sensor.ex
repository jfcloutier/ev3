defmodule Ev3.UltrasonicSensor do
  @moduledoc "Ultrasonic sensor"
  @behaviour Ev3.Sensing

  import Ev3.Sysfs
  alias Ev3.LegoSensor

  @distance_cm "US-DIST-CM"

 	### Ev3.Sensing behaviour

  def senses(_) do
    [:distance_cm]
  end

  def read(sensor, sense) do
    do_read(sensor, sense)
  end

  defp do_read(sensor, :distance_cm) do
    distance_cm(sensor)
  end

  def pause(_) do
    500
  end

  def sensitivity(_sensor, :distance_cm) do
    1
  end

  ####

  @doc "Get distance in centimeters - 0 to 2550"
  def distance_cm(sensor) do
    updated_sensor = set_distance_cm_mode(sensor)
    value = get_attribute(updated_sensor, "value0", :integer)
    {value, updated_sensor}
  end

  defp set_distance_cm_mode(sensor) do
    LegoSensor.set_mode(sensor, @distance_cm)
  end

end
