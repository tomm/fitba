import * as model from './model';
import * as React from 'react';
import { bug } from './utils';
import CircularProgress from '@material-ui/core/CircularProgress';
import Select from '@material-ui/core/Select';
import MenuItem from '@material-ui/core/MenuItem';
import Box from '@material-ui/core/Box';
import FormControl from '@material-ui/core/FormControl';
import { Commands } from './commands';
import { format } from 'date-fns';
const uniq = require('ramda/src/uniq');

function dateEq(d1: Date, d2: Date) {
  return d1.getFullYear() == d2.getFullYear() &&
         d1.getMonth() == d2.getMonth() &&
         d1.getDate() == d2.getDate();
}

function resultText(game: model.Game): string {
  switch (game.status) {
    case 'Scheduled': return 'Scheduled';
    case 'InProgress': return 'In Progress!';
    case 'Played':
      const penalties = game.homePenalties > 0 || game.awayPenalties > 0
        ? ` (${game.homePenalties} : ${game.awayPenalties} P)`
        : '';
      return `${game.homeGoals} : ${game.awayGoals} ${penalties}`;
    default: bug();
  }
}

function FixturesTable(props: {
  rootState: model.RootState,
  showTournament: boolean,
  dateFormatter: (d: Date) => string,
  fixtures: model.Game[]
}) {
  const rowClass = (game: model.Game): string =>
    game.homeTeamId == props.rootState.team.id ||
    game.awayTeamId == props.rootState.team.id
    ? 'fixture-own'
    : 'fixture-other';

  const cupStage = (stage: number): string => {
    switch(stage) {
      case 1: return 'Finals';
      case 2: return 'Semi-Finals';
      case 4: return 'Quarter-Finals';
      case 8: return 'Last 16';
      default: return 'Preliminaries';
    }
  }

  const tournamentText = (game: model.Game) =>
    `${game.tournament} ${game.stage && cupStage(game.stage)}`

  return <div>
    <table>
      <tr>
        <th>Game</th>
        <th>Kickoff</th>
        <th>Result</th>
      </tr>
      {
        props.fixtures.map(game =>
          <tr className={rowClass(game)}
              /*onClick Watch fixture.gameId */>
            <td>
              { props.showTournament
                ? <span className="fixture-tournament">{ tournamentText(game) }</span>
                : game.stage != undefined
                ? <span className="fixture-tournament">{ cupStage(game.stage) }</span>
                : null
              }
              {
                game.homeName + " - " + game.awayName
              }
            </td>
            <td>{ props.dateFormatter(game.start) }</td>
            <td>{ resultText(game) }</td>
          </tr>
        )
      }
    </table>
  </div>
}

function FixturesToday(props: { rootState: model.RootState, fixtures: model.Game[] }) {
  return <FixturesTable
    rootState={props.rootState}
    showTournament={true}
    dateFormatter={d => format(d, 'HH:mm')}
    fixtures={props.fixtures.filter(f => dateEq(f.start, new Date()))}
  />
}

export function FixturesView(props: { rootState: model.RootState, commands: Commands }) {
  const [ fixtures, setFixtures ] = React.useState<model.Game[] | undefined>(undefined);
  const [ viewTournamentName, setViewTournamentName ] = React.useState<string>("Today");

  React.useEffect(() => {
    model.getFixtures.call({}).then(setFixtures);
  }, []);

  function handleChangeView(view: string) {
    setViewTournamentName(view);
  }

  const getTournaments = (fixtures: model.Game[]): string[] =>
    uniq(fixtures.map(g => g.tournament));

  return <>
    <h2>Fixtures</h2>
    { fixtures == undefined &&
      <div style={{textAlign: 'center', marginTop: '4rem'}}>
        <CircularProgress />
      </div>
    }
    { fixtures != undefined &&
      <>
        <Box display="flex" justifyContent="center" padding={2}>
          <FormControl variant="outlined">
            <Select
              value={viewTournamentName}
              onChange={(e: any) => handleChangeView(e.target.value)}
            >
              <MenuItem value="Today">Today&apos;s Fixtures</MenuItem>
              {
                getTournaments(fixtures).map(tournamentName =>
                  <MenuItem value={tournamentName}>{ tournamentName }, Season { props.rootState.season }</MenuItem>
                )
              }
            </Select>
          </FormControl>
        </Box>
        { viewTournamentName == 'Today'
          ? <FixturesToday rootState={props.rootState} fixtures={fixtures} />
          : <FixturesTable
              rootState={props.rootState}
              showTournament={false}
              dateFormatter={d => format(d, 'E d MMM HH:mm')}
              fixtures={fixtures.filter(f => f.tournament == viewTournamentName)}
            />
        }
      </>
    }
  </>;
}
