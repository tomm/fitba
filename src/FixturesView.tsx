import * as model from './model';
import * as React from 'react';
import { bug } from './utils';
import * as Uitk from './Uitk';
import Select from '@material-ui/core/Select';
import MenuItem from '@material-ui/core/MenuItem';
import Box from '@material-ui/core/Box';
import FormControl from '@material-ui/core/FormControl';
import { MatchView } from './MatchView';
import { Commands } from './commands';
import { format } from 'date-fns';
import { uniq } from 'rambda';

function dateEq(d1: Date, d2: Date) {
  return d1.getFullYear() == d2.getFullYear() &&
         d1.getMonth() == d2.getMonth() &&
         d1.getDate() == d2.getDate();
}

export function resultText(game: model.Fixture): string {
  switch (game.status) {
    case model.GameStatus.Scheduled: return 'Scheduled';
    case model.GameStatus.InProgress: return 'In Progress!';
    case model.GameStatus.Played:
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
  onClickGame: (gameId: number) => void,
  fixtures: model.Fixture[]
}) {
  const rowClass = (game: model.Fixture): string =>
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

  const tournamentText = (game: model.Fixture) =>
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
              onClick={e => props.onClickGame(game.gameId)}>
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

export function FixturesView(props: { rootState: model.RootState, commands: Commands }) {
  const [ fixtures, setFixtures ] = React.useState<model.Fixture[] | undefined>(undefined);
  const [ viewTournamentName, setViewTournamentName ] = React.useState<string>("Today");
  const [ viewGameId, setViewGameId ] = React.useState<number | undefined>(undefined);

  React.useEffect(() => {
    model.getFixtures.call({}).then(setFixtures);
  }, []);

  function handleChangeView(view: string) {
    setViewTournamentName(view);
  }

  function handleClickGame(gameId: number) {
    setViewGameId(gameId);
  }

  const getTournaments = (fixtures: model.Fixture[]): string[] =>
    uniq(fixtures.map(g => g.tournament));

  if (viewGameId != undefined) {
    return <MatchView gameId={viewGameId} {...props} />
  } else {
    return <>
      <h2>Fixtures</h2>
      { fixtures == undefined && <Uitk.Loading /> }
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
            ?  <FixturesTable
                onClickGame={handleClickGame}
                rootState={props.rootState}
                showTournament={true}
                dateFormatter={d => format(d, 'HH:mm')}
                fixtures={fixtures.filter(f => dateEq(f.start, new Date()))}
              />
            : <FixturesTable
                onClickGame={handleClickGame}
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
}
