module Model exposing (..)
import Array exposing (Array)
import Dict exposing (Dict)
import Date exposing (Date)
import Debug
import Time exposing (Time)

-- MODEL

type alias WatchingGame = { timePoint: Time, game: Game }

type UiTab = TabTeam | TabLeagueTables | TabFixtures (Maybe WatchingGame) | TabFinances

type alias RootModel = {
    errorMsg: Maybe String,
    state: RootState
}

type RootState = Loading | GameData Model

type alias Model = {
    ourTeamId: TeamId,
    tabTeamSelectedPlayer: Maybe Int,
    tab: UiTab,
    ourTeam : Team,
    fixtures: List Fixture,
    leagueTables : List LeagueTable
}

type alias TeamId = Int
type alias Team = { id: TeamId, name: String, players: Array Player, formation: Array (Int, Int) }

type alias SeasonRecord = { teamId: TeamId, name: String, played: Int, won: Int, drawn: Int, lost: Int, goalsFor: Int, goalsAgainst: Int }
type alias LeagueTable = { name: String, record: List SeasonRecord }

{-
premierLeague : LeagueTable
premierLeague = { name="Scottish Premier Division", record=[
  { teamId=1, name="Rangers", played=1, won=0, drawn=0, lost=1, goalsFor=0, goalsAgainst=2 },
  { teamId=2, name="Celtic", played=1, won=1, drawn=0, lost=0, goalsFor=2, goalsAgainst=0 }
  ]}
-}

type alias PlayerId = Int
type alias Player = { id: PlayerId, name: String, shooting: Int, passing: Int, tackling: Int, handling: Int, speed: Int }

type alias GameId = Int
type alias GameEventId = Int
type GameEventKind = KickOff | Goal | Boring | Shot | EndOfGame
type GameEventSide = Home | Away
type alias GameEvent = { id: GameEventId, gameId: GameId, kind: GameEventKind, side: GameEventSide, timestamp: Time, message: String, ballPos: (Int, Int) }
type alias Game = { id: GameId, homeTeam: Team, awayTeam: Team, start: Time, events: List GameEvent }

type alias FixtureStatusPlayed = { homeGoals: Int, awayGoals: Int }
type FixtureStatus = Scheduled | Played FixtureStatusPlayed
type alias Fixture = { gameId: GameId, homeName: String, awayName: String, start: Time, status: FixtureStatus }
