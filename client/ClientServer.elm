module ClientServer exposing (loadGame, pollGameEvents, getStartGameData, getFixtures, getLeagueTables)

import Array exposing (Array)
import Date
import Http
import Json.Decode as Json
import Json.Encode as JsonEncode
import Time

import Model exposing (..)
import RootMsg exposing (Msg, Msg(..))

loadGame : GameId -> Cmd Msg
loadGame gameId =
    let url = "/game_events/" ++ toString gameId
    in Http.send LoadGame (Http.get url jsonDecodeGame)

pollGameEvents : GameId -> Maybe GameEventId -> Cmd Msg
pollGameEvents gameId lastEventId =
    let url = "/game_events_since/" ++ toString gameId ++ "/" ++
        case lastEventId of
            Just eventId -> toString eventId
            Nothing -> ""
    in Http.send UpdateGame (Http.get url <| Json.list jsonDecodeGameEvent)

getStartGameData : Cmd Msg
getStartGameData = Http.send GotStartGameData (Http.get "/load_world" jsonDecodeTeam)

getFixtures : Cmd Msg
getFixtures =
    Http.send UpdateFixtures (Http.get "/fixtures" jsonDecodeFixtures)

getLeagueTables : Cmd Msg
getLeagueTables =
    Http.send UpdateLeagueTables (Http.get "/tables" jsonDecodeLeagueTables)

jsonDecodeGame : Json.Decoder Game
jsonDecodeGame =
    Json.map5 Game
        (Json.field "id" Json.int)
        (Json.field "homeTeam" jsonDecodeTeam)
        (Json.field "awayTeam" jsonDecodeTeam)
        (Json.field "start" jsonDecodeTime)
        (Json.field "events" <| Json.list jsonDecodeGameEvent)

jsonDecodeGameEvent : Json.Decoder GameEvent
jsonDecodeGameEvent =
    Json.map7 GameEvent
        (Json.field "id" Json.int)
        (Json.field "gameId" Json.int)
        (Json.field "kind" jsonDecodeGameEventKind)
        (Json.field "side" jsonDecodeGameEventSide)
        (Json.field "timestamp" jsonDecodeTime)
        (Json.field "message" Json.string)
        (Json.field "ballPos" jsonDecodePlayerPosition)

jsonDecodeGameEventKind : Json.Decoder GameEventKind
jsonDecodeGameEventKind =
    Json.string |> Json.andThen (\val ->
        case val of
            "KickOff" -> Json.succeed KickOff
            "Goal" -> Json.succeed Goal
            "Boring" -> Json.succeed Boring
            "Shot" -> Json.succeed Shot
            "EndGame" -> Json.succeed EndOfGame
            _ -> Json.fail ("Invalid GameEvent kind: " ++ val)
        )

jsonDecodeGameEventSide : Json.Decoder GameEventSide
jsonDecodeGameEventSide =
    Json.int |> Json.andThen (\val ->
        case val of
            0 -> Json.succeed Home
            1 -> Json.succeed Away
            _ -> Json.fail ("Invalid GameEvent side: " ++ toString val)
        )

jsonDecodeTeam : Json.Decoder Team
jsonDecodeTeam =
    Json.map4 Team
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
        (Json.field "players" (Json.array jsonDecodePlayer))
        (Json.field "formation" (Json.array jsonDecodePlayerPosition))

jsonDecodePlayer : Json.Decoder Player
jsonDecodePlayer =
    Json.map7 Player
        (Json.at ["id"] Json.int)
        (Json.at ["name"] Json.string)
        (Json.at ["shooting"] Json.int)
        (Json.at ["passing"] Json.int)
        (Json.at ["tackling"] Json.int)
        (Json.at ["handling"] Json.int)
        (Json.at ["speed"] Json.int)

jsonDecodePlayerPosition : Json.Decoder (Int, Int)
jsonDecodePlayerPosition =
    (Json.array Json.int) |> Json.andThen (\val ->
        let mx = Array.get 0 val 
            my = Array.get 1 val
        in case (mx,my) of
            (Just x, Just y) -> Json.succeed (x, y)
            _ -> Json.fail "Expected Int,Int"
    )

jsonDecodeTime : Json.Decoder Time.Time
jsonDecodeTime =
  Json.string
    |> Json.andThen (\val ->
        case Date.fromString val of
          Err err -> Json.fail err
          Ok d -> Json.succeed <| Date.toTime d)

jsonDecodeFixtures : Json.Decoder (List Fixture)
jsonDecodeFixtures =
    Json.list (
        Json.map5 Fixture
            (Json.at ["gameId"] Json.int)
            (Json.at ["homeName"] Json.string)
            (Json.at ["awayName"] Json.string)
            (Json.at ["start"] jsonDecodeTime)
            (Json.at ["status"] Json.string |> Json.andThen (\val ->
                if val == "Scheduled" then
                    Json.succeed Scheduled
                else
                    Json.map Played
                        (Json.map2 FixtureStatusPlayed
                            (Json.at ["homeGoals"] Json.int)
                            (Json.at ["awayGoals"] Json.int)
                        )
            ))
    )

jsonDecodeLeagueTables : Json.Decoder (List LeagueTable)
jsonDecodeLeagueTables =
    Json.list (
        Json.map2 LeagueTable
            (Json.at ["name"] Json.string)
            (Json.at ["record"] <| Json.list (
                Json.map8 SeasonRecord
                    (Json.at ["teamId"] Json.int)
                    (Json.at ["name"] Json.string)
                    (Json.at ["played"] Json.int)
                    (Json.at ["won"] Json.int)
                    (Json.at ["drawn"] Json.int)
                    (Json.at ["lost"] Json.int)
                    (Json.at ["goalsFor"] Json.int)
                    (Json.at ["goalsAgainst"] Json.int)
            ))
    )
