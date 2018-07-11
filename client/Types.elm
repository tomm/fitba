module Types exposing (..)
import Array exposing (Array)
import Time exposing (Time)

type alias TeamId = Int
type alias Team = { id: TeamId, name: String, players: Array Player, formation: Array (Int, Int), money: Maybe Int }
type alias SeasonRecord = { teamId: TeamId, name: String, played: Int, won: Int, drawn: Int, lost: Int, goalsFor: Int, goalsAgainst: Int }
type alias LeagueTable = { name: String, record: List SeasonRecord }
type alias PlayerId = Int
type alias Player = { id: PlayerId, name: String, shooting: Int, passing: Int, tackling: Int, handling: Int, speed: Int }
type alias TransferListingId = Int
type TransferStatus = OnSale | YouWon | YouLost
type alias TransferListing = { id: TransferListingId, minPrice: Int, deadline: Time,
                               player: Player, youBid: Maybe Int, status: TransferStatus }
type alias GameId = Int
type alias GameEventId = Int
type GameEventKind = KickOff | Goal | Boring | Shot | EndOfGame
type GameEventSide = Home | Away
type alias GameEvent = { id: GameEventId, gameId: GameId, kind: GameEventKind, side: GameEventSide,
                         timestamp: Time, message: String, ballPos: (Int, Int) }
type alias Game = { id: GameId, homeTeam: Team, awayTeam: Team, start: Time, events: List GameEvent, status: FixtureStatus }
type alias FixtureStatusPlayed = { homeGoals: Int, awayGoals: Int }
type FixtureStatus = Scheduled | InProgress | Played FixtureStatusPlayed
type alias Fixture = { gameId: GameId, homeName: String, awayName: String, start: Time, status: FixtureStatus }
