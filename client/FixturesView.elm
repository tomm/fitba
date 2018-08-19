module FixturesView exposing (view, update)

import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, input, span, table, tr, td, th, text, ul, h3, li, button)
import Svg
import Date
import List
import Array
import Svg.Attributes exposing (..)
import Time exposing (Time)
import Dict

import Model exposing (..)
import TeamView
import Utils
import RootMsg
import FixturesViewMsg exposing (Msg, Msg(..))
import ClientServer
import Types exposing (..)
import Uitk

match_length_seconds : Float
match_length_seconds = 270.0  -- make sure this matches app/helpers/match_sim_helper.rb:MATCH_LENGTH_SECONDS

view : Model -> Maybe WatchingGame -> Html Msg
view model maybeWatchingGame =
    case maybeWatchingGame of
        Nothing -> Uitk.view Nothing (text "Fixtures") [ fixturesTable model ]
        Just watching -> matchView watching

eventsUpToTimepoint : Game -> Time -> List GameEvent
eventsUpToTimepoint game time =
    List.filter (\a -> a.timestamp <= time) game.events
        |> List.sortWith (\a b -> if a.timestamp > b.timestamp then LT else GT)

latestGameEventAtTimepoint : Game -> Time -> Maybe GameEvent
latestGameEventAtTimepoint game time = eventsUpToTimepoint game time |> List.head

secondsToMatchMinute : Float -> String
secondsToMatchMinute s =
    (toString << round) (90.0 * s / (match_length_seconds * Time.second))

goalSummary : Game -> Time -> Html Msg
goalSummary game time =
    let allGoals side = List.filter (\a -> a.timestamp <= time) game.events
            |> List.filter (\e -> e.kind == Goal && e.side == side)
            |> List.sortWith (\a b -> if a.timestamp > b.timestamp then GT else LT)
        summarizeEvent e =
            let scorer = Maybe.withDefault "" e.playerName
                when = secondsToMatchMinute (e.timestamp - game.start)
            in div [] [text <| case e.side of
                    Home -> scorer ++ " " ++ when
                    Away -> when ++ " " ++ scorer
                ]
        goalSummary side =
            div [Html.Attributes.class "game-summary",
                  teamColorClass side,
                  Html.Attributes.class <| "game-summary-" ++ toString side]
                 <| List.map summarizeEvent (allGoals side)
    in div [] [
        Html.h3 [Html.Attributes.class "game-summary-title"] [text "Goal Summary"],
        Uitk.row [
            Uitk.column 12 [ goalSummary Home ],
            Uitk.column 12 [ goalSummary Away ]
        ]
    ]

teamColorClass side = Html.Attributes.class <| if side == Home then "home-team" else "away-team"
matchStarted game = List.length game.events > 0

matchView : WatchingGame -> Html Msg
matchView watching =
    let game = watching.game
        all_goals = eventsUpToTimepoint game (game.start + watching.timePoint)
                        |> List.filter (\e -> e.kind == Goal)
        goals = (List.filter (\e -> e.side == Home) all_goals |> List.length,
                 List.filter (\e -> e.side == Away) all_goals |> List.length)
        status = case watching.game.status of
            Scheduled -> "Live match"
            InProgress -> "Live match"
            Played _ -> "Match replay"
        showFinalScoreButton = Uitk.row (
                case watching.game.status of
                    Played _ -> 
                        if watching.timePoint < match_length_seconds * Time.second then
                            [
                                Uitk.column 9 [],
                                Uitk.column 6 [ Uitk.actionButton ShowFinalScore "Show final score" ],
                                Uitk.column 9 []
                            ]
                        else []
                    _ -> []
            )
        title = Html.h3 [] [
                Html.span [teamColorClass Home] [text game.homeTeam.name],
                text (" (" ++ (toString <| Tuple.first goals) ++ " : " ++ (toString <| Tuple.second goals) ++ ") "),
                Html.span [teamColorClass Away] [text game.awayTeam.name]
            ]
        maybeLatestEvent = latestGameEventAtTimepoint game (game.start + watching.timePoint)
        attendanceSummary = div [] [
            Html.h3 [] [text "Managers Attending"],
            if List.isEmpty game.attending then
                Html.p [Html.Attributes.class "center"] [text "None"]
            else
                Html.p [Html.Attributes.class "managers-attending"]
                       [text <| String.join ", " game.attending]
        ]

    in Uitk.view Nothing title [
            drawPitch game maybeLatestEvent,
            showFinalScoreButton,
            goalSummary game (game.start + watching.timePoint),
            attendanceSummary,
            Uitk.row [
                Uitk.responsiveColumn 12 [
                    Html.h3 [] [text <| TeamView.teamTitle game.homeTeam],
                    Uitk.row [
                        Uitk.column 1 [],
                        Uitk.column 22 [ Html.map (\_ -> NoOp) <| TeamView.squadList False game.homeTeam.players Nothing ],
                        Uitk.column 1 []
                    ]
                ],
                Uitk.responsiveColumn 12 [
                    Html.h3 [] [text <| TeamView.teamTitle game.awayTeam],
                    Uitk.row [
                        Uitk.column 1 [],
                        Uitk.column 22 [ Html.map (\_ -> NoOp) <| TeamView.squadList False game.awayTeam.players Nothing ],
                        Uitk.column 1 []
                    ]
                ]
            ]
        ]

matchMinute game event = secondsToMatchMinute (event.timestamp - game.start) ++ ":00"

drawPitch : Game -> (Maybe GameEvent) -> Svg.Svg Msg
drawPitch game maybeEv =
    let matchMessage m color = 
            Svg.text_ [Svg.Attributes.x "406", Svg.Attributes.y "32",
                       Svg.Attributes.textAnchor "middle",
                       Svg.Attributes.class "match-event-message",
                       fill color,
                       fillOpacity "1.0"]
                      [Svg.text m]
        gameTime event = 
            Svg.text_ [Svg.Attributes.x "750", Svg.Attributes.y "32",
                       Svg.Attributes.textAnchor "middle",
                       Svg.Attributes.class "match-event-message",
                       fill "white",
                       fillOpacity "1.0"]
                      [Svg.text <| matchMinute game event]
    in Svg.svg
        [Svg.Attributes.width "100%", Svg.Attributes.height "100%", viewBox "0 0 812 515" ]
        ([ 
            Svg.image
                [Svg.Attributes.width "100%", Svg.Attributes.height "100%", Svg.Attributes.xlinkHref "/pitch_h.png" ]
                [],
            drawPlayers game
        ] ++
            (case maybeEv of
                Nothing -> [
                    Svg.g [] [
                        matchMessage ("The match has not started: kick-off on " ++ Utils.timeFormat game.start) "white"
                    ]
                ]
                Just ev -> [
                    drawBall ev,
                    Svg.g [] [
                        matchMessage ev.message (if ev.side == Home then "blue" else "#c00"),
                        gameTime ev
                    ]
                ]
            )
            {- show all positions. useful for debug
            ++
            (List.map drawBall <| List.concat <| List.map (\x -> List.map (\y -> (x,y)) [0,1,2,3,4,5,6]) [0,1,2,3,4])
            -}
        )

pitchX = 812
pitchY = 515
pitchPosPixelPos : (Int, Int) -> (Float, Float)
pitchPosPixelPos (x, y) =
    let
        xpadding = 100.0
        ypadding = 50.0
        xinc = (pitchX - 2*xpadding) / 6
        yinc = (pitchY - 2*ypadding) / 4
    in
        (xpadding + (toFloat (6-y))*xinc, ypadding + (toFloat x)*yinc)

playerHalfPos : GameEventSide -> (Int, Int) -> (Float, Float)
playerHalfPos side (x, y) =
    let
        xpadding = 50.0
        ypadding = 50.0
        xinc = (pitchX - 2*xpadding) / 12
        yinc = (pitchY - 2*ypadding) / 4
        sideFlip = toFloat <| if side == Home then 6-y else y+6
    in
        (xpadding + sideFlip*xinc, ypadding + (toFloat x)*yinc)

zip : List a -> List b -> List (a,b)
zip aa bb = case (aa, bb) of
    ([],_) -> []
    (_,[]) -> []
    (a::ar, b::br) -> (a,b)::zip ar br

drawPlayers : Game -> Svg.Svg Msg
drawPlayers game =
    let playerPos team = zip (List.take 11 <| Array.toList team.players) (List.take 11 <| Array.toList team.formation)
        drawTeam side team = List.map (drawPlayer side) (playerPos team)
        drawPlayer side (player,pos) = 
            let (xpos, ypos) = playerHalfPos side pos
                color = if side == Home then "blue" else "red"
            in [
                Svg.circle [ cx (toString xpos), cy (toString ypos), r "20", fill color, fillOpacity "0.2" ] [],
                Svg.text_ [Svg.Attributes.x <| toString xpos, Svg.Attributes.y <| toString (ypos + 32),
                           Svg.Attributes.textAnchor "middle",
                           Svg.Attributes.class "match-player-label",
                           fill "white",
                           fillOpacity "0.2"]
                          [Svg.text player.name]
            ]
        
    in Svg.g []
        (List.concat <| drawTeam Home game.homeTeam ++
                        drawTeam Away game.awayTeam)
        --++
        --drawTeam Away game.awayTeam

drawBall : GameEvent -> Svg.Svg Msg
drawBall ev =
    let
        (xpos, ypos) = pitchPosPixelPos (ev.ballPos)
        fillCol = if ev.side == Home then "blue" else "red"
    in
        Svg.g [] [
            Svg.circle [ cx (toString xpos), cy (toString ypos), r "30", fill "white" ] [],
            Svg.circle [ cx (toString xpos), cy (toString ypos), r "15", fill fillCol ] [],
            Svg.text_ [Svg.Attributes.x <| toString xpos, Svg.Attributes.y <| toString (ypos + 48),
                       Svg.Attributes.textAnchor "middle",
                       Svg.Attributes.class "match-ball-label",
                       fill "white"]
                      [Svg.text <| Maybe.withDefault "" ev.playerName]
        ]


fixturesTable : Model -> Html Msg
fixturesTable model =
    let fixtureRow fixture =
            tr [Html.Attributes.class <|
                    if fixture.homeName == model.ourTeam.name || fixture.awayName == model.ourTeam.name then
                        "fixture-own" else "fixture-other",
                onClick (Watch fixture.gameId)] [
                td [] [text (fixture.homeName ++ " - " ++ fixture.awayName)],
                td [] [text <| Utils.timeFormat fixture.start],
                td [] [resultText fixture ]
            ]
        resultText fixture =
            case fixture.status of
                Scheduled -> text "Scheduled"
                InProgress -> text "In Progress!"
                Played result -> text (toString result.homeGoals ++ " : " ++ toString result.awayGoals)

        fixtureTable title fixtures = 
            div [] [
                h3 [] [text title],
                table [] ([
                        tr [] [
                            th [] [text "Game"],
                            th [] [text "Date"],
                            th [] [text "Result"]
                        ]
                    ] ++
                    List.map fixtureRow fixtures
                    )
                ]
    in
        div [] [
            fixtureTable "Today's Matches"
                (List.filter (\f -> Utils.dateEq (Date.fromTime f.start) (Date.fromTime model.currentTime)) model.fixtures)
            ,
            fixtureTable "Season Fixtures" model.fixtures
        ]

update : Msg -> Model -> (Model, Cmd RootMsg.Msg)
update msg model =
    let
        latestEventId game = case List.head <| List.reverse game.events of
            Nothing -> Nothing
            Just event -> Just event.id
    in
        case msg of
            NoOp -> (model, Cmd.none)
            Watch gameId ->
                (model, Cmd.batch [ClientServer.loadGame gameId])
            ShowFinalScore -> case model.tab of
                TabFixtures (Just watchingGame) ->
                    ({ model | tab = TabFixtures (Just {
                         watchingGame | timePoint = watchingGame.timePoint + match_length_seconds*Time.second
                        })}, Cmd.none)
                _ -> (model, Cmd.none)
            GameTick -> case model.tab of
                TabFixtures (Just watchingGame) ->
                    let cmds = case List.head <| List.reverse watchingGame.game.events of
                        Nothing ->
                            if model.currentTime >= watchingGame.game.start then
                                -- game should have started. poll for events
                                Cmd.batch [ClientServer.pollGameEvents watchingGame.game.id Nothing]
                            else
                                Cmd.none
                        Just e -> 
                            if e.kind == EndOfGame then
                                -- game ended. stop polling
                                Cmd.none
                            else
                                -- game in progress. get new game events
                                Cmd.batch [ClientServer.pollGameEvents watchingGame.game.id (Just e.id)]
                    in (
                        { model | tab = TabFixtures (Just { watchingGame | timePoint = watchingGame.timePoint + 1*Time.second})},
                        cmds
                    )
                _ -> (model, Cmd.none)
