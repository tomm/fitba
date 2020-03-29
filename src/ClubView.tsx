import React from 'react';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import * as model from './model';
import { UiTab, Commands } from './commands';
import { NewsView } from './NewsView';
import { InboxView } from './InboxView';
import { SeasonHistoryView } from './SeasonHistoryView';
import { TransferMarketView } from './TransferMarketView';

function TabPanel(props: any) {
  const { children, value, index } = props;

  return (
    <div className="view-content">
      {value === index && children }
    </div>
  );
}

export function ClubView(props: { rootState: model.RootState, commands: Commands }) {
  const [ tab, setTab ] = React.useState<UiTab>(0);

  React.useEffect(() => {
    // check for new inbox messages. this actually does a complete reload, which is a bit inefficient...
    props.commands.reloadRootState();
  }, []);

  function inboxLabel() {
    if (props.rootState.team.inbox.length == 0) {
      return "Inbox";
    } else {
      return `Inbox (${props.rootState.team.inbox.length})`;
    }
  }

  function deleteMessage(msgId: number) {
    props.commands.deleteInboxMessage(msgId);
  }

  return <>
    <AppBar position="static" color="default">
      <Tabs value={tab} onChange={(e, idx) => setTab(idx)}
            variant={'scrollable'} scrollButtons={'on'} >
        <Tab label="News" />
        <Tab label="Transfers" />
        <Tab label={inboxLabel()} />
        <Tab label="Records" />
      </Tabs>
    </AppBar>;
    <TabPanel value={tab} index={0}>
      <NewsView />
    </TabPanel>
    <TabPanel value={tab} index={1}>
      <TransferMarketView ownTeam={props.rootState.team} />
    </TabPanel>
    <TabPanel value={tab} index={2}>
      <InboxView inbox={props.rootState.team.inbox}
                 onClickDeleteMessage={deleteMessage} />
    </TabPanel>
    <TabPanel value={tab} index={3}>
      <SeasonHistoryView ownTeam={props.rootState.team} currentSeason={props.rootState.season} />
    </TabPanel>
  </>;
}
