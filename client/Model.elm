module Model exposing (..)
import Time exposing (Time)

import Types exposing (..)
import TransferMarketTypes
import TeamViewTypes

-- MODEL

type alias WatchingGame = { timePoint: Time, game: Game }
type alias TournamentName = String
type FixtureSubView = TodaysFixtures | AllFixtures TournamentName
type alias TabTransferMarketState = { listings: List Player }

type UiTab = TabTeam TeamViewTypes.State
             | TabTournaments
             | TabTopScorers
             | TabFixtures FixtureSubView
             | TabMatch WatchingGame
             | TabClub
             | TabTransferMarket TransferMarketTypes.State
             | TabViewOtherTeam TeamViewTypes.State
             | TabInbox
             | TabNews

type alias RootModel = {
    errorMsg: Maybe String,
    state: RootState
}

type RootState = Loading | GameData Model

type alias Model = {
    ourTeamId: TeamId,
    currentTime: Time.Time,
    tab: UiTab,
    ourTeam: Team,
    news: List News,
    fixtures: List Fixture,
    leagueTables: List LeagueTable,
    topScorers: List TournamentTopScorers
}
