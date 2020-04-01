import * as Safe from 'safe-portals';
import axios from 'axios';
import { bug } from './utils';

// index of player on team.players array
export type PlayerIdx = number;

interface HttpCall<Args,Resp> {
  url: string,
  argType: Safe.Obj<Args>,
  respType: Safe.Type<Resp>,
  call: (args: Args) => Promise<Resp>
}

const httpCall = <Args, Resp>(
  url: string, argType: Safe.Obj<Args>, respType: Safe.Type<Resp>
): HttpCall<Args, Resp> => ({
  url, argType, respType, 
  call: async (args: Args): Promise<Resp> => {
    return axios.post(url, argType.write(args))
      .then(v => respType.read(v.data))
      .catch(e => {
        if (e?.response?.status == 403) {
          window.location.pathname = '/login';
        }
        throw e;
      });
  }
});

const SafePlayer = Safe.obj({
  id: Safe.int,
  name: Safe.str,
  age: Safe.int,
  forename: Safe.str,
  shooting: Safe.int,
  passing: Safe.int,
  tackling: Safe.int,
  handling: Safe.int,
  speed: Safe.int,
  injury: Safe.int,
  form: Safe.int,
  positions: Safe.array(
    Safe.tuple(Safe.int, Safe.int)
  ),
  is_transfer_listed: Safe.bool
});

const SafeInboxMessage = Safe.obj({
  id: Safe.int,
  from: Safe.str,
  subject: Safe.str,
  body: Safe.str,
  date: Safe.dateIso
});

const SafeTeam = Safe.obj({
  id: Safe.int,
  name: Safe.str,
  manager: Safe.optional(Safe.str),
  players: Safe.array(SafePlayer),
  formation: Safe.array(
    Safe.tuple(Safe.int, Safe.int)
  ),
  money: Safe.optional(Safe.int),
  inbox: Safe.array(SafeInboxMessage)
});

const SafeRootState = Safe.obj({
  season: Safe.int,
  team: SafeTeam
});

const SafeTeamLeagueRecord = Safe.obj({
  teamId: Safe.int,
  name: Safe.str,
  played: Safe.int,
  won: Safe.int,
  drawn: Safe.int,
  lost: Safe.int,
  goalsFor: Safe.int,
  goalsAgainst: Safe.int
});

const SafeTransferListing = Safe.obj({
  id: Safe.int,
  minPrice: Safe.int,
  deadline: Safe.dateIso,
  sellerTeamId: Safe.int,
  player: SafePlayer,
  youBid: Safe.optional(Safe.int),
  status: Safe.oneOf({
    'OnSale': '', 'Sold': '', 'Unsold': '', 'YouWon': '', 'OutBid': '',
    'TeamRejected': '', 'PlayerRejected': '', 'InsufficientMoney': ''
  })
});

export enum GameStatus {
  Scheduled,
  InProgress,
  Played
};

const SafeGameStatus: Safe.Type<GameStatus> = {
  container: 'none',
  read: (o: any): GameStatus => {
    switch (o) {
      case "Scheduled": return GameStatus.Scheduled;
      case "InProgress": return GameStatus.InProgress;
      case "Played": return GameStatus.Played;
      default: bug(`Unknown GameStatus: ${o}`);
    }
  },
  write: (e: GameStatus): any => bug('SafeGameStatus write not implemented')
};

const SafeLeagueTable = Safe.obj({
  name: Safe.str,
  record: Safe.array(SafeTeamLeagueRecord)
});

const SafeFixture = Safe.obj({
  gameId: Safe.int,
  tournament: Safe.str,
  homeTeamId: Safe.int,
  awayTeamId: Safe.int,
  homeName: Safe.str,
  awayName: Safe.str,
  start: Safe.dateIso,
  status: SafeGameStatus,
  stage: Safe.optional(Safe.int),
  homeGoals: Safe.int,
  awayGoals: Safe.int,
  homePenalties: Safe.int,
  awayPenalties: Safe.int
});

export enum GameEventKind {
  KickOff, Goal, GoalKick, Corner, Boring, ShotTry, ShotMiss, ShotSaved, EndOfGame
};

export enum GameEventSide {
  Home, Away
};

const SafeGameEventKind: Safe.Type<GameEventKind> = {
  container: 'none',
  read: (o: any): GameEventKind => {
    switch (o) {
      case "KickOff": return GameEventKind.KickOff;
      case "Goal": return GameEventKind.Goal;
      case "GoalKick": return GameEventKind.GoalKick;
      case "Corner": return GameEventKind.Corner;
      case "ShotTry": return GameEventKind.ShotTry;
      case "ShotMiss": return GameEventKind.ShotMiss;
      case "ShotSaved": return GameEventKind.ShotSaved;
      case "Boring": return GameEventKind.Boring;
      case "EndOfPeriod": return GameEventKind.Boring;
      case "Injury": return GameEventKind.Boring;
      case "Sub": return GameEventKind.Boring;
      case "EndOfGame": return GameEventKind.EndOfGame;
      default: bug(`Unknown GameEventKind: ${o}`);
    }
  },
  write: (e: GameEventKind): any => bug('SafeGameEventKind write not implemented')
};

const SafeGameEventSide: Safe.Type<GameEventSide> = {
  container: 'none',
  read: (o: any): GameEventSide => {
    switch (o) {
      case 0: return GameEventSide.Home;
      case 1: return GameEventSide.Away;
      default: bug(`Unknown GameEventSide: ${o}`);
    }
  },
  write: (e: GameEventSide): any => bug('SafeGameEventSide write not implemented')
};

const SafeGameEvent = Safe.obj({
  id: Safe.int,
  gameId: Safe.int,
  kind: SafeGameEventKind,
  side: SafeGameEventSide,
  timestamp: Safe.dateIso,
  message: Safe.str,
  ballPos: Safe.tuple(Safe.int, Safe.int),
  playerName: Safe.optional(Safe.str)
});

const SafeGame = Safe.obj({
  id: Safe.int,
  homeTeam: SafeTeam,
  awayTeam: SafeTeam,
  start: Safe.dateIso,
  events: Safe.array(SafeGameEvent),
  status: SafeGameStatus,
  homeGoals: Safe.int,
  awayGoals: Safe.int,
  homePenalties: Safe.int,
  awayPenalties: Safe.int,
  attending: Safe.array(Safe.str),
  stage: Safe.optional(Safe.int),
});

const SafeNews = Safe.obj({
  title: Safe.str,
  body: Safe.str,
  date: Safe.dateIso
});

const SafeSeasonHistory = Safe.obj({
  season: Safe.int,
  leagues: Safe.array(SafeLeagueTable),
  cup_finals: Safe.array(SafeFixture)
});

const SafeTopScorers = Safe.array(
  Safe.obj({
    tournamentName: Safe.str,
    topScorers: Safe.array(
      Safe.obj({
        teamname: Safe.optional(Safe.str),
        playername: Safe.str,
        goals: Safe.int
      })
    )
  })
);

export type Team = Safe.TypeEncapsulatedBy<typeof SafeTeam>;
export type Player = Safe.TypeEncapsulatedBy<typeof SafePlayer>;
export type LeagueTable = Safe.TypeEncapsulatedBy<typeof SafeLeagueTable>;
export type TeamLeagueRecord = Safe.TypeEncapsulatedBy<typeof SafeTeamLeagueRecord>;
export type Fixture = Safe.TypeEncapsulatedBy<typeof SafeFixture>;
export type Game = Safe.TypeEncapsulatedBy<typeof SafeGame>;
export type GameEvent = Safe.TypeEncapsulatedBy<typeof SafeGameEvent>;
export type RootState = Safe.TypeEncapsulatedBy<typeof SafeRootState>;
export type News = Safe.TypeEncapsulatedBy<typeof SafeNews>;
export type InboxMessage = Safe.TypeEncapsulatedBy<typeof SafeInboxMessage>;
export type SeasonHistory = Safe.TypeEncapsulatedBy<typeof SafeSeasonHistory>;
export type TransferListing = Safe.TypeEncapsulatedBy<typeof SafeTransferListing>;
export type TopScorers = Safe.TypeEncapsulatedBy<typeof SafeTopScorers>;

export const getGame = httpCall(
  '/get_game',
  Safe.obj({ id: Safe.int }),
  SafeGame
);

export const getFixtures = httpCall(
  '/fixtures',
  Safe.obj({}),
  Safe.array(SafeFixture)
);

export const getTeam = httpCall(
  '/squad/',
  Safe.obj({
    id: Safe.int
  }),
  SafeTeam
);

export const getRootState = httpCall(
  '/load_world',
  Safe.obj({}),
  SafeRootState
);

export const saveFormation = {
  call: async function(t: Team): Promise<void> {
    await axios.post(
      '/save_formation',
      t.players.map((p, idx) => [p.id, t.formation[idx]])
    )
  }
}

export const sellPlayer = httpCall(
  '/sell_player',
  Safe.obj({
    player_id: Safe.int
  }),
  Safe.nothing
);

export const getLeagueTables = httpCall(
  '/tables',
  Safe.obj({}),
  Safe.array(SafeLeagueTable)
);

export const getGameUpdates = httpCall(
  '/game_events_since',
  Safe.obj({
    id: Safe.int,
    event_id: Safe.optional(Safe.int)
  }),
  Safe.obj({
    attending: Safe.array(Safe.str),
    events: Safe.array(SafeGameEvent)
  })
);

export const getNews = httpCall(
  '/news_articles',
  Safe.obj({}),
  Safe.array(SafeNews)
);

export const getSeasonHistory = httpCall(
  '/history',
  Safe.obj({ season: Safe.int }),
  SafeSeasonHistory
);

export const deleteInboxMessage = httpCall(
  '/delete_message',
  Safe.obj({ message_id: Safe.int }),
  Safe.nothing
);

export const getTransferListings = httpCall(
  '/transfer_listings',
  Safe.obj({}),
  Safe.array(SafeTransferListing)
);

export const makeBid = httpCall(
  '/transfer_bid',
  Safe.obj({
    amount: Safe.optional(Safe.float),
    transfer_listing_id: Safe.int
  }),
  Safe.nothing
);

export const getTopScorers = httpCall(
  '/top_scorers',
  Safe.obj({
    season: Safe.int
  }),
  SafeTopScorers
);
