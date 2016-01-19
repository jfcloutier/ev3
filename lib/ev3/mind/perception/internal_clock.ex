defmodule Ev3.InternalClock do
  @moduledoc "An internal clock"

  require Logger
  alias Ev3.Percept
  alias Ev3.CNS
  import Ev3.Utils

  @name __MODULE__
  @down_time 2500

  def start_link() do
    {:ok, pid} = Agent.start_link(
      fn() ->
        %{responsive: true, tock: now()}
      end,
      [name: @name]
    )
		Logger.info("#{@name} started")
    {:ok, pid}
  end

  def tick() do
    Agent.cast(
      @name,
      fn(state) ->
        if state.responsive do
          tock = now()
          Percept.new_transient(about: :time_elapsed, value: state.tock - tock)
          |> CNS.notify_perceived()
          Logger.info("tick")
          %{state | tock: tock}
        else
          state
        end
      end)
  end

    @doc "Stop the detection of percepts"
  def actuator_overwhelmed() do
		Agent.update(
			@name,
			fn(state) ->
        if state.responsive do
				  spawn_link(
					  fn() -> # make sure to reactivate
						  :timer.sleep(@down_time)
						  reactivate()
					  end)
				  %{state | responsive: false}
        else
          state
        end
			end)
  end

  @doc "Resume producing percepts"
	def reactivate() do
		Agent.update(
			@name,
			fn(state) ->
				%{state | responsive: true}
			end)
	end

end
