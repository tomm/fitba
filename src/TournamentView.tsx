import React from 'react';
import { UiTab, Commands } from './commands';
import CircularProgress from '@material-ui/core/CircularProgress';
import Grid from '@material-ui/core/Grid';
import IconButton from '@material-ui/core/IconButton';
import ArrowBackIcon from '@material-ui/icons/ArrowBack';
import * as model from './model';
import { TeamView } from './TeamView';
import * as Uitk from './Uitk';

function calcPoints(record: model.TeamLeagueRecord) {
  return record.won * 3 + record.drawn * 1
}

function OpponentTeamView(props: { team: model.Team, commands: Commands }) {
  return <>
    <TeamView team={props.team} commands={props.commands} />
  </>;
}

function LeagueTableView(props: {
  league: model.LeagueTable,
  commands: Commands,
  onClickTeam: (teamId: number) => void
}) {

  return <>
    <h3>{ props.league.name }</h3>
    <table className="league-table">
      <tr>
        <th>Pos.</th>
        <th>Team</th>
        <th>Played</th>
        <th>Won</th>
        <th>Drawn</th>
        <th>Lost</th>
        <th>GF</th>
        <th>GA</th>
        <th>GD</th>
        <th>Points</th>
      </tr>
      {
        props.league.record.map((record, idx) =>
          <tr onClick={e => props.onClickTeam(record.teamId)}>
             <td>{ idx + 1 }</td>
             <td>{ record.name }</td>
             <td>{ record.won + record.drawn + record.lost }</td>
             <td>{ record.won }</td>
             <td>{ record.drawn }</td>
             <td>{ record.lost }</td>
             <td>{ record.goalsFor }</td>
             <td>{ record.goalsAgainst }</td>
             <td>{ record.goalsFor - record.goalsAgainst }</td>
             <td>{ calcPoints(record) }</td>
          </tr>
        )
      }
    </table>
  </>
}

export function TournamentView(props: { rootState: model.RootState, commands: Commands }) {

  const [ viewingTeam, setViewingTeam ] = React.useState<model.Team | undefined>(undefined);
  const [ tables, setTables ] = React.useState<model.LeagueTable[] | undefined>(undefined);

  React.useEffect(() => {
    model.getLeagueTables.call({}).then(setTables);
  }, []);

  function handleClickTeam(teamId: number) {
    if (teamId == props.rootState.team.id) {
      // our own team. jump to squad view
      props.commands.openTab(UiTab.SquadTab);
    } else {
      // load from server
      model.getTeam.call({ id: teamId }).then(setViewingTeam);
    }
  }

  return <>
    <Uitk.ButtonBar>
      { viewingTeam &&
        <IconButton>
          <ArrowBackIcon onClick={setViewingTeam.bind(undefined,undefined)}/>
        </IconButton>
      }
    </Uitk.ButtonBar>

    <h2>Season { props.rootState.season }</h2>
    { viewingTeam
      ? <OpponentTeamView team={viewingTeam} commands={props.commands} />

      : !!tables
      ? <Grid container spacing={5}>
          { tables.map(l => 
            <Grid item xs={12}>
              <LeagueTableView league={l} commands={props.commands} onClickTeam={handleClickTeam} />
            </Grid>
            )
          }
        </Grid>
      : <div style={{textAlign: 'center', marginTop: '4rem'}}>
          <CircularProgress />
        </div>
    }
  </>
}
