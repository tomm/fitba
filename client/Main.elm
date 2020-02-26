module Main exposing (..)

import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, input, text, ul, li, button)
import Http
import Maybe exposing (withDefault)
import Navigation
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
import HistoryView
import LeagueTableView
import Model exposing (..)
import Types exposing (..)
import RootMsg exposing (..)
import TeamView
import ClientServer exposing (..)

main : Program Never RootModel Msg
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
            getStartGameData
        ]
    )

-- SUBSCRIPTIONS

subscriptions : RootModel -> Sub Msg
subscriptions model = Sub.batch [
        Time.every Time.second SecondTick
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
                    Ok data -> ({model | state=GameData {ourTeamId = data.team.id,
                                 tab = TabTeam { team = data.team, view = TeamViewTypes.SquadView { selectedPlayer = Nothing } },
                                 ourTeam = data.team,
                                 season = data.season,
                                 currentTime = 0.0, -- would be better not to wait for tick to resolve this...
                                 fixtures = [],
                                 news = [],
                                 topScorers = [],
                                 history = Nothing,
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
                        TabHistory -> getHistory (m.season - 1)
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
                ViewHistory season ->
                    if season > 0 && season <= m.season then
                        updateStateCmd { m | history = Nothing } (getHistory season)
                    else (model, Cmd.none)
                UpdateHistory result -> case result of
                    Ok history -> updateState { m | history = Just history }
                    Err error -> handleHttpError error model
                UpdateLeagueTables result -> case result of
                    Ok tables -> updateState { m | leagueTables = tables }
                    Err error -> handleHttpError error model
                UpdateTopScorers result -> case result of
                    Ok scorers -> updateState { m | topScorers = scorers }
                    Err error -> handleHttpError error model
                GotStartGameData result -> case result of
                    Ok data -> updateState { m | ourTeam = data.team, season = data.season }
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
                    Uitk.infoButton (ChangeTab TabInfo),
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
                        TabHistory -> HistoryView.view m
                        TabInfo -> infoTab
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
    Uitk.view Nothing (text <| "Season " ++ toString model.season) <| [
            Uitk.blockButtonRow [
                Uitk.column 8 [],
                Uitk.blockButton 8 (ChangeTab TabTopScorers) "Top Scorers",
                Uitk.column 8 []
            ],
            div [] (List.map (LeagueTableView.view model) model.leagueTables)
        ]

infoTab : Html Msg
infoTab = Uitk.view Nothing (text "Fitba Help!") [
        Uitk.row [
            Uitk.column 1 [],
            Uitk.column 22 [
                Html.h3 [] [text "Squad"],
                Html.h4 [] [text "Skills"],
                Html.p [] [
                    Html.dl [] [
                        Html.dt [] [text "Shooting"],
                        Html.dd [] [text <|
                            "Shooting is important to any player who finds themselves with a chance to score."
                        ]
                    ],
                    Html.dl [] [
                        Html.dt [] [text "Passing"],
                        Html.dd [] [text <|
                            "Passing allows a player to make longer and more accurate passes, crosses, goal kicks and corners."
                        ]
                    ],
                    Html.dl [] [
                        Html.dt [] [text "Tackling"],
                        Html.dd [] [text <|
                            "Tackling allows a player to successfully take the ball from an opposition player."
                        ]
                    ],
                    Html.dl [] [
                        Html.dt [] [text "Handling"],
                        Html.dd [] [text <|
                            "Handling affects an outfield player's ability to dribble, resist tackles and win aerial challenges. " ++
                            "For goalkeepers, handling contributes to their ability to save shots and hold onto the ball."
                        ]
                    ],
                    Html.dl [] [
                        Html.dt [] [text "Speed"],
                        Html.dd [] [text <|
                            "Speed affects an outfield player's ability to dribble, win aerial challenges and intercept opponents' passes. " ++
                            "For goalkeepers, speed contributes to their ability to save shots and particularly penalties."
                        ]
                    ],
                    Html.dl [] [
                        Html.dt [] [text "Form"],
                        Html.dd [] [text <|
                            "A player's form changes over the season. " ++
                            "It is added to every other skill (shooting, passing, tackling, handling, speed). " ++
                            "A player with average skill 5.4 and form +1 will effectively have an average skill of 6.4."
                        ]
                    ]
                ],
                Html.h4 [] [text "Positioning"],
                Html.p [] [text
                    "Players playing in their favoured position(s) will gain a +1 bonus to all skills (shooting, passing, tackling, handling, speed)."
                ]
            ],
            Uitk.column 1 []
        ]
    ]

clubTab : Model -> Html Msg
clubTab model =
    let numMsgs = "(" ++ toString (List.length model.ourTeam.inbox) ++ ")"
    in Uitk.view Nothing (text "Club") [
        Html.p [class "center"] [
            text <| "You have " ++ (Utils.moneyFormat <| Maybe.withDefault 0 model.ourTeam.money) ++ " available for transfers."
        ],
        Uitk.blockButtonRow [
            Uitk.column 2 [],
            Uitk.blockButton 10 ViewTransferMarket "Transfer Market",
            Uitk.blockButton 10 (ChangeTab TabInbox) (numMsgs ++ " Inbox"),
            Uitk.column 2 []
        ],
        Uitk.blockButtonRow [
            Uitk.column 2 [],
            Uitk.blockButton 10 (ChangeTab TabNews) "News",
            Uitk.blockButton 10 (ChangeTab TabHistory) "History",
            Uitk.column 2 []
        ]
    ]
