defmodule Ev3.Mock.GyroSensor do
  @moduledoc "A mock gyro sensor"

  @behaviour Ev3.Sensing

  def new() do
    %Ev3.Device{class: :sensor,
                path: "/mock/gyro_sensor",
                type: :gyro,
                mock: true}
  end

  ### Sensing

  def senses(_) do
    [:angle, :rotational_speed]
  end

  def read(sensor, sense) do
    case sense do
      :angle -> angle(sensor)
      :rotational_speed -> rotational_speed(sensor)
    end
  end
  
   def nudge(_sensor, sense, value, previous_value) do
    case sense do
      :angle -> nudge_angle(value, previous_value)
      :rotational_speed -> nudge_rotational_speed(value, previous_value)
    end
  end
  
  def pause(_) do
    500
  end

  def sensitivity(_sensor, _sense) do
    nil
  end

  ### Private

  def angle(sensor) do
    value = 50 - :random.uniform(100)
    {value, sensor}
  end

  def nudge_angle(value, previous_value) do
    case previous_value do
      nil -> 32767 - :random.uniform(32767 * 2)
      _ -> value + previous_value |> max(-32767) |> min(32767)
    end
  end

  def rotational_speed(sensor) do
   value = 20 - :random.uniform(40)
    {value, sensor}
  end

  def nudge_rotational_speed(value, previous_value) do
    case previous_value do
      nil -> 440 - :random.uniform(440 * 2)
      _ -> value + previous_value |> max(-440) |> min(440)
    end
  end

end

  
