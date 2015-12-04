defmodule Ev3.Utils do
	@moduledoc "Utility functions"

	@doc "The time now in msecs"
	def now() do
		{mega, secs, micro} = :os.timestamp()
		((mega * 1_000_000) + secs) * 1000 + div(micro, 1000)
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

end
