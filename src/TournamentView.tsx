import React from 'react';
import { UiTab, Commands } from './commands';
import Grid from '@material-ui/core/Grid';
import IconButton from '@material-ui/core/IconButton';
import ArrowBackIcon from '@material-ui/icons/ArrowBack';
import * as model from './model';
import { TeamView } from './TeamView';
import { LeagueTableView } from './LeagueTableView';
import * as Uitk from './Uitk';

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
              <LeagueTableView league={l} onClickTeam={handleClickTeam} />
            </Grid>
            )
          }
        </Grid>
      : <Uitk.Loading />
    }
  </>
}

function OpponentTeamView(props: { team: model.Team, commands: Commands }) {
  return <>
    <TeamView team={props.team} commands={props.commands} />
  </>;
}
