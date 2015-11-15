defmodule Ev3.Memory do
	@docmodule "The memory of percepts"

	use GenServer
	alias Ev3.Percept
	alias Ev3.EventManager
	import Ev3.PerceptionUtils
  require Logger

  @name __MODULE__
	@forget_pause 10000 # clear expired precepts every 10 secs

  ### API
	
	@doc "Start the library server"
	def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	@doc "Remember a percept"
	def store(percept) do
		GenServer.cast(@name, {:store, percept})
	end

	@doc "Recall all percepts from any of given senses in a time window until now"
	def recall(senses, window_width) do
		GenServer.call(@name, {:recall, senses, window_width})
	end

	### CALLBACKS

	def init(_) do
    Logger.debug("Init #{@name}")
    spawn_link(fn() -> forget()	end)
		{:ok, %{}}
	end

	# forget all expired percepts every second
	defp forget() do
			:timer.sleep(@forget_pause)
			send(@name, :forget)
			forget()
	end

	def handle_info(:forget, state) do
		new_state = forget_expired(state)
		{:noreply, new_state}
	end

	def handle_cast({:store, percept}, state) do
		percepts = Map.get(state, percept.sense, [])
		new_percepts =  update_percepts(percept, percepts)
		new_state = Map.put(state, percept.sense, new_percepts)
		{:noreply, new_state}
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
		EventManager.notify_memorized(:new, percept)
		[percept]
	end

	defp update_percepts(percept, [previous | others]) do
		if not change_felt?(percept, previous) do
			extended_percept = %Percept{previous | until: percept.since}
			EventManager.notify_memorized(:extended, extended_percept)
			[extended_percept | others]
		else
			EventManager.notify_memorized(:new, percept)
			[percept, previous | others]
		end
	end

	# Both percepts are assumed to be from the same sense, thus comparable
	defp change_felt?(percept, previous) do
		cond do
			percept.resolution == nil or previous.resolution == nil ->
				percept.value != previous.value
			not is_number(percept.value) or not is_number(previous.value) ->
			  percept.value != previous.value
			true ->
				resolution = max(percept.resolution, previous.resolution)
				abs(percept.value - previous.value) >= resolution
		end
	end

	defp forget_expired(state) do
		msecs = now()
		Enum.reduce(Map.keys(state),
										%{},
			fn(sense, acc) ->
				unexpired = Enum.take_while(
					Map.get(state, sense),
					fn(percept) ->
						if percept.retain == nil or (percept.until + percept.retain) > msecs do
							true
						else
							Logger.debug("Forgot #{inspect percept.sense} = #{inspect percept.value} after #{div(msecs - percept.until, 1000)} secs")
							false
						end
					end)
				Map.put_new(acc, sense, unexpired)
			end)
	end

end
