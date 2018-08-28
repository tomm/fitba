module Main exposing (..)

import Array exposing (Array)
import Date
import Debug
import Dict exposing (Dict)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, input, text, ul, li, button)
import Http
import Json.Decode as Json
import Json.Encode as JsonEncode
import Maybe exposing (withDefault)
import Navigation
import Svg
import Task
import Time
import Notification
import Notification exposing (defaultOptions)

import Uitk
import Utils
import TransferMarket
import TransferMarketTypes
import FixturesView
import MatchView
import MatchViewMsg
import TeamViewTypes
import InboxView
import NewsView
import Model exposing (..)
import Types exposing (..)
import RootMsg exposing (..)
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
init = (
        { errorMsg=Nothing, state=Loading},
        Cmd.batch [
            getStartGameData,
            Task.perform RequestNotificationPermissionResult Notification.requestPermission
        ]
    )

-- SUBSCRIPTIONS

subscriptions : RootModel -> Sub Msg
subscriptions model = Sub.batch [
        Time.every Time.second SecondTick,
        Time.every Time.minute MinuteTick
    ]

-- UPDATE

handleHttpError : Http.Error -> RootModel -> (RootModel, Cmd Msg)
handleHttpError error model =
    case error of
        Http.BadStatus response -> 
            if response.status.code == 403 then
                (model , Navigation.load "/login")
            else
                ({model | errorMsg = Just <| toString response}, Cmd.none)
        _ -> ({model | errorMsg = Just <| toString error}, Cmd.none)

popupNotification : String -> String -> Cmd Msg
popupNotification title body =
    Notification.Notification title { defaultOptions | body = Just body }
        |> Notification.create |> Task.attempt NotificationResult

maybeNotifyGameStarting : Model -> Time.Time -> Cmd Msg
maybeNotifyGameStarting model now =
    let ownGameStarting fixture =
            (   (fixture.homeName == model.ourTeam.name) ||
                (fixture.awayName == model.ourTeam.name)
            ) && Utils.timeEqYYMMDDHHMM now (fixture.start - 5*Time.minute)
        opponent fixture =
            if fixture.homeName == model.ourTeam.name then
            fixture.awayName else fixture.homeName
        nextOwnFixture = List.head <| List.filter ownGameStarting model.fixtures
    in
        case nextOwnFixture of
            Nothing -> Cmd.none
            Just fixture -> popupNotification "Fitba" <|
                "Your game against " ++ opponent fixture ++ " will start in 5 minutes"

update : Msg -> RootModel -> (RootModel, Cmd Msg)
update msg model =
    let updateState newState = ({ model | state = GameData newState, errorMsg = Nothing }, Cmd.none)
        updateStateCmd newState cmd = ({ model | state = GameData newState, errorMsg = Nothing }, cmd)
        updateWatchingGame watchingGame update =
            let game = watchingGame.game
            in {watchingGame | game = {game | events = List.append game.events update.events,
                                              attending = update.attending } }
        handleLoadingStateMsgs =
            case msg of
                GotStartGameData result -> case result of
                    Ok team -> ({model | state=GameData {ourTeamId = team.id,
                                 tab = TabTeam { team = team, view = TeamViewTypes.SquadView { selectedPlayer = Nothing } },
                                 ourTeam = team,
                                 currentTime = 0.0, -- would be better not to wait for tick to resolve this...
                                 fixtures = [],
                                 news = [],
                                 topScorers = [],
                                 leagueTables = []
                                }}, Cmd.batch [getFixtures, getLeagueTables])
                    Err error -> handleHttpError error model
                RequestNotificationPermissionResult _ -> (model, Cmd.none)
                _ -> ({model | errorMsg = Just "Unexpected message while loading ..."}, Cmd.none)
        handleActiveStateMsgs m =
            case msg of
                RequestNotificationPermissionResult _ -> (model, Cmd.none)
                NotificationResult _ -> (model, Cmd.none)
                ChangeTab tab ->
                    let cmd = case tab of
                        -- fetch updated poop
                        TabFixtures _ -> getFixtures
                        TabTournaments -> getLeagueTables
                        TabTopScorers -> getTopScorers
                        TabTeam _ -> getStartGameData
                        TabClub -> getStartGameData
                        TabNews -> ClientServer.loadNews
                        _ -> Cmd.none
                    in updateStateCmd { m | tab = tab } cmd
                ViewTransferMarket -> (model, ClientServer.loadTransferListings)
                Watch gameId -> (model, ClientServer.loadGame gameId)
                GotNews result -> case result of
                    Ok news -> updateState { m | news = news }
                    Err error -> handleHttpError error model
                GotTransferListings result -> case result of
                    Ok listings -> updateState { m | tab = TabTransferMarket {
                        view=TransferMarketTypes.ListView, listings=listings } }
                    Err error -> handleHttpError error model
                ViewTeam teamId -> (model, ClientServer.loadTeam teamId)
                ViewTeamLoaded result -> case result of
                    Ok team -> updateState { m | tab = TabViewOtherTeam {
                        team = team,
                        view = TeamViewTypes.SquadView { selectedPlayer = Nothing }
                    } }
                    Err error -> handleHttpError error model
                SecondTick t ->
                    let (state, cmd) = MatchView.update MatchViewMsg.GameTick m
                        state2 = { state | currentTime = t }
                    in ({ model | state = GameData state2}, cmd)
                MinuteTick t ->
                    (model, maybeNotifyGameStarting m t)
                MsgTeamView msg -> case m.tab of
                    TabTeam state ->
                        let (newState, cmd) = TeamView.update msg state
                        in updateStateCmd { m | tab = TabTeam newState,
                                                ourTeam = newState.team } cmd
                    _ -> (model, Cmd.none)
                MsgMatchView msg ->
                    let (state, cmd) = MatchView.update msg m
                    in ({ model | state = GameData state}, cmd)
                MsgTransferMarket msg -> case m.tab of
                    TabTransferMarket state -> 
                        let (newState, cmd) = TransferMarket.update msg state
                        in updateStateCmd { m | tab = TabTransferMarket newState } cmd
                    _ -> (model, Cmd.none)
                UpdateFixtures result -> case result of
                    Ok fixtures -> updateState { m | fixtures = fixtures }
                    Err error -> handleHttpError error model
                LoadGame result -> case result of
                    Ok game -> 
                        if game.status == InProgress then
                            -- start InProgress games from latest event
                            let timeElapsed = List.length game.events -- XXX TODO hack. will only work
                                                                      -- assuming match simulated takes 1 second per event
                            in updateState { m | tab = TabMatch {
                                game=game,
                                timePoint=Time.second * (toFloat timeElapsed)
                            }}
                        else
                            -- start Played and Scheduled games from beginning
                            updateState { m | tab = TabMatch { game=game, timePoint=0.0} }
                    Err error -> handleHttpError error model
                UpdateGame result -> case result of
                    Ok update -> case m.tab of
                        TabMatch watchingGame -> updateState {
                            m | tab=TabMatch (updateWatchingGame watchingGame update)
                        }
                        _ -> (model, Cmd.none)
                    Err error -> handleHttpError error model
                UpdateLeagueTables result -> case result of
                    Ok tables -> updateState { m | leagueTables = tables }
                    Err error -> handleHttpError error model
                UpdateTopScorers result -> case result of
                    Ok scorers -> updateState { m | topScorers = scorers }
                    Err error -> handleHttpError error model
                GotStartGameData result -> case result of
                    Ok team -> updateState { m | ourTeam = team }
                    Err error -> handleHttpError error model
                SavedFormation _ -> (model, Cmd.none) -- don't give a fuck
                SavedBid _ -> (model, Cmd.none) -- don't give a fuck
                SellPlayerResponse _ -> (model, ClientServer.loadTransferListings) -- don't give a fuck
                DeleteInboxMessage msgId ->
                    let team = m.ourTeam
                    in  updateStateCmd { m | ourTeam = { team | inbox = List.filter (\item -> item.id /= msgId) team.inbox } }
                        (ClientServer.deleteInboxMessage msgId)
                DeleteMessageResponse _ -> (model, Cmd.none)
                NoOp -> (model, Cmd.none)

    in
        case model.state of
            Loading -> handleLoadingStateMsgs
            GameData m -> handleActiveStateMsgs m


-- VIEW

tabs : Model -> Html Msg
tabs model =
  let tabStyle tab = if model.tab == tab then class "active-tab-style" else class "inactive-tab-style"
      clubTabLabel = case List.length model.ourTeam.inbox of
          0 -> "Club"
          n -> "(" ++ toString n ++ ") Club"
      tabLabels = [(TabTeam { team = model.ourTeam, view = TeamViewTypes.SquadView { selectedPlayer = Nothing } }, "Squad"),
                   (TabTournaments, "Tournaments"),
                   (TabFixtures TodaysFixtures, "Fixtures"),
                   (TabClub, clubTabLabel)]

  in ul [class "tab-menu"]
      (List.map (\(tab, label) ->
          li [class "tab-item"] [button [onClick (ChangeTab tab), tabStyle tab] [text label]]
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
                    text <| Maybe.withDefault "" model.errorMsg,
                    case m.tab of
                        TabViewOtherTeam state -> Html.map (\_ -> NoOp {- can't edit -}) <| TeamView.view state
                        TabTeam state -> Html.map MsgTeamView <| TeamView.view state
                        TabTournaments -> tournamentTab m
                        TabTopScorers -> topScorerView m
                        TabFixtures subview -> FixturesView.view m subview
                        TabMatch watchingGame -> Html.map MsgMatchView <| MatchView.view watchingGame
                        TabClub -> clubTab m
                        TabTransferMarket state -> Html.map MsgTransferMarket <| TransferMarket.view m.ourTeamId state
                        TabInbox -> InboxView.view m
                        TabNews -> NewsView.view m
                ]
    ]

topScorerView : Model -> Html Msg
topScorerView model =
    let style scorer = if Just model.ourTeam.name == scorer.teamName then [Html.Attributes.class "scorer-own"] else []
        topScorerTable tournamentTopScorers = Uitk.responsiveColumn 12 [
            Uitk.row [
                Uitk.column 1 [],
                Uitk.column 22 [
                    Html.h3 [] [text <| tournamentTopScorers.tournamentName ++ " Top Scorers"],
                    Html.table [] (
                        Html.tr [] [
                            Html.th [] [text "Team"],
                            Html.th [] [text "Player"],
                            Html.th [] [text "Goals"]
                        ] ::
                        List.map (\scorer -> Html.tr (style scorer) [
                            Html.td [] [text <| Maybe.withDefault "" scorer.teamName],
                            Html.td [] [text scorer.playerName],
                            Html.td [] [text <| toString scorer.goals]
                        ]) tournamentTopScorers.topScorers
                    )
                ],
                Uitk.column 1 []
            ]
        ]

    in Uitk.view Nothing (text "Tournaments") [
            Uitk.row <| List.map topScorerTable model.topScorers
        ]

tournamentTab : Model -> Html Msg
tournamentTab model =
    Uitk.view Nothing (text "Tournaments") <| [
            Uitk.blockButtonRow [
                Uitk.column 8 [],
                Uitk.blockButton 8 (ChangeTab TabTopScorers) "Top Scorers",
                Uitk.column 8 []
            ],
            div [] (List.map (leagueTableTab model) model.leagueTables)
        ]

clubTab : Model -> Html Msg
clubTab model =
    let numMsgs = "(" ++ toString (List.length model.ourTeam.inbox) ++ ")"
    in Uitk.view Nothing (text "Club") [
        Html.p [class "center"] [
            text <| "You have " ++ (Utils.moneyFormat <| Maybe.withDefault 0 model.ourTeam.money) ++ " available for transfers."
        ],
        Uitk.blockButtonRow [
            --Uitk.column 0 [],
            Uitk.blockButton 8 ViewTransferMarket "Transfer Market",
            Uitk.blockButton 8 (ChangeTab TabInbox) (numMsgs ++ " Inbox"),
            Uitk.blockButton 8 (ChangeTab TabNews) "News"
            --Uitk.column 0 []
            --Uitk.blockButton 8 NoOp "Something else"
        ]
    ]

leagueTableTab : Model -> LeagueTable -> Html Msg
leagueTableTab model league =
    let recordToTableLine index record =
        Html.tr
            [onClick (ViewTeam record.teamId)] 
            [
                Html.td [] [text <| toString <| index + 1]
              , Html.td [] [text record.name]
              , Html.td [] [record.won + record.drawn + record.lost |> toString |> text]
              , Html.td [] [record.won |> toString |> text]
              , Html.td [] [record.drawn |> toString |> text]
              , Html.td [] [record.lost |> toString |> text]
              , Html.td [] [record.goalsFor |> toString |> text]
              , Html.td [] [record.goalsAgainst |> toString |> text]
              , Html.td [] [record.goalsFor - record.goalsAgainst |> toString |> text]
              , Html.td [] [calcPoints record |> toString |> text]
            ]
    in
        Html.div [] [
            Html.h3 [] [text league.name],
            Html.table [class "league-table"] (
                (Html.tr [] [
                    Html.th [] [text "Pos."]
                  , Html.th [] [text "Team"]
                  , Html.th [] [text "Played"]
                  , Html.th [] [text "Won"]
                  , Html.th [] [text "Drawn"]
                  , Html.th [] [text "Lost"]
                  , Html.th [] [text "GF"]
                  , Html.th [] [text "GA"]
                  , Html.th [] [text "GD"]
                  , Html.th [] [text "Points"]
                ]) ::
                (List.indexedMap recordToTableLine (sortLeague league.record))
            )
        ]

calcPoints : SeasonRecord -> Int
calcPoints sr = sr.won*3 + sr.drawn*1

sortLeague : List SeasonRecord -> List SeasonRecord
sortLeague sr =
  let ptsDesc a b = if calcPoints a > calcPoints b then LT else (
      if calcPoints a < calcPoints b then GT else
        (if a.goalsFor - a.goalsAgainst > b.goalsFor - b.goalsAgainst then LT else GT)
      )
                    
  in List.sortWith ptsDesc sr
