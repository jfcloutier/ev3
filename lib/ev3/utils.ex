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

  @doc "Get personal setting string passed in command line"
  def get_personal(variable, default_value) do
    get_personal(variable, :string, default_value)
  end

  @doc "Get typed personal setting passed in command line invocation"
  def get_personal(variable, type, default_value) do
    val = case System.get_env(@personal) do
      nil ->
        default_value
      string ->
        extract_personal(string, variable, default_value)
          end
    case type do
      :string -> val
      :integer ->
        case Integer.parse(val) do
          {value, _} -> value
          :error -> default_value
        end
      :float ->
        case Float.parse(val) do
          {value, _} -> value
          :error -> default_value
        end
    end
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
