defmodule Ev3.Mock.GyroSensor do
  @moduledoc "A mock gyro sensor"

  @behaviour Ev3.Sensing

  def new() do
    %Ev3.Device{class: :sensor,
                path: "/mock/gyro_sensor",
                type: :gyro}
  end

  ### Sensing

  def senses(_) do
    [:angle, :rotational_speed]
  end

  def read(sensor, :angle) do
    angle(sensor)
  end

  def read(sensor, :rotational_speed) do
    rotational_speed(sensor)
  end

  def pause(_) do
    500
  end

  def sensitivity(_sensor, _sense) do
    nil
  end

  ### Private

  def angle(sensor) do
    value = 32767 - :random.uniform(32767 * 2)
    {value, sensor}
  end

  def rotational_speed(sensor) do
   value = 440 - :random.uniform(440 * 2)
    {value, sensor}
  end

end

  
