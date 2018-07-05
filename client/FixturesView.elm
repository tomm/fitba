module FixturesView exposing (view, update)

import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, h2, input, table, tr, td, th, text, ul, li, button)
import Svg
import Svg.Attributes exposing (..)
import Time exposing (Time)

import Styles
import Model exposing (..)
import Utils
import Dict
import RootMsg
import FixturesViewMsg exposing (Msg, Msg(Watch))
import ClientServer

match_length_seconds : Float
match_length_seconds = 270.0  -- make sure this matches app/simulation.rb:MATCH_LENGTH_SECONDS

view : Model -> Maybe WatchingGame -> Html Msg
view model maybeWatchingGame =
    div [] (
        case maybeWatchingGame of
            Nothing -> [
                h2 [] [text "Fixtures"],
                fixturesTable model
            ]
            Just watching -> [
                h2 [] [text "Match Video"],
                case watching.game of
                    Nothing -> div [] [text "Game loading..."]
                    Just game -> matchView game watching
            ]
    )

eventsUpToTimepoint : Game -> Time -> List GameEvent
eventsUpToTimepoint game time =
    List.filter (\a -> a.timestamp <= time) game.events
        |> List.sortWith (\a b -> if a.timestamp > b.timestamp then LT else GT)

latestGameEventAtTimepoint : Game -> Time -> Maybe GameEvent
latestGameEventAtTimepoint game time = eventsUpToTimepoint game time |> List.head

matchView : Game -> WatchingGame -> Html Msg
matchView game watching =
    let maybeEv = latestGameEventAtTimepoint game (game.start + watching.timePoint)
        matchMinute = round <| case maybeEv of
            Nothing -> 90.0 * watching.timePoint / match_length_seconds / Time.second
            Just ev -> 90.0 * (ev.timestamp - game.start) / match_length_seconds / Time.second
        matchTimeDisplay = if matchStarted then
                div
                [Html.Attributes.style [("float", "right")]]
                [text <| (++) "Time: " <| toString <| matchMinute, text ":00"]
            else
                div [] []
        goals =
            let all_goals = eventsUpToTimepoint game (game.start + watching.timePoint)
                        |> List.filter (\e -> e.kind == Goal)
            in (List.filter (\e -> e.side == Home) all_goals |> List.length,
                List.filter (\e -> e.side == Away) all_goals |> List.length)
        matchStarted = List.length game.events > 0

    in
        div []
            [
                Html.h3 [] [text (game.homeTeam.name ++ " " ++ (toString <| Tuple.first goals) ++ " - " ++
                                  (toString <| Tuple.second goals) ++ " " ++ game.awayTeam.name)],
                matchTimeDisplay,
                (case latestGameEventAtTimepoint game (game.start + watching.timePoint) of
                    Nothing -> div [] [
                        text "The match has not started.",
                        drawPitch game Nothing
                        ]
                    Just ev -> div [] [
                        text ev.message,
                        drawPitch game <| Just ev
                    ]
                )
            ]

drawPitch : Game -> (Maybe GameEvent) -> Svg.Svg Msg
drawPitch game maybeEv =
    Svg.svg
        [Svg.Attributes.width "100%", Svg.Attributes.height "100%", viewBox "0 0 812 515" ]
        ([ 
            Svg.image
                [Svg.Attributes.width "100%", Svg.Attributes.height "100%", Svg.Attributes.xlinkHref "/pitch_h.png" ]
                []
        ] ++
            (case maybeEv of
                Nothing -> []
                Just ev -> [drawBall ev.ballPos]
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

    {- this worked for bigger pitch size -- may need when moving formations work
    let
        xpadding = 150.0
        ypadding = 50.0
        xinc = (pitchX - 2*xpadding) / 4
        yinc = (pitchY - 2*ypadding) / 4
    in
        (xpadding + (toFloat (4-y))*xinc, ypadding + (toFloat x)*yinc)
    -}

drawBall : (Int, Int) -> Svg.Svg Msg
drawBall (x, y) =
    let
        (xpos, ypos) = pitchPosPixelPos (x, y)
    in
        Svg.g [] [
            Svg.circle [ cx (toString xpos), cy (toString ypos), r "30", fill "white" ] [],
            Svg.text_ [fill "black", Svg.Attributes.x <| toString xpos, Svg.Attributes.y <| toString ypos]
                      [Svg.text ((toString x) ++ "," ++ (toString y))]
        ]


fixturesTable : Model -> Html Msg
fixturesTable model =
    let fixtureRow fixture =
            tr [onClick (Watch fixture.gameId)] [
                td [] [text (fixture.homeName ++ " - " ++ fixture.awayName)],
                td [] [text <| Utils.timeFormat fixture.start],
                td [] [resultText fixture ]
            ]
        resultText fixture =
            case fixture.status of
                Scheduled -> text "Scheduled"
                Played result -> text (toString result.homeGoals ++ " : " ++ toString result.awayGoals)
    in
        table
            [Styles.tableStyle]
            ([
                tr [] [
                    th [] [text "Game"],
                    th [] [text "Date"],
                    th [] [text "Result"]
                ]
            ] ++
            List.map fixtureRow model.fixtures
            )

update : Msg -> Model -> (Model, Cmd RootMsg.Msg)
update msg model =
    case msg of
        Watch gameId -> (
            { model | tab = TabFixtures (Just { gameId=gameId, timePoint=0.0, game=Nothing }) },
            Cmd.batch [ClientServer.loadGame gameId]
        )
