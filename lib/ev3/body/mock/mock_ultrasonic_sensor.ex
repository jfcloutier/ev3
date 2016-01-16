defmodule Ev3.Mock.UltrasonicSensor do
  @moduledoc "A mock ultrasonic sensor"

  @behaviour Ev3.Sensing

  def new() do
    %Ev3.Device{class: :sensor,
                path: "/mock/ultrasonic_sensor",
                type: :ultrasonic}
  end

  ### Sensing

  def senses(_) do
    [:distance_cm]
  end

  def read(sensor, :distance_cm) do
    distance_cm(sensor)
  end

  def pause(_) do
    500
  end

  def sensitivity(_sensor, _sense) do
    nil
  end

  ### Private

  defp distance_cm(sensor) do
    value = :random.uniform(2550)
    {value, sensor}
  end

end
