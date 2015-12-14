defmodule Ev3.Intent do
	@moduledoc "A struct for an intent (a unit of action)"

	import Ev3.Utils

	# A "memorizable" - must have about, since and value fields

	defstruct about: nil, since: nil, source: nil, value: nil, strong: false

	@doc "Create an intent"
	def new(about: about, value: params) do
		%Ev3.Intent{about: about,
								 since: now(),
								 value: params}
	end

	def new_strong(about: about, value: params) do
		%Ev3.Intent{about: about,
								since: now(),
								value: params,
								strong: true}
	end

end
