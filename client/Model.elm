module Model exposing (..)
import Array exposing (Array)
import Date exposing (Date)
import Debug
import Time exposing (Time)

import Types exposing (..)
import TransferMarketTypes

-- MODEL

type alias WatchingGame = { timePoint: Time, game: Game }
type alias TeamTabState = { selectedPlayer: Maybe Int }
type alias TabTransferMarketState = { listings: List Player }

type UiTab = TabTeam TeamTabState |
             TabLeagueTables |
             TabFixtures (Maybe WatchingGame) |
             TabFinances |
             TabTransferMarket TransferMarketTypes.State |
             TabViewOtherTeam (TeamTabState, Team)

type alias RootModel = {
    errorMsg: Maybe String,
    state: RootState
}

type RootState = Loading | GameData Model

type alias Model = {
    ourTeamId: TeamId,
    tab: UiTab,
    ourTeam : Team,
    fixtures: List Fixture,
    leagueTables : List LeagueTable
}
