module FixturesView exposing (view, resultText)

import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, input, span, table, tr, td, th, text, ul, h3, li, button)
import Date
import List
import Set

import Model exposing (..)
import Utils
import RootMsg exposing (Msg, Msg(..))
import Types exposing (..)
import Uitk

resultText : Fixture -> Html Msg
resultText fixture =
    case fixture.status of
        Scheduled -> text "Scheduled"
        InProgress -> text "In Progress!"
        Played result -> text (toString result.homeGoals ++ " : " ++ toString result.awayGoals
            ++ (
                if result.homePenalties > 0 || result.awayPenalties > 0 then
                    " (" ++ toString result.homePenalties ++ " : " ++
                            toString result.awayPenalties ++ " P)"
                else ""
            ))

view : Model -> FixtureSubView -> Html Msg
view model subView =
    let fixtureRow showTournament timeFormatter fixture =
            tr [Html.Attributes.class <|
                    if fixture.homeName == model.ourTeam.name || fixture.awayName == model.ourTeam.name then
                        "fixture-own" else "fixture-other",
                onClick (Watch fixture.gameId)] [
                td [] [
                    if showTournament then
                        span [Html.Attributes.class "fixture-tournament"] [text <| tournamentText fixture]
                    else case fixture.stage of
                        Nothing -> span [] []
                        Just stage -> span [Html.Attributes.class "fixture-tournament"] [text <| cupStage stage]
                    ,
                    text (fixture.homeName ++ " - " ++ fixture.awayName)
                ],
                td [] [text <| timeFormatter fixture.start],
                td [] [resultText fixture ]
            ]

        tournamentText fixture =
            fixture.tournament ++ case fixture.stage of
                Nothing -> ""
                Just stage -> " " ++ cupStage stage

        cupStage stage = case stage of
                            1 -> "Finals"
                            2 -> "Semi-Finals"
                            4 -> "Quarter-Finals"
                            8 -> "Last 16"
                            _ -> "Preliminaries"

        fixtureTable showTournament timeFormatter title fixtures = 
            div [] [
                h3 [] [text title],
                table [] ([
                        tr [] [
                            th [] [text "Game"],
                            th [] [text "Kickoff"],
                            th [] [text "Result"]
                        ]
                    ] ++
                    List.map (fixtureRow showTournament timeFormatter) fixtures
                    )
                ]

        tournaments = Set.toList <| Set.fromList (List.map .tournament model.fixtures)

        todaysFixtures = [
            Uitk.blockButtonRow <| List.map (\tournament ->
                Uitk.blockButton 8
                    (ChangeTab (TabFixtures (AllFixtures tournament)))
                    tournament
            ) tournaments,
            fixtureTable True Utils.onlyTimeFormat "Today's Matches"
                (List.filter (\f -> Utils.dateEq (Date.fromTime f.start) (Date.fromTime model.currentTime)) model.fixtures)
        ]
    in
        Uitk.view Nothing (text "Fixtures") <|
            case subView of
                TodaysFixtures -> todaysFixtures
                AllFixtures tournamentName -> [
                        fixtureTable False Utils.timeFormat (tournamentName ++ " Fixtures")
                            (List.filter (\f -> f.tournament == tournamentName) model.fixtures)
                    ]
