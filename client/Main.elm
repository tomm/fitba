module Main exposing (..)

import Array exposing (Array)
import Debug
import Dict exposing (Dict)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, input, text, ul, li, button)
import Maybe exposing (withDefault)
import Svg
import Time
import Date
import Task
import Http
import Json.Decode as Json
import Json.Encode as JsonEncode

import FixturesView
import FixturesViewMsg
import Model exposing (..)
import RootMsg exposing (..)
import Styles exposing (..)
import TeamView
import ClientServer exposing (..)


main =
    Html.program {
        init = init,
        view = view,
        update = update,
        subscriptions = subscriptions
    }

init : (RootModel, Cmd Msg)
init = ({ errorMsg=Nothing, state=Loading}, Cmd.batch [getStartGameData])
    {-
    games = Dict.fromList [
        (2, {
                id=2, homeTeam=team1, awayTeam=team2, start=1492174154 * Time.second, events=[
                    { id=2, type_=Boring, timestamp=1492174154 * Time.second, message="Kick off!", ballPos=(2,2) },
                    { id=2, type_=Boring, timestamp=1492174156 * Time.second, message="Shit happened!", ballPos=(2,3) },
                    { id=2, type_=Boring, timestamp=1492174158 * Time.second, message="And again", ballPos=(4,3) },
                    { id=2, type_=Boring, timestamp=1492174160 * Time.second, message="The final whistle has been blown!", ballPos=(4,2) }
                ]
            }
        )
    ]
    -}

-- SUBSCRIPTIONS

subscriptions : RootModel -> Sub Msg
subscriptions model = Sub.batch [
        Time.every Time.second ClockTick
    ]


-- UPDATE

update : Msg -> RootModel -> (RootModel, Cmd Msg)
update msg model =
    let updateState newState = ({ model | state = GameData newState}, Cmd.none)
        updateWatchingGame watchingGame newEvents =
            let game = watchingGame.game
            in {watchingGame | game = {game | events = List.append game.events newEvents} }
        handleLoadingStateMsgs =
            case msg of
                GotStartGameData result -> case result of
                    Ok team -> ({model | state=GameData {ourTeamId = team.id,
                                 tabTeamSelectedPlayer = Nothing,
                                 tab = TabTeam,
                                 ourTeam = team,
                                 fixtures = [],
                                 leagueTables = []
                                }}, Cmd.batch [getFixtures, getLeagueTables])
                    Err error -> ({ model | errorMsg = Just <| toString error}, Cmd.none)
                _ -> ({model | errorMsg = Just "Unexpected message while loading ..."}, Cmd.none)
        handleActiveStateMsgs m =
            case msg of
                ChangeTab tab -> updateState { m | tab = tab }
                ClockTick t ->
                    let (state, cmd) = FixturesView.update FixturesViewMsg.GameTick m
                    in ({ model | state = GameData state}, cmd)
                MsgTeamView msg ->
                    let (state, cmd) = TeamView.update msg m
                    in ({ model | state = GameData state}, cmd)
                MsgFixturesView msg ->
                    let (state, cmd) = FixturesView.update msg m
                    in ({ model | state = GameData state}, cmd)
                UpdateFixtures result -> case result of
                    Ok fixtures -> updateState { m | fixtures = fixtures }
                    Err error -> ({model | errorMsg = Just <| toString error}, Cmd.none)
                LoadGame result -> case result of
                    Ok game -> 
                        if game.status == InProgress then
                            -- start InProgress games from latest event
                            let timeElapsed = List.length game.events -- XXX TODO hack. will only work
                                                                      -- assuming match simulated takes 1 second per event
                            in updateState { m | tab = TabFixtures (Just {
                                game=game,
                                timePoint=Time.second * (toFloat timeElapsed)
                            })}
                        else
                            -- start Played and Scheduled games from beginning
                            updateState { m | tab = TabFixtures (Just { game=game, timePoint=0.0}) }
                    Err error -> ({model | errorMsg = Just <| toString error}, Cmd.none)
                UpdateGame result -> case result of
                    Ok events -> case m.tab of
                        TabFixtures (Just watchingGame) -> updateState {
                            m | tab=TabFixtures (Just <| updateWatchingGame watchingGame events)
                        }
                        _ -> (model, Cmd.none)
                    Err error -> ({model | errorMsg = Just <| toString error}, Cmd.none)
                UpdateLeagueTables result -> case result of
                    Ok tables -> updateState { m | leagueTables = tables }
                    Err error -> ({model | errorMsg = Just <| toString error}, Cmd.none)
                GotStartGameData _ -> ({model | errorMsg = Just "Unexpected message"}, Cmd.none)
                SavedFormation _ -> (model, Cmd.none) -- don't give a fuck

    in
        case model.state of
            Loading -> handleLoadingStateMsgs
            GameData m -> handleActiveStateMsgs m


-- VIEW

tabs : Model -> Html Msg
tabs model =
  let liStyle = style[("display", "block"), ("float", "left"), ("width", "25%"), ("border", "0")]
      tabStyle tab = if model.tab == tab then activeTabStyle else inactiveTabStyle
      tabLabels = [(TabTeam, "Team"), (TabLeagueTables, "Tables"), (TabFixtures Nothing, "Fixtures"), (TabFinances, "Finances")]

  in ul [style [("opacity", "0.9"), ("listStyleType", "none"), ("width", "100%"), ("padding", "0 0 1em 0"), ("top", "0"), ("left", "0"), ("margin", "0"), ("position", "fixed")]]
      (List.map (\(tab, label) ->
          li [liStyle] [button [onClick (ChangeTab tab), tabStyle tab] [text label]]
        )
        tabLabels)

view : RootModel -> Html Msg
view model =
    div [] [
        case model.state of
            Loading -> text <| Maybe.withDefault "Loading ..." model.errorMsg
            GameData m ->
                div [] [
                    tabs m,
                    div [style [("clear", "both"), ("margin", "4em 0 0 0")]] [
                        text <| Maybe.withDefault "" model.errorMsg,
                        case m.tab of
                            TabTeam -> Html.map MsgTeamView <| TeamView.view m m.ourTeam
                            TabLeagueTables -> div [] (List.map (leagueTableTab m) m.leagueTables)
                            TabFixtures maybeWatchingGame -> Html.map MsgFixturesView <| FixturesView.view m maybeWatchingGame
                            TabFinances -> text ""
                        ]
                ]
    ]

leagueTableTab : Model -> LeagueTable -> Html Msg
leagueTableTab model league =
    let recordToTableLine record =
        Html.tr
            [] 
            [
                Html.td [] [text record.name]
              , Html.td [] [record.won + record.drawn + record.lost |> toString |> text]
              , Html.td [] [record.won |> toString |> text]
              , Html.td [] [record.drawn |> toString |> text]
              , Html.td [] [record.lost |> toString |> text]
              , Html.td [] [record.goalsFor |> toString |> text]
              , Html.td [] [record.goalsAgainst |> toString |> text]
              , Html.td [] [record.goalsFor - record.goalsAgainst |> toString |> text]
              , Html.td [] [calcPoints record |> toString |> text]
            ]
  in div [] [
      Html.h2 [] [text <| league.name],
      Html.table [tableStyle] (
      (Html.tr [] [
        Html.th [] [text "Team"]
      , Html.th [] [text "Played"]
      , Html.th [] [text "Won"]
      , Html.th [] [text "Drawn"]
      , Html.th [] [text "Lost"]
      , Html.th [] [text "GF"]
      , Html.th [] [text "GA"]
      , Html.th [] [text "GD"]
      , Html.th [] [text "Points"]
      ]) ::
      (List.map recordToTableLine (sortLeague league.record))
    )]

calcPoints : SeasonRecord -> Int
calcPoints sr = sr.won*3 + sr.drawn*1

sortLeague : List SeasonRecord -> List SeasonRecord
sortLeague sr =
  let ptsDesc a b = if calcPoints a > calcPoints b then LT else (
      if calcPoints a < calcPoints b then GT else
        (if a.goalsFor - a.goalsAgainst > b.goalsFor - b.goalsAgainst then LT else GT)
      )
                    
  in List.sortWith ptsDesc sr
