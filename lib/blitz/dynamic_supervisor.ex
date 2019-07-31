defmodule Blitz.DynamicSupervisor do
  use DynamicSupervisor

  alias Blitz.SummonersWatcher

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_watching(last_matches_by_summoner) do
    DynamicSupervisor.start_child(__MODULE__, {SummonersWatcher, [last_matches_by_summoner]})
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end
end
