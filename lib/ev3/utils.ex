defmodule Ev3.Utils do
	@moduledoc "Utility functions"

  @personal "personal"

	@doc "The time now in msecs"
	def now() do
		{mega, secs, micro} = :os.timestamp()
		((mega * 1_000_000) + secs) * 1000 + div(micro, 1000)
	end

  @doc "Supported time units"
  def units() do
    [:msecs, :secs, :mins, :hours]
  end

	@doc "Convert a duration to msecs"
	def convert_to_msecs(nil), do: nil
	def convert_to_msecs({count, unit}) do
		case unit do
			:msecs -> count
			:secs -> count * 1000
			:mins -> count * 1000 * 60
			:hours -> count * 1000 * 60 * 60
		end
	end

	def get_voice() do
		get_robot_setting(:voice, "en")
	end

	def get_beacon_channel() do
		get_robot_setting(:beacon_channel, 0)
  end

  @doc "Get personal setting "
  def get_robot_setting(setting, default_value) do
    settings = Application.get_env(:ev3, :robot)
		Keyword.get(settings, setting, default_value)
  end


  ### PRIVATE

  defp extract_personal(string, variable, default_value) do
    settings = String.split(string, ",")
    pairs = Enum.map(settings, &(String.split(&1, "=")))
    case Enum.find(pairs, fn([key, _value]) -> key == variable end) do
      nil ->
        default_value
      [_, value] ->
        value
    end
  end

end
