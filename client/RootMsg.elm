module RootMsg exposing (..)

import Http
import MatchViewMsg
import Model exposing (..)
import TeamViewTypes
import Time
import TransferMarketTypes
import Types exposing (..)


type Msg
    = ChangeTab UiTab
    | MsgTeamView TeamViewTypes.Msg
    | SecondTick Time.Posix
    | MinuteTick Time.Posix
    | MsgMatchView MatchViewMsg.Msg
    | MsgTransferMarket TransferMarketTypes.Msg
    | UpdateHistory (Result Http.Error History)
    | UpdateFixtures (Result Http.Error (List Fixture))
    | UpdateLeagueTables (Result Http.Error (List LeagueTable))
    | UpdateTopScorers (Result Http.Error (List TournamentTopScorers))
    | LoadGame (Result Http.Error Game)
    | UpdateGame (Result Http.Error GameEventUpdate)
    | GotStartGameData (Result Http.Error StartGameData)
    | SavedFormation (Result Http.Error String)
    | SavedBid (Result Http.Error String)
    | ViewTeam TeamId
    | ViewTeamLoaded (Result Http.Error Team)
    | ViewTransferMarket
    | GotNews (Result Http.Error (List News))
    | GotTransferListings (Result Http.Error (List Types.TransferListing))
    | SellPlayerResponse (Result Http.Error String)
    | DeleteInboxMessage InboxMessageId
    | DeleteMessageResponse (Result Http.Error String)
    | Watch GameId
    | ViewHistory Season
    | NoOp
