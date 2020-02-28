module ClientServer exposing
    ( deleteInboxMessage
    , getFixtures
    , getHistory
    , getLeagueTables
    , getStartGameData
    , getTopScorers
    , loadGame
    , loadNews
    , loadTeam
    , loadTransferListings
    , makeTransferBid
    , pollGameEvents
    , saveFormation
    , sellPlayer
    )

import Array exposing (Array)
import Iso8601
import Date
import Http
import Json.Decode as Json
import Json.Decode.Pipeline as P
import Json.Encode
import RootMsg exposing (Msg(..))
import Time
import Types exposing (..)


loadGame : GameId -> Cmd Msg
loadGame gameId =
    Http.get {
        url = "/game_events/" ++ String.fromInt gameId,
        expect = Http.expectJson LoadGame jsonDecodeGame
    }


sellPlayer : PlayerId -> Cmd Msg
sellPlayer playerId =
    Http.post {
        url = "/sell_player"
      , body = Http.jsonBody <| Json.Encode.object [ ( "player_id", Json.Encode.int playerId ) ]
      , expect = Http.expectJson SellPlayerResponse Json.string
    }

deleteInboxMessage : InboxMessageId -> Cmd Msg
deleteInboxMessage messageId =
    Http.post {
        url = "/delete_message"
      , body = Http.jsonBody <| Json.Encode.object [ ( "message_id", Json.Encode.int messageId ) ]
      , expect = Http.expectJson DeleteMessageResponse Json.string
    }

type alias PlayerPos = (Int, Maybe (Int, Int))

encodeMaybe : Maybe a -> (a -> Json.Encode.Value) -> Json.Encode.Value
encodeMaybe ma encoder = case ma of
    Nothing -> Json.Encode.null
    Just a -> encoder a

type Choice a b = Left a | Right b

saveFormation : Team -> Cmd Msg
saveFormation team =
    let
        tuplePlayerPos : Int -> Player -> PlayerPos
        tuplePlayerPos idx player =
            case Array.get idx team.formation of
                Nothing -> (player.id, Nothing)
                Just pos -> (player.id, Just pos)

        positionEncoder : PlayerPos -> Json.Encode.Value
        positionEncoder (player_id, maybe_pos) =
                Json.Encode.list (\a ->
                    case a of 
                        Left pid -> Json.Encode.int pid
                        Right (Nothing) -> Json.Encode.null
                        Right (Just (x,y)) -> Json.Encode.list Json.Encode.int [x,y]
                ) [ Left player_id, Right maybe_pos ]
        body =
            Http.jsonBody <| Json.Encode.array positionEncoder <| Array.indexedMap tuplePlayerPos team.players
    in
    Http.post {
        url = "/save_formation",
        body = body,
        expect = Http.expectJson SavedFormation Json.string
    }


makeTransferBid : TransferListingId -> Maybe Int -> Cmd Msg
makeTransferBid tid amount =
    let
        body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "amount"
                      , case amount of
                            Just a ->
                                Json.Encode.int a

                            Nothing ->
                                Json.Encode.null
                      )
                    , ( "transfer_listing_id", Json.Encode.int tid )
                    ]
    in Http.post {
        url = "/transfer_bid",
        body = body,
        expect = Http.expectJson SavedBid Json.string
    }


loadTransferListings : Cmd Msg
loadTransferListings =
    Http.get {
        url = "/transfer_listings",
        expect = Http.expectJson GotTransferListings jsonDecodeTransferListings
    }

loadTeam : TeamId -> Cmd Msg
loadTeam teamId =
    Http.get {
        url = "/squad" ++ String.fromInt teamId,
        expect = Http.expectJson ViewTeamLoaded jsonDecodeTeam
    }

pollGameEvents : GameId -> Maybe GameEventId -> Cmd Msg
pollGameEvents gameId lastEventId =
    let
        url =
            "/game_events_since/"
                ++ String.fromInt gameId
                ++ "/"
                ++ (case lastEventId of
                        Just eventId ->
                            String.fromInt eventId

                        Nothing ->
                            ""
                   )
    in Http.get {
        url = url,
        expect = Http.expectJson UpdateGame jsonDecodeGameEventUpdate
    }

getStartGameData : Cmd Msg
getStartGameData =
    Http.get {
        url = "/load_world",
        expect = Http.expectJson GotStartGameData jsonDecodeStartGameData
    }

getFixtures : Cmd Msg
getFixtures =
    Http.get {
        url = "/fixtures",
        expect = Http.expectJson UpdateFixtures jsonDecodeFixtures
    }

getLeagueTables : Cmd Msg
getLeagueTables =
    Http.get {
        url = "/tables",
        expect = Http.expectJson UpdateLeagueTables jsonDecodeLeagueTables
    }

getHistory : Season -> Cmd Msg
getHistory season =
    Http.get {
        url = "/history/" ++ String.fromInt season,
        expect = Http.expectJson UpdateHistory jsonDecodeHistory
    }

getTopScorers : Cmd Msg
getTopScorers =
    Http.get {
        url = "/top_scorers",
        expect = Http.expectJson UpdateTopScorers jsonDecodeTopScorers
    }

loadNews : Cmd Msg
loadNews =
    Http.get {
        url = "/news_articles",
        expect = Http.expectJson GotNews jsonDecodeNews
    }

jsonDecodeNews : Json.Decoder (List News)
jsonDecodeNews =
    Json.list
        (Json.map3 News
            (Json.field "title" Json.string)
            (Json.field "body" Json.string)
            (Json.field "date" jsonDecodeTime)
        )


jsonDecodeTransferListings : Json.Decoder (List TransferListing)
jsonDecodeTransferListings =
    Json.list
        (Json.map7 TransferListing
            (Json.field "id" Json.int)
            (Json.field "minPrice" Json.int)
            (Json.field "deadline" jsonDecodeTime)
            (Json.field "sellerTeamId" Json.int)
            (Json.field "player" jsonDecodePlayer)
            (Json.field "youBid" Json.int |> Json.maybe)
            (Json.field "status" Json.string
                |> Json.andThen
                    (\val ->
                        case val of
                            "OnSale" ->
                                Json.succeed OnSale

                            "Sold" ->
                                Json.succeed Sold

                            "Unsold" ->
                                Json.succeed Unsold

                            "YouWon" ->
                                Json.succeed YouWon

                            "OutBid" ->
                                Json.succeed OutBid

                            "TeamRejected" ->
                                Json.succeed TeamRejected

                            "PlayerRejected" ->
                                Json.succeed PlayerRejected

                            "InsufficientMoney" ->
                                Json.succeed InsufficientMoney

                            _ ->
                                Json.fail <| "Unexpected TransferListing status: " ++ val
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
        (Json.at [ "status" ] Json.string
            |> Json.andThen
                (\val ->
                    case val of
                        "Scheduled" ->
                            Json.succeed Scheduled

                        "InProgress" ->
                            Json.succeed InProgress

                        "Played" ->
                            Json.map Played
                                (Json.map4 FixtureStatusPlayed
                                    (Json.field "homeGoals" Json.int)
                                    (Json.field "awayGoals" Json.int)
                                    (Json.field "homePenalties" Json.int)
                                    (Json.field "awayPenalties" Json.int)
                                )

                        _ ->
                            Json.fail <| "Unexpected fixture status: " ++ val
                )
        )
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
    Json.string
        |> Json.andThen
            (\val ->
                case val of
                    "KickOff" ->
                        Json.succeed KickOff

                    "Goal" ->
                        Json.succeed Goal

                    "GoalKick" ->
                        Json.succeed GoalKick

                    "Corner" ->
                        Json.succeed Corner

                    "Boring" ->
                        Json.succeed Boring

                    "ShotTry" ->
                        Json.succeed ShotTry

                    "ShotMiss" ->
                        Json.succeed ShotMiss

                    "ShotSaved" ->
                        Json.succeed ShotSaved

                    "EndOfPeriod" ->
                        Json.succeed Boring

                    "Injury" ->
                        Json.succeed Boring

                    "Sub" ->
                        Json.succeed Boring

                    "EndOfGame" ->
                        Json.succeed EndOfGame

                    _ ->
                        Json.fail ("Invalid GameEvent kind: " ++ val)
            )


jsonDecodeGameEventSide : Json.Decoder GameEventSide
jsonDecodeGameEventSide =
    Json.int
        |> Json.andThen
            (\val ->
                case val of
                    0 ->
                        Json.succeed Home

                    1 ->
                        Json.succeed Away

                    _ ->
                        Json.fail ("Invalid GameEvent side: " ++ String.fromInt val)
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
    Json.succeed Player
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


jsonDecodePlayerPosition : Json.Decoder ( Int, Int )
jsonDecodePlayerPosition =
    Json.array Json.int
        |> Json.andThen
            (\val ->
                let
                    mx =
                        Array.get 0 val

                    my =
                        Array.get 1 val
                in
                case ( mx, my ) of
                    ( Just x, Just y ) ->
                        Json.succeed ( x, y )

                    _ ->
                        Json.fail "Expected Int,Int"
            )


jsonDecodeTime : Json.Decoder Time.Posix
jsonDecodeTime = Iso8601.decoder


jsonDecodeFixtures : Json.Decoder (List Fixture)
jsonDecodeFixtures =
    Json.list
        (Json.map7 Fixture
            (Json.at [ "gameId" ] Json.int)
            (Json.at [ "homeName" ] Json.string)
            (Json.at [ "awayName" ] Json.string)
            (Json.at [ "start" ] jsonDecodeTime)
            (Json.at [ "status" ] Json.string
                |> Json.andThen
                    (\val ->
                        case val of
                            "Scheduled" ->
                                Json.succeed Scheduled

                            "InProgress" ->
                                Json.succeed InProgress

                            "Played" ->
                                Json.map Played
                                    (Json.map4 FixtureStatusPlayed
                                        (Json.at [ "homeGoals" ] Json.int)
                                        (Json.at [ "awayGoals" ] Json.int)
                                        (Json.field "homePenalties" Json.int)
                                        (Json.field "awayPenalties" Json.int)
                                    )

                            _ ->
                                Json.fail <| "Unexpected fixture status: " ++ val
                    )
            )
            (Json.field "tournament" Json.string)
            (Json.field "stage" Json.int |> Json.maybe)
        )


jsonDecodeTopScorers : Json.Decoder (List TournamentTopScorers)
jsonDecodeTopScorers =
    Json.list
        (Json.map2 TournamentTopScorers
            (Json.field "tournamentName" Json.string)
            (Json.field "topScorers"
                (Json.list
                    (Json.map3 TopScorer
                        (Json.field "teamname" Json.string |> Json.maybe)
                        (Json.field "playername" Json.string)
                        (Json.field "goals" Json.int)
                    )
                )
            )
        )


jsonDecodeHistory : Json.Decoder History
jsonDecodeHistory =
    Json.map3 History
        (Json.field "season" Json.int)
        (Json.field "leagues" jsonDecodeLeagueTables)
        (Json.field "cup_finals" jsonDecodeFixtures)


jsonDecodeLeagueTables : Json.Decoder (List LeagueTable)
jsonDecodeLeagueTables =
    Json.list
        (Json.map2 LeagueTable
            (Json.at [ "name" ] Json.string)
            (Json.at [ "record" ] <|
                Json.list
                    (Json.map8 SeasonRecord
                        (Json.at [ "teamId" ] Json.int)
                        (Json.at [ "name" ] Json.string)
                        (Json.at [ "played" ] Json.int)
                        (Json.at [ "won" ] Json.int)
                        (Json.at [ "drawn" ] Json.int)
                        (Json.at [ "lost" ] Json.int)
                        (Json.at [ "goalsFor" ] Json.int)
                        (Json.at [ "goalsAgainst" ] Json.int)
                    )
            )
        )
