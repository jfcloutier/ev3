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

  @doc "Create a strong intent"
	def new_strong(about: about, value: params) do
		%Ev3.Intent{about: about,
								 since: now(),
								 value: params,
                 strong: true}
	end



  @doc "The age of an intent"
  def age(intent) do
    now() - intent.since
  end

  @doc "Describe the strength of an intent"
  def strength(intent) do
    if intent.strong, do: :strong, else: :weak
  end
  
end
