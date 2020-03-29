import React from 'react';
import * as model from './model';
import Box from '@material-ui/core/Box';
import IconButton from '@material-ui/core/IconButton';
import ArrowBackIcon from '@material-ui/icons/ArrowBack';
import ArrowForwardIcon from '@material-ui/icons/ArrowForward';
import { LeagueTableView } from './LeagueTableView';
import * as Uitk from './Uitk';
import { resultText } from './FixturesView';

function TopScorersView(props: { ownTeam: model.Team, season: number }) {
  const [ stats, setStats ] = React.useState<model.TopScorers | undefined>(undefined);

  React.useEffect(() => {
    model.getTopScorers.call({ season: props.season }).then(setStats);
  }, []);

  if (stats == undefined) {
    return <Uitk.Loading />;
  } else {
    return <>
      {
        stats.map(t => <>
          <h3>{ t.tournamentName } Top Scorers</h3>
          <table>
            <tr>
              <th>Team</th>
              <th>Player</th>
              <th>Goals</th>
            </tr>
            { t.topScorers.map(p =>
                <tr className={ p.teamname == props.ownTeam.name ? 'scorer-own' : '' }>
                  <td>{ p.teamname }</td>
                  <td>{ p.playername }</td>
                  <td>{ p.goals }</td>
                </tr>)
            }
          </table>
        </>)
      }
    </>;
  }
}

export function SeasonHistoryView(props: { ownTeam: model.Team, currentSeason: number }) {

  const [ history, setHistory ] = React.useState<model.SeasonHistory | undefined>(undefined);
  const [ season, setSeason ] = React.useState<number>(props.currentSeason - 1);

  React.useEffect(() => reloadSeason(season), []);

  function reloadSeason(s: number) {
    model.getSeasonHistory.call({ season: s }).then(setHistory);
  }

  function handleChangeSeason(inc: number) {
    const s = Math.min(Math.max(1, season + inc), props.currentSeason);
    if (s != season) {
      setSeason(s);
      setHistory(undefined);
      reloadSeason(s);
    }
  }

  if (history == undefined) {
    return <Uitk.Loading />;
  } else {
    return <>
      <h2>Club History</h2>
      <Box display="flex" justifyContent="center">
        <Box>
          <IconButton onClick={e => handleChangeSeason(-1)}>
            <ArrowBackIcon />
          </IconButton>
        </Box>
        <Box width="100%">
          <h3>Season { season }</h3>
        </Box>
        <Box>
          <IconButton onClick={e => handleChangeSeason(1)}>
            <ArrowForwardIcon />
          </IconButton>
        </Box>
      </Box>
      <h3>Cup Finals</h3>
      { (history.cup_finals.length > 0) &&
        <table>
          { history.cup_finals.map(f =>
              <>
                <tr>
                  <th className="center" colSpan={3}>{ f.tournament }</th>
                </tr>
                <tr>
                  <td className="cup-finals-history">{ f.homeName }</td>
                  <td className="cup-finals-history">{ resultText(f) }</td>
                  <td className="cup-finals-history">{ f.awayName }</td>
                </tr>
              </>
            )
          }
        </table>
      }
      <div>
        {
          history.leagues.map(l =>
            <LeagueTableView league={l} onClickTeam={() => {}} />
          )
        }
      </div>
      <TopScorersView ownTeam={props.ownTeam} season={season} />
    </>;
  }
}
