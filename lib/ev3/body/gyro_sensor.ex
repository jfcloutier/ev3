defmodule Ev3.GyroSensor do
  @moduledoc "Gyro sensor"
  @behaviour Ev3.Sensing

  import Ev3.Sysfs
  alias Ev3.LegoSensor

  @angle "GYRO-ANG"
  @rotational_speed "GYRO-RATE"

  ### Ev3.Sensing behaviour

  def senses(_) do
    [:angle, :rotational_speed]
  end

  def read(sensor, sense) do
		{_, updated_sensor} = do_read(sensor, sense)
		do_read(updated_sensor, sense) # double read seems necessary after a mode change
  end

  def do_read(sensor, :angle) do
    angle(sensor)
  end

  def do_read(sensor, :rotational_speed) do
    rotational_speed(sensor)
  end

  def pause(_) do
    500
  end

  def sensitivity(_sensor, sense) do
    case (sense) do
      :angle -> 5
      :rotational_speed -> 2
    end
  end

  ####

  def angle(sensor) do
    updated_sensor = set_angle_mode(sensor)
    value = get_attribute(updated_sensor, "value0", :integer)
    {value, updated_sensor}
  end

  def rotational_speed(sensor) do
    updated_sensor = set_rotational_speed_mode(sensor)
    value = get_attribute(updated_sensor, "value0", :integer)
    {value, updated_sensor}
  end

### PRIVATE

  def set_angle_mode(sensor) do
    LegoSensor.set_mode(sensor, @angle)
  end

  def set_rotational_speed_mode(sensor) do
    LegoSensor.set_mode(sensor, @rotational_speed)
  end

end

  
