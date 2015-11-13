defmodule Ev3.Memory do
	@docmodule "The memory of percepts"

	use GenServer
	alias Ev3.Percept
	import Ev3.PerceptionUtils
  require Logger

  @name __MODULE__

  ### API
	
	@doc "Start the library server"
	def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	@doc "Remember a percept"
	def store(percept) do
		GenServer.call(@name, {:store, percept})
	end

	def recall(senses, window_width) do
		GenServer.recall(@name, {:recall, senses, window_width})
	end

	### CALLBACKS

	def init(_) do
    spawn_link(fn() -> forget()	end)
		{:ok, %{}}
	end

	# forget all expired percepts every second
	defp forget() do
			:timer.sleep(1000)
			send(@name, :forget)
			forget()
	end

	def handle_info(:forget, state) do
		new_state = forget_expired(state)
		{:noreply, new_state}
	end

	def handle_cast({:store, percept}, state) do
		percepts = Map.get(state, percept.sense, [])
		new_state = Map.put(state, percept.sense, update_percepts(percept, percepts))
		{:reply, new_state}
	end

	def handle_call({:recall, senses, window_width}, _from, state) do
		msecs = now()
		window =
		  Enum.reduce(
				senses,
				[],
        fn(sense, acc) ->
					percepts = Enum.take_while(
						Map.get(state, sense, []),
						fn(percept) ->
							window_width == nil or percept.until > (msecs - window_width)
						end)
					acc ++ percepts	
				end)		
		{:reply, window, state}
	end

	### PRIVATE

	defp update_percepts(percept, []) do
		[percept]
	end

	defp update_percepts(percept, [previous | others]) do
		if Percept.same?(percept, previous) do
			[%Percept{previous | until: percept.since} | others]
		else
			[percept, previous | others]
		end
	end

	defp forget_expired(state) do
		msecs = now()
		Enum.reduce(Map.keys(state),
										%{},
			fn(sense, acc) ->
				unexpired = Enum.take_while(
					Map.get(state, sense),
					fn(percept) -> percept.retain == nil or (percept.until + percept.retain) > msecs end)
				Map.put_new(acc, sense, unexpired)
			end)
	end

end
