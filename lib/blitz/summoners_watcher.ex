defmodule Blitz.SummonersWatcher do
  use GenServer
  require Logger
  alias Blitz.RiotApiClient

  @interval :timer.minutes(1)

  def start_link(_, args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def inspect do
    GenServer.call(__MODULE__, :inspect)
  end

  def check_summoner_games(last_matches_by_summoner) do
    Enum.reduce(last_matches_by_summoner, last_matches_by_summoner, fn {account_id, prev_match},
                                                                       last_matches_by_summoner ->
      %{"matches" => [last_match]} = RiotApiClient.get_recent_matches(account_id, 1)

      Logger.debug(
        "previous match and last match for #{account_id}: #{prev_match["gameId"]}, #{
          last_match["gameId"]
        }"
      )

      if last_match != prev_match do
        Logger.info("======= New match with id: #{last_match["gameId"]} =======")
        Map.put(last_matches_by_summoner, account_id, last_match)
      else
        last_matches_by_summoner
      end
    end)
  end

  # Callbacks

  def init([last_matches_by_summoner]) do
    Process.send_after(__MODULE__, :poll_summoner, @interval)

    initial_state = %{
      last_matches_by_summoner: last_matches_by_summoner,
      timer_counter: 0
    }

    {:ok, initial_state}
  end

  def handle_info(:poll_summoner, state) do
    if state.timer_counter < @watcher_lifetime do
      Process.send_after(__MODULE__, :poll_summoner, @interval)

      last_matches_by_summoner = check_summoner_games(state.last_matches_by_summoner)

      new_state = %{
        state
        | last_matches_by_summoner: last_matches_by_summoner,
          timer_counter: state.timer_counter + 1
      }

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  def handle_call(:inspect, _from, state) do
    {:reply, state, state}
  end
end
