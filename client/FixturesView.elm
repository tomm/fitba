module FixturesView exposing (view)

import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, input, span, table, tr, td, th, text, ul, h3, li, button)
import Svg
import Date
import List
import Array
import Set
import Svg.Attributes exposing (..)
import Time exposing (Time)
import Dict

import Model exposing (..)
import TeamView
import Utils
import RootMsg exposing (Msg, Msg(..))
import ClientServer
import Types exposing (..)
import Uitk

view : Model -> FixtureSubView -> Html Msg
view model subView =
    let fixtureRow showTournament timeFormatter fixture =
            tr [Html.Attributes.class <|
                    if fixture.homeName == model.ourTeam.name || fixture.awayName == model.ourTeam.name then
                        "fixture-own" else "fixture-other",
                onClick (Watch fixture.gameId)] [
                td [] [
                    if showTournament then
                        span [Html.Attributes.class "fixture-tournament"] [text fixture.tournament]
                    else
                        span [] []
                    ,
                    text (fixture.homeName ++ " - " ++ fixture.awayName)
                ],
                td [] [text <| timeFormatter fixture.start],
                td [] [resultText fixture ]
            ]
        resultText fixture =
            case fixture.status of
                Scheduled -> text "Scheduled"
                InProgress -> text "In Progress!"
                Played result -> text (toString result.homeGoals ++ " : " ++ toString result.awayGoals)

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
