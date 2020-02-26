module ClientServer exposing (loadGame, loadTeam, saveFormation, sellPlayer, pollGameEvents, getStartGameData, getFixtures, getLeagueTables,
    loadTransferListings, makeTransferBid, deleteInboxMessage, loadNews, getTopScorers, getHistory)

import Array exposing (Array)
import Date
import Http
import Json.Decode as Json
import Json.Encode
import Time
import Json.Decode.Pipeline as P

import RootMsg exposing (Msg, Msg(..))
import Types exposing (..)

loadGame : GameId -> Cmd Msg
loadGame gameId =
    let url = "/game_events/" ++ toString gameId
    in Http.send LoadGame (Http.get url jsonDecodeGame)

sellPlayer : PlayerId -> Cmd Msg
sellPlayer playerId =
    let body = Http.jsonBody <| Json.Encode.object [("player_id", Json.Encode.int playerId)]
    in Http.send SellPlayerResponse (Http.post "/sell_player" body Json.string)

deleteInboxMessage : InboxMessageId -> Cmd Msg
deleteInboxMessage messageId =
    let body = Http.jsonBody <| Json.Encode.object [("message_id", Json.Encode.int messageId)]
    in Http.send DeleteMessageResponse (Http.post "/delete_message" body Json.string)

saveFormation : Team -> Cmd Msg
saveFormation team = 
    let tuplePlayerPos idx player =
            case Array.get idx team.formation of
                Nothing -> Json.Encode.list [ Json.Encode.int player.id, Json.Encode.null ]
                Just pos -> Json.Encode.list [
                    Json.Encode.int player.id,
                    Json.Encode.list [ Json.Encode.int <| Tuple.first pos, Json.Encode.int <| Tuple.second pos ]
                    ]
        body = Http.jsonBody <| Json.Encode.array <| Array.indexedMap tuplePlayerPos team.players
    in
        Http.send SavedFormation (Http.post "/save_formation" body Json.string)

makeTransferBid : TransferListingId -> Maybe Int -> Cmd Msg
makeTransferBid tid amount =
    let body = Http.jsonBody <| Json.Encode.object [
            ("amount", case amount of
                Just a -> Json.Encode.int a
                Nothing -> Json.Encode.null),
            ("transfer_listing_id", Json.Encode.int tid)
        ]
    in Http.send SavedBid (Http.post "/transfer_bid" body Json.string)

loadTransferListings : Cmd Msg
loadTransferListings = Http.send GotTransferListings (Http.get "/transfer_listings" jsonDecodeTransferListings)

loadTeam : TeamId -> Cmd Msg
loadTeam teamId =
    let url = "/squad/" ++ toString teamId
    in Http.send ViewTeamLoaded (Http.get url jsonDecodeTeam)

pollGameEvents : GameId -> Maybe GameEventId -> Cmd Msg
pollGameEvents gameId lastEventId =
    let url = "/game_events_since/" ++ toString gameId ++ "/" ++
        case lastEventId of
            Just eventId -> toString eventId
            Nothing -> ""
    in Http.send UpdateGame (Http.get url jsonDecodeGameEventUpdate)

getStartGameData : Cmd Msg
getStartGameData = Http.send GotStartGameData (Http.get "/load_world" jsonDecodeStartGameData)

getFixtures : Cmd Msg
getFixtures =
    Http.send UpdateFixtures (Http.get "/fixtures" jsonDecodeFixtures)

getLeagueTables : Cmd Msg
getLeagueTables =
    Http.send UpdateLeagueTables (Http.get "/tables" jsonDecodeLeagueTables)

getHistory : Season -> Cmd Msg
getHistory season =
    let url = "/history/" ++ toString season
    in Http.send UpdateHistory (Http.get url jsonDecodeHistory)

getTopScorers : Cmd Msg
getTopScorers =
    Http.send UpdateTopScorers (Http.get "/top_scorers" jsonDecodeTopScorers)

loadNews : Cmd Msg
loadNews = Http.send GotNews (Http.get "/news_articles" jsonDecodeNews)

jsonDecodeNews : Json.Decoder (List News)
jsonDecodeNews =
    Json.list (
        Json.map3 News
            (Json.field "title" Json.string)
            (Json.field "body" Json.string)
            (Json.field "date" jsonDecodeTime)
    )

jsonDecodeTransferListings : Json.Decoder (List TransferListing)
jsonDecodeTransferListings =
    Json.list (
        Json.map7 TransferListing
            (Json.field "id" Json.int)
            (Json.field "minPrice" Json.int)
            (Json.field "deadline" jsonDecodeTime)
            (Json.field "sellerTeamId" Json.int)
            (Json.field "player" jsonDecodePlayer)
            (Json.field "youBid" Json.int |> Json.maybe)
            (Json.field "status" Json.string |> Json.andThen
                (\val ->
                    case val of
                        "OnSale" -> Json.succeed OnSale
                        "Sold" -> Json.succeed Sold
                        "Unsold" -> Json.succeed Unsold
                        "YouWon" -> Json.succeed YouWon
                        "OutBid" -> Json.succeed OutBid
                        "TeamRejected" -> Json.succeed TeamRejected
                        "PlayerRejected" -> Json.succeed PlayerRejected
                        "InsufficientMoney" -> Json.succeed InsufficientMoney
                        _ -> Json.fail <| "Unexpected TransferListing status: " ++ val
                )
            )
    )

jsonDecodeGame : Json.Decoder Game
jsonDecodeGame =
    Json.map8 Game
        (Json.field "id" Json.int)
        (Json.field "homeTeam" jsonDecodeTeam)
        (Json.field "awayTeam" jsonDecodeTeam)
        (Json.field "start" jsonDecodeTime)
        (Json.field "events" <| Json.list jsonDecodeGameEvent)
        (Json.at ["status"] Json.string |> Json.andThen (\val ->
            case val of
                "Scheduled" -> Json.succeed Scheduled
                "InProgress" -> Json.succeed InProgress
                "Played" -> Json.map Played
                    (Json.map4 FixtureStatusPlayed
                        (Json.field "homeGoals" Json.int)
                        (Json.field "awayGoals" Json.int)
                        (Json.field "homePenalties" Json.int)
                        (Json.field "awayPenalties" Json.int)
                    )
                _ -> Json.fail <| "Unexpected fixture status: " ++ val
        ))
        (Json.field "attending" (Json.list Json.string))
        (Json.field "stage" Json.int |> Json.maybe)

jsonDecodeGameEventUpdate : Json.Decoder GameEventUpdate
jsonDecodeGameEventUpdate =
    Json.map2 GameEventUpdate
        (Json.field "attending" (Json.list Json.string))
        (Json.field "events" (Json.list jsonDecodeGameEvent))

jsonDecodeGameEvent : Json.Decoder GameEvent
jsonDecodeGameEvent =
    Json.map8 GameEvent
        (Json.field "id" Json.int)
        (Json.field "gameId" Json.int)
        (Json.field "kind" jsonDecodeGameEventKind)
        (Json.field "side" jsonDecodeGameEventSide)
        (Json.field "timestamp" jsonDecodeTime)
        (Json.field "message" Json.string)
        (Json.field "ballPos" jsonDecodePlayerPosition)
        (Json.field "playerName" Json.string |> Json.maybe)

jsonDecodeGameEventKind : Json.Decoder GameEventKind
jsonDecodeGameEventKind =
    Json.string |> Json.andThen (\val ->
        case val of
            "KickOff" -> Json.succeed KickOff
            "Goal" -> Json.succeed Goal
            "GoalKick" -> Json.succeed GoalKick
            "Corner" -> Json.succeed Corner
            "Boring" -> Json.succeed Boring
            "ShotTry" -> Json.succeed ShotTry
            "ShotMiss" -> Json.succeed ShotMiss
            "ShotSaved" -> Json.succeed ShotSaved
            "EndOfPeriod" -> Json.succeed Boring
            "Injury" -> Json.succeed Boring
            "Sub" -> Json.succeed Boring
            "EndOfGame" -> Json.succeed EndOfGame
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

jsonDecodeStartGameData : Json.Decoder StartGameData
jsonDecodeStartGameData =
    Json.map2 StartGameData
        (Json.field "team" jsonDecodeTeam)
        (Json.field "season" Json.int)

jsonDecodeTeam : Json.Decoder Team
jsonDecodeTeam =
    Json.map7 Team
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
        (Json.field "manager" (Json.string |> Json.maybe))
        (Json.field "players" (Json.array jsonDecodePlayer))
        (Json.field "formation" (Json.array jsonDecodePlayerPosition))
        (Json.field "money" Json.int |> Json.maybe)
        (Json.field "inbox" (Json.list jsonDecodeInboxMessage))

jsonDecodeInboxMessage : Json.Decoder InboxMessage
jsonDecodeInboxMessage =
    Json.map5 InboxMessage
        (Json.field "id" Json.int)
        (Json.field "from" Json.string)
        (Json.field "subject" Json.string)
        (Json.field "body" Json.string)
        (Json.field "date" jsonDecodeTime)

jsonDecodePlayer : Json.Decoder Player
jsonDecodePlayer =
    P.decode Player
        |> P.required "id" Json.int
        |> P.required "name" Json.string
        |> P.required "age" Json.int
        |> P.required "forename" Json.string
        |> P.required "shooting" Json.int
        |> P.required "passing" Json.int
        |> P.required "tackling" Json.int
        |> P.required "handling" Json.int
        |> P.required "speed" Json.int
        |> P.required "injury" Json.int
        |> P.required "form" Json.int
        |> P.required "positions" (Json.list jsonDecodePlayerPosition)

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
        Json.map7 Fixture
            (Json.at ["gameId"] Json.int)
            (Json.at ["homeName"] Json.string)
            (Json.at ["awayName"] Json.string)
            (Json.at ["start"] jsonDecodeTime)
            (Json.at ["status"] Json.string |> Json.andThen (\val ->
                case val of
                    "Scheduled" -> Json.succeed Scheduled
                    "InProgress" -> Json.succeed InProgress
                    "Played" -> Json.map Played
                        (Json.map4 FixtureStatusPlayed
                            (Json.at ["homeGoals"] Json.int)
                            (Json.at ["awayGoals"] Json.int)
                            (Json.field "homePenalties" Json.int)
                            (Json.field "awayPenalties" Json.int)
                        )
                    _ -> Json.fail <| "Unexpected fixture status: " ++ val
            ))
            (Json.field "tournament" Json.string)
            (Json.field "stage" Json.int |> Json.maybe)
    )

jsonDecodeTopScorers : Json.Decoder (List TournamentTopScorers)
jsonDecodeTopScorers =
    Json.list (
        Json.map2 TournamentTopScorers
            (Json.field "tournamentName" Json.string)
            (Json.field "topScorers" (
                Json.list (
                    Json.map3 TopScorer
                        (Json.field "teamname" Json.string |> Json.maybe)
                        (Json.field "playername" Json.string)
                        (Json.field "goals" Json.int)
                    )
                )
            )
    )

jsonDecodeHistory : Json.Decoder History
jsonDecodeHistory =
    Json.map2 History
        (Json.field "season" Json.int)
        (Json.field "leagues" jsonDecodeLeagueTables)

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
