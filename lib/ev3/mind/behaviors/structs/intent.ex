defmodule Ev3.Intent do
	@moduledoc "A struct for an intent (a unit of intention to act)"

	import Ev3.Utils

  @doc """
       about: The nature of the intent
       value: The measure of the intent (a number, atom...)
       since: When the intent was created
       source: The source of the intent (the name of a behavior)
       strong: If true, the intent takes longer to become stale
       """
	defstruct about: nil, value: nil, since: nil, source: nil, strong: false

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

  	# A "memorable" - must have about, since and value fields

  
end
