module MatchView exposing (view, update)

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
import MatchViewMsg exposing (Msg, Msg(..))
import ClientServer
import Types exposing (..)
import Uitk

view : WatchingGame -> Html Msg
view watching =
    let game = watching.game
        all_goals = eventsUpToTimepoint game (game.start + watching.timePoint)
                        |> List.filter (\e -> e.kind == Goal)
        goals = (List.filter (\e -> e.side == Home) all_goals |> List.length,
                 List.filter (\e -> e.side == Away) all_goals |> List.length)
        status = case watching.game.status of
            Scheduled -> "Live match"
            InProgress -> "Live match"
            Played _ -> "Match replay"
        showFinalScoreButton =
                case watching.game.status of
                    Played _ -> 
                        case maybeLatestEvent of
                            Nothing -> Html.span [] []
                            Just ev -> if ev.kind /= EndOfGame then Uitk.actionButton ShowFinalScore "Show final score" else Html.span [] []
                    _ -> Html.span [] []
        title = Html.h3 [] [
                Html.span [teamColorClass Home] [text game.homeTeam.name],
                text (" (" ++ (toString <| Tuple.first goals) ++ " : " ++ (toString <| Tuple.second goals) ++ ") "),
                Html.span [teamColorClass Away] [text game.awayTeam.name]
            ]
        maybeLatestEvent = latestGameEventAtTimepoint game (game.start + watching.timePoint)
        attendanceSummary = div [] [
            Html.h4 [] [text "Managers Attending"],
            if List.isEmpty game.attending then
                Html.p [Html.Attributes.class "center"] [text "None"]
            else
                Html.p [Html.Attributes.class "managers-attending"]
                       [text <| String.join ", " game.attending]
        ]

    in Uitk.view Nothing title [
            drawPitch game maybeLatestEvent,
            Uitk.row [
                Uitk.column 12 [
                    goalSummary game (game.start + watching.timePoint),
                    showFinalScoreButton
                ],
                Uitk.column 12 [
                    shotSummary game (game.start + watching.timePoint),
                    possessionSummary game (game.start + watching.timePoint),
                    attendanceSummary
                ]
            ],
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


eventsUpToTimepoint : Game -> Time -> List GameEvent
eventsUpToTimepoint game time =
    List.filter (\a -> a.timestamp <= time) game.events
        |> List.sortWith (\a b -> if a.timestamp > b.timestamp then LT else GT)

latestGameEventAtTimepoint : Game -> Time -> Maybe GameEvent
latestGameEventAtTimepoint game time = eventsUpToTimepoint game time |> List.head

secondsToMatchMinute : Bool -> Float -> String
secondsToMatchMinute showSeconds time =
    let s = time / Time.second
        seconds = if showSeconds then ":00" else ""
    in  if s < 3*55 then
            let mins = round (s/3)
            in if mins <= 45 then toString mins ++ seconds else "45+" ++ (toString (mins-45)) ++ seconds
        else if s < 3*105 then
            let mins = round (s/3 - 10)
            in if mins <= 90 then toString mins ++ seconds else "90+" ++ (toString (mins-90)) ++ seconds
        else if s < 3*125 then
            let mins = round (s/3 - 15)
            in if mins <= 105 then toString mins ++ seconds else "105+" ++ (toString (mins-105)) ++ seconds
        else
            let mins = round (s/3 - 20)
            in if mins <= 120 then toString mins ++ seconds else "120+" ++ (toString (mins-120)) ++ seconds

summary side = div [Html.Attributes.class "game-summary",
               teamColorClass side,
               Html.Attributes.class <| "game-summary-" ++ toString side]

goalSummary : Game -> Time -> Html Msg
goalSummary game time =
    let allGoals side = List.filter (\a -> a.timestamp <= time) game.events
            |> List.filter (\e -> e.kind == Goal && e.side == side)
            |> List.sortWith (\a b -> if a.timestamp > b.timestamp then GT else LT)
        summarizeEvent e =
            let scorer = Maybe.withDefault "" e.playerName
                when = secondsToMatchMinute False (e.timestamp - game.start)
            in div [] [text <| case e.side of
                    Home -> scorer ++ " " ++ when
                    Away -> when ++ " " ++ scorer
                ]
        goalSummary side = summary side <| List.map summarizeEvent (allGoals side)
    in div [] [
        Html.h4 [Html.Attributes.class "game-summary-title"] [text "Goal Summary"],
        Uitk.row [
            Uitk.column 12 [ goalSummary Home ],
            Uitk.column 12 [ goalSummary Away ]
        ]
    ]

shotSummary : Game -> Time -> Html Msg
shotSummary game time =
    let numShots side = List.filter (\e -> e.timestamp <= time && e.side == side) game.events
                |> List.filter (\e -> e.kind == ShotTry)
                |> List.length
        numMisses side = List.filter (\e -> e.timestamp <= time && e.side == side) game.events
                |> List.filter (\e -> e.kind == ShotMiss)
                |> List.length
        shotsSummary side = summary side [div [] [ text <| toString <| numShots side ]]
        onTargetSummary side = summary side [div [] [ text <| toString <| numShots side  - numMisses side ]]
    in div [] [
        Html.h4 [Html.Attributes.class "game-summary-title"] [text "Total Shots"],
        Uitk.row [
            Uitk.column 12 [ shotsSummary Home ],
            Uitk.column 12 [ shotsSummary Away ]
        ],
        Html.h4 [Html.Attributes.class "game-summary-title"] [text "On Target"],
        Uitk.row [
            Uitk.column 12 [ onTargetSummary Home ],
            Uitk.column 12 [ onTargetSummary Away ]
        ]
    ]

possessionSummary : Game -> Time -> Html Msg
possessionSummary game time =
    let tot_events = List.length <| List.filter (\e -> e.timestamp <= time) game.events
        num_events side = List.length (List.filter (\e ->
            e.timestamp <= time && e.side == side) game.events)
        possession side = summary side [div [] 
            (case tot_events of
                0 -> []
                n -> [text <| toString <| round <| 100.0 * toFloat (num_events side) /
                                                  toFloat tot_events
                    , text "%"]
              )]
    in div [] [
        Html.h4 [Html.Attributes.class "game-summary-title"] [text "Possession"],
        Uitk.row [
            Uitk.column 12 [ possession Home ],
            Uitk.column 12 [ possession Away ]
        ]
    ]
    

teamColorClass side = Html.Attributes.class <| if side == Home then "home-team" else "away-team"
matchStarted game = List.length game.events > 0

matchMinute game event = secondsToMatchMinute True (event.timestamp - game.start)

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
            Svg.text_ [Svg.Attributes.x "740", Svg.Attributes.y "32",
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
        xpadding = if y == 0 || y == 6 then 50.0 else 5.0
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
        xSideFlip = toFloat <| if side == Home then 6-y else y+6
        ySideFlip = toFloat <| if side == Home then x else 4-x
    in
        (xpadding + xSideFlip*xinc, ypadding + ySideFlip*yinc)

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

update : Msg -> Model -> (Model, Cmd RootMsg.Msg)
update msg model =
    let
        latestEventId game = case List.head <| List.reverse game.events of
            Nothing -> Nothing
            Just event -> Just event.id
    in
        case msg of
            NoOp -> (model, Cmd.none)
            ShowFinalScore -> case model.tab of
                TabMatch watchingGame ->
                    ({ model | tab = TabMatch ({
                         watchingGame | timePoint = watchingGame.timePoint + 500*Time.second
                        })}, Cmd.none)
                _ -> (model, Cmd.none)
            GameTick -> case model.tab of
                TabMatch watchingGame ->
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
                        { model | tab = TabMatch ({ watchingGame | timePoint = watchingGame.timePoint + 1*Time.second})},
                        cmds
                    )
                _ -> (model, Cmd.none)
