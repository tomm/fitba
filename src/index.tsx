import React from 'react';
import ReactDOM from 'react-dom';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import * as Uitk from './Uitk';
import { makeStyles } from '@material-ui/core/styles';
import * as model from './model';
import { TeamView } from './TeamView';
import { UiTab, Commands } from './commands';
import { HelpPage } from './HelpPage';
import { TournamentView } from './TournamentView';
import { FixturesView } from './FixturesView';
import { ClubView } from './ClubView';
import QueryBuilderOutlinedIcon from '@material-ui/icons/QueryBuilderOutlined';
import PeopleAltOutlinedIcon from '@material-ui/icons/PeopleAltOutlined';
import ViewListIcon from '@material-ui/icons/ViewList';
import ClassOutlinedIcon from '@material-ui/icons/ClassOutlined';
import MenuOutlinedIcon from '@material-ui/icons/MenuOutlined';
import './style.css';
const clone = require('ramda/src/clone');

const useStyles = makeStyles(theme => ({
  root: {
    flexGrow: 1,
  },
}));

function TabPanel(props: any) {
  const { children, value, index } = props;

  return (
    <div className="view-content">
      {value === index && children }
    </div>
  );
}

function App(props: {
  rootState: model.RootState,
  requestReloadRootState: () => void,
  updateRootState: (newRootState: model.RootState) => void
}) {
  const handleChangeTab = (event: any, index: number) => setTab(index);
  const [ tab, setTab ] = React.useState<UiTab>(0);

  const commands: Commands = {
    async deleteInboxMessage(id: number): Promise<void> {
      await model.deleteInboxMessage.call({ message_id: id })
                 .then(props.requestReloadRootState);
    },

    reloadRootState() {
      props.requestReloadRootState();
    },

    openTab(tab: UiTab) {
      setTab(tab);
    },

    isOwnTeam(teamId: number): boolean {
      return teamId === props.rootState.team.id;
    },

    async swapPlayers(t: model.Team, idx1: model.PlayerIdx, idx2: model.PlayerIdx): Promise<void> {
      if (t.id != props.rootState.team.id) {
        throw new Error("Tried to swapPlayers on opponent's team");
      }
      if (idx1 >= t.players.length || idx2 >= t.players.length) {
        throw new Error("Player idx out of range in swapPlayers");
      }

      const newTeam = clone(t);
      const tmp = newTeam.players[idx1];
      newTeam.players[idx1] = newTeam.players[idx2];
      newTeam.players[idx2] = tmp;

      props.updateRootState({
        ...props.rootState,
        team: newTeam
      });

      model.saveFormation.call(newTeam);
    },

    async movePlayer(t: model.Team, idx: model.PlayerIdx, pos: [number, number]): Promise<void> {
      if (t.id != props.rootState.team.id) {
        throw new Error("Tried to swapPlayers on opponent's team");
      }

      const newTeam = clone(t);
      newTeam.formation[idx] = pos;

      props.updateRootState({
        ...props.rootState,
        team: newTeam
      });

      model.saveFormation.call(newTeam);
    },

    async sellPlayer(p: model.Player): Promise<void> {
      // XXXs should check it's our player?
      await model.sellPlayer.call({ player_id: p.id });
    }
  };

  return <>
    <AppBar position="static">
      <Tabs /*variant={'scrollable'} scrollButtons={'on'}*/ value={tab} onChange={handleChangeTab}>
        <Tab icon={<PeopleAltOutlinedIcon />} id="tab-0" />
        <Tab icon={<ViewListIcon />} id="tab-1" />
        <Tab icon={<QueryBuilderOutlinedIcon />} id="tab-2" />
        <Tab icon={<ClassOutlinedIcon />} id="tab-3" />
        <Tab icon={<MenuOutlinedIcon />} id="tab-4" />
      </Tabs>
    </AppBar>
    <TabPanel value={tab} index={0}>
      <TeamView team={props.rootState.team} commands={commands} />
    </TabPanel>
    <TabPanel value={tab} index={1}>
      <TournamentView commands={commands} rootState={props.rootState} />
    </TabPanel>
    <TabPanel value={tab} index={2}>
      <FixturesView commands={commands} rootState={props.rootState} />
    </TabPanel>
    <TabPanel value={tab} index={3}>
      <ClubView commands={commands} rootState={props.rootState} />
    </TabPanel>
    <TabPanel value={tab} index={4}>
      <HelpPage />
    </TabPanel>
  </>;
}

function Loader() {
  const classes = useStyles();
  const [ rootState, setRootState ] = React.useState<model.RootState | undefined>(undefined);

  function handleReloadRootState() {
    model.getRootState.call({}).then(setRootState);
  }

  React.useEffect(handleReloadRootState, []);

  return <div className={classes.root}>
    { rootState === undefined
      ? <Uitk.Loading />
      : <App rootState={rootState} updateRootState={setRootState} requestReloadRootState={handleReloadRootState} />
    }
  </div>
}

ReactDOM.render(<Loader />, document.getElementById('main'));
