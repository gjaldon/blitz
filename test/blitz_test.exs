defmodule BlitzTest do
  use ExUnit.Case
  alias Blitz.SummonersWatcher

  import Tesla.Mock

  defmodule Counter do
    use Agent

    def start_link(initial_value) do
      Agent.start_link(fn -> initial_value end, name: __MODULE__)
    end

    def value do
      Agent.get(__MODULE__, & &1)
    end

    def increment do
      Agent.update(__MODULE__, &(&1 + 1))
    end
  end

  setup do
    Counter.start_link(0)

    mock_global(fn
      %{method: :get, url: "https://test.com/lol/summoner/v4/summoners/by-name/RiotSchmick"} ->
        %Tesla.Env{
          status: 200,
          body: %{
            "id" => "niDY1YDqqLcAihe0xkE8zt50udStXwfYlbxPM1CvdgNe",
            "accountId" => "MM8hDMEiN5k_ehzSTRf1NLlsvJmR0Uz7tATLxEzx2zVCig",
            "puuid" =>
              "M1Xe6msBufXnKD1FZRtpMfaQw_J7odkDddc4VioRsbmFdx2BYYgRanNlibX1buWH8InLjU9GiMYsDw",
            "name" => "RiotSchmick",
            "profileIconId" => 4213,
            "revisionDate" => 1_564_548_545_000,
            "summonerLevel" => 148
          }
        }

      %{
        method: :get,
        url:
          "https://test.com/lol/match/v4/matchlists/by-account/MM8hDMEiN5k_ehzSTRf1NLlsvJmR0Uz7tATLxEzx2zVCig"
      } ->
        %Tesla.Env{
          status: 200,
          body: %{
            "matches" => [
              %{
                "platformId" => "NA1",
                "gameId" => 3_109_554_735,
                "champion" => 34,
                "queue" => 450,
                "season" => 13,
                "timestamp" => 1_564_461_724_971,
                "role" => "DUO_SUPPORT",
                "lane" => "NONE"
              }
            ]
          }
        }

      %{
        method: :get,
        url:
          "https://test.com/lol/match/v4/matchlists/by-account/pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE"
      } ->
        Counter.increment()

        game_id =
          if Counter.value() > 3 do
            1337
          else
            3_109_554_735
          end

        %Tesla.Env{
          status: 200,
          body: %{
            "matches" => [
              %{
                "platformId" => "NA1",
                "gameId" => game_id,
                "champion" => 34,
                "queue" => 450,
                "season" => 13,
                "timestamp" => 1_564_461_724_971,
                "role" => "DUO_SUPPORT",
                "lane" => "NONE"
              }
            ]
          }
        }

      %{method: :get, url: "https://test.com/lol/match/v4/matches/3109554735"} ->
        %Tesla.Env{
          status: 200,
          body: %{
            "participantIdentities" => [
              %{
                "participantId" => 1,
                "player" => %{
                  "platformId" => "NA1",
                  "accountId" => "pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE",
                  "summonerName" => "eyeinsist",
                  "summonerId" => "7ED760pZ-J3DIJMCqfTHFo3XoVEwkvi0t6kAugPbZzOtW78",
                  "currentPlatformId" => "NA1",
                  "currentAccountId" => "pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE",
                  "matchHistoryUri" => "/v1/stats/player_history/NA1/204564658",
                  "profileIcon" => 4225
                }
              }
            ]
          }
        }

      %{
        method: :get,
        url:
          "https://test.com/lol/summoner/v4/summoners/by-account/pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE"
      } ->
        %Tesla.Env{
          status: 200,
          body: %{
            "id" => "7ED760pZ-J3DIJMCqfTHFo3XoVEwkvi0t6kAugPbZzOtW78",
            "accountId" => "pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE",
            "puuid" =>
              "aEzPNGZuue9UDx4-KjtOMw22qD38i2qrXyXmlNMX9nT54rmX5ydMJOZ45-8kS8A0Boo1bum4qQJtWQ",
            "name" => "eyeinsist",
            "profileIconId" => 4225,
            "revisionDate" => 1_564_546_553_000,
            "summonerLevel" => 140
          }
        }
    end)

    :ok
  end

  test "finds all summoners a summoner has played with in the last 5 matches" do
    result = Blitz.find_recently_played_with_matches("RiotSchmick")

    assert result == %{
             summoner_1: %{
               info: %{
                 "accountId" => "pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE",
                 "id" => "7ED760pZ-J3DIJMCqfTHFo3XoVEwkvi0t6kAugPbZzOtW78",
                 "name" => "eyeinsist",
                 "profileIconId" => 4225,
                 "puuid" =>
                   "aEzPNGZuue9UDx4-KjtOMw22qD38i2qrXyXmlNMX9nT54rmX5ydMJOZ45-8kS8A0Boo1bum4qQJtWQ",
                 "revisionDate" => 1_564_546_553_000,
                 "summonerLevel" => 140
               },
               matches: [
                 %{
                   "champion" => 34,
                   "gameId" => 3_109_554_735,
                   "lane" => "NONE",
                   "platformId" => "NA1",
                   "queue" => 450,
                   "role" => "DUO_SUPPORT",
                   "season" => 13,
                   "timestamp" => 1_564_461_724_971
                 }
               ]
             }
           }

    assert SummonersWatcher.inspect() == %{
             last_matches_by_summoner: %{
               "pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE" => %{
                 "champion" => 34,
                 "gameId" => 3_109_554_735,
                 "lane" => "NONE",
                 "platformId" => "NA1",
                 "queue" => 450,
                 "role" => "DUO_SUPPORT",
                 "season" => 13,
                 "timestamp" => 1_564_461_724_971
               }
             },
             timer_counter: 0
           }

    Process.sleep(350)

    # Requests for recent matches of "pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE"
    # should not exceed 5. 1 for the initial request and 3 for when we start polling
    assert Counter.value() == 4
    new_state = SummonersWatcher.inspect()
    assert new_state.timer_counter == 3

    assert new_state.last_matches_by_summoner["pzdIYyj6VVt2j79_3FHhK4qF_Yj11OnAou_OcvvexYuF5PE"][
             "gameId"
           ] == 1337
  end
end
