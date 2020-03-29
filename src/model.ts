import * as Safe from 'safe-portals';
import axios from 'axios';

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
  call: async (args: Args): Promise<Resp> =>
    respType.read((await axios.post(url, argType.write(args))).data)
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
  )
});

const SafeTeam = Safe.obj({
  id: Safe.int,
  name: Safe.str,
  manager: Safe.optional(Safe.str),
  players: Safe.array(SafePlayer),
  formation: Safe.array(
    Safe.tuple(Safe.int, Safe.int)
  )
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

const SafeLeagueTable = Safe.obj({
  name: Safe.str,
  record: Safe.array(SafeTeamLeagueRecord)
});

const SafeGame = Safe.obj({
  gameId: Safe.int,
  tournament: Safe.str,
  homeName: Safe.str,
  awayName: Safe.str,
  start: Safe.dateIso,
  status: Safe.str,
  stage: Safe.optional(Safe.int),
  homeGoals: Safe.int,
  awayGoals: Safe.int,
  homePenalties: Safe.int,
  awayPenalties: Safe.int
});

export type Team = Safe.TypeEncapsulatedBy<typeof SafeTeam>;
export type Player = Safe.TypeEncapsulatedBy<typeof SafePlayer>;
export type LeagueTable = Safe.TypeEncapsulatedBy<typeof SafeLeagueTable>;
export type TeamLeagueRecord = Safe.TypeEncapsulatedBy<typeof SafeTeamLeagueRecord>;
export type Game = Safe.TypeEncapsulatedBy<typeof SafeGame>;
export type RootState = Safe.TypeEncapsulatedBy<typeof SafeRootState>;

export const getFixtures = httpCall(
  '/fixtures',
  Safe.obj({}),
  Safe.array(SafeGame)
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
