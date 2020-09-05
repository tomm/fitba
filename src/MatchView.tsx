import * as model from './model';
import * as React from 'react';
import { Commands } from './commands';
import * as Uitk from './Uitk';
import { format, addMilliseconds } from 'date-fns';
import Grid from '@material-ui/core/Grid';
import AppBar from '@material-ui/core/AppBar';
import Tabs from '@material-ui/core/Tabs';
import Tab from '@material-ui/core/Tab';
import Box from '@material-ui/core/Box';
import IconButton from '@material-ui/core/IconButton';
import { TeamView } from './TeamView';
import FastForwardIcon from '@material-ui/icons/FastForward';
import PlayArrowIcon from '@material-ui/icons/PlayArrow';
import PauseIcon from '@material-ui/icons/Pause';
import { bug } from './utils';

const pitchX = 812;
const pitchY = 515;

const latestGameEventAtTimepoint = (game: model.Game, time: Date): model.GameEvent | undefined =>
  eventsUpToTimepoint(game, time)[0];

const eventsUpToTimepoint = (game: model.Game, time: Date): model.GameEvent[] =>
  game.events
    .filter(e => e.timestamp <= time)
    .sort((a, b) => a.timestamp > b.timestamp ? -1 : 1);

const allInterestingEvents = (game: model.Game, time: Date): model.GameEvent[] =>
  eventsUpToTimepoint(game, time).filter(e =>
    e.kind == model.GameEventKind.Goal ||
    e.kind == model.GameEventKind.Injury ||
    e.kind == model.GameEventKind.YellowCard ||
    e.kind == model.GameEventKind.RedCard
  );

const allGoals = (game: model.Game, time: Date): model.GameEvent[] =>
  eventsUpToTimepoint(game, time).filter(e => e.kind == model.GameEventKind.Goal);

// @returns [home goals, away goals]
const goalsBySide = (game: model.Game, time: Date, side: model.GameEventSide): number =>
  allGoals(game, time).reduce((n, e) => e.side == side ? n + 1 : n, 0);


enum MatchTab {
  Pitch,
  HomeTeam,
  AwayTeam
};
interface MatchViewState {
  tab: MatchTab,
  replaySpeed: number,
  time: Date;
  game?: model.Game
};
interface MatchViewProps {
  gameId: number,
  rootState: model.RootState,
  commands: Commands
};
const updateInterval = 0.1;
export class MatchView extends React.Component<MatchViewProps, MatchViewState> {
  drawInterval: NodeJS.Timeout | undefined;
  pollInterval: NodeJS.Timeout | undefined;


  constructor(props: MatchViewProps) {
    super(props);
    this.state = { tab: MatchTab.Pitch, time: new Date(), replaySpeed: 1000 };
  }

  componentDidMount() {
    this.drawInterval = setInterval(this.handleDrawTick.bind(this), 1000 * updateInterval);
    this.pollInterval = setInterval(this.handlePollTick.bind(this), 1000);
    
    model
      .getGame
      .call({ id: this.props.gameId })
      .then(game => {
        // start watching match from current time, unless it is already
        // played, and then watch from game start time
        const time = 
          game.status == model.GameStatus.Played
          ? game.start
          : new Date();

        this.setState({ game, time })
      });
  }

  componentWillUnmount() {
    if (this.drawInterval) clearInterval(this.drawInterval);
    if (this.pollInterval) clearInterval(this.pollInterval);
  }

  handlePollTick() {
    if (this.state.game &&
        this.state.game.status != model.GameStatus.Played) {
      const game = this.state.game;

      // stop polling for new events when the game has ended
      if (game.events.length > 0 &&
          game.events[game.events.length - 1].kind == model.GameEventKind.EndOfGame) {
        return;
      }

      const now = new Date();
      if (game.start <= now) {
        // if the game has started, poll for game events
        model.getGameUpdates.call({
          id: game.id,
          event_id: game.events.length > 0
            ? game.events[game.events.length - 1].id
            : undefined
        }).then(updates => {
          if (!this.state.game) return bug();
          this.setState({
            game: {
              ...this.state.game,
              attending: updates.attending,
              events: [ ...this.state.game.events, ...updates.events ]
            }
          });
          return;
        });
      }
    }
  }

  handleDrawTick() {
    if (this.state.game) {
      // if watching a played game, advance time by 1 second
      // otherwise just follow real time
      const time = 
        this.state.game.status == model.GameStatus.Played
        ? addMilliseconds(this.state.time, updateInterval * this.state.replaySpeed)
        : new Date();
      this.setState({
        game: this.state.game,
        time
      });
    }
  }

  handleChangeTab(event: React.ChangeEvent<{}>, newValue: MatchTab) {
    this.setState({ tab: newValue });
  }

  handleSetSpeed(speed: number) {
    this.setState({ replaySpeed: speed });
  }

  render() {
    if (this.state.game == undefined) {
      return <Uitk.Loading />
    } else {
      const status = this.state.game.status;
      const game = this.state.game;
      const time = this.state.time;
      const homeGoals = goalsBySide(game, time, model.GameEventSide.Home);
      const awayGoals = goalsBySide(game, time, model.GameEventSide.Away);
      return <>
        <Box display="flex" justifyContent="center">
          { status == model.GameStatus.Played &&
            <>
              <Box>
                <IconButton onClick={this.handleSetSpeed.bind(this, 0)}>
                  <PauseIcon />
                </IconButton>
              </Box>
              <Box>
                <IconButton onClick={this.handleSetSpeed.bind(this, 1000)}>
                  <PlayArrowIcon />
                </IconButton>
              </Box>
              <Box>
                <IconButton onClick={this.handleSetSpeed.bind(this, 10000)}>
                  <FastForwardIcon />
                </IconButton>
              </Box>
            </>
          }
          <Box width="100%">
            <h2>
              <span className="home-team">{ game.homeTeam.name }</span>
              <span> ({homeGoals}&nbsp;:&nbsp;{awayGoals}) </span>
              <span className="away-team">{ game.awayTeam.name }</span>
            </h2>
          </Box>
        </Box>

        <AppBar position="static" color="default">
          <Tabs
            value={this.state.tab}
            onChange={this.handleChangeTab.bind(this)}
            indicatorColor="primary"
            textColor="primary"
            variant="fullWidth"
          >
            <Tab value={MatchTab.HomeTeam} label="Home Team" />
            <Tab value={MatchTab.Pitch} label="Match" />
            <Tab value={MatchTab.AwayTeam} label="Away Team" />
          </Tabs>
        </AppBar>

        {
          this.state.tab == MatchTab.HomeTeam
          ? <TeamView team={game.homeTeam} commands={this.props.commands} />
          : this.state.tab == MatchTab.AwayTeam
          ? <TeamView team={game.awayTeam} commands={this.props.commands} />
          : <>
              <PitchView game={game} latestEvent={latestGameEventAtTimepoint(game, time)} />
              <Grid container>
                <Grid xs={6}>
                  { goalSummary(game, time) }
                </Grid>
                <Grid xs={6}>
                  { shotSummary(game, time) }
                  { possessionSummary(game, time) }
                  { attendanceSummary(game) }
                </Grid>
              </Grid>
            </>
        }
      </>
    }
  }
}

function Summary(props: { side: model.GameEventSide; children: any }) {
  const s = props.side == model.GameEventSide.Away ? 'away' : 'home';
  return <div className={`game-summary ${s}-team game-summary-${s}`}>
    { props.children }
  </div>;
}

function attendanceSummary(game: model.Game) {
  return <div>
    <h4>Managers Attending</h4>
    { game.attending.length == 0
      ? <p className="center">None</p>
      : <p className="managers-attending">{ game.attending.join(', ') }</p>
    }
  </div>
}

function possessionSummary(game: model.Game, time: Date) {

  const possession = (side: model.GameEventSide) => {
    const totalEvents: number = eventsUpToTimepoint(game, time).length;
    const ourEvents: number = eventsUpToTimepoint(game, time)
      .reduce((n, e) => e.side == side ? n + 1 : n, 0);

    return <Summary side={side}>
      { ourEvents > 0 && `${(100 * ourEvents / totalEvents).toFixed(0)}%` }
    </Summary>
  }

  return <div>
    <h4 className="game-summary-title">Possession</h4>
    <Grid container>
      <Grid xs={6}>
        { possession(model.GameEventSide.Home) }
      </Grid>
      <Grid xs={6}>
        { possession(model.GameEventSide.Away) }
      </Grid>
    </Grid>
  </div>;
}

function shotSummary(game: model.Game, time: Date) {

  const numTries = (side: model.GameEventSide): number =>
    game.events.filter(e =>
      e.timestamp <= time &&
      e.side == side &&
      e.kind == model.GameEventKind.ShotTry
    ).length;

  const numOnTarget = (side: model.GameEventSide): number =>
    numTries(side) - game.events.filter(e =>
      e.timestamp <= time &&
      e.side == side &&
      e.kind == model.GameEventKind.ShotMiss
    ).length;

  return <div>
    <h4 className="game-summary-title">Total Shots</h4>
    <Grid container>
      <Grid xs={6}>
        <Summary side={model.GameEventSide.Home}>
          { numTries(model.GameEventSide.Home) }
        </Summary>
      </Grid>
      <Grid xs={6}>
        <Summary side={model.GameEventSide.Away}>
          { numTries(model.GameEventSide.Away) }
        </Summary>
      </Grid>
    </Grid>

    <h4 className="game-summary-title">On Target</h4>
    <Grid container>
      <Grid xs={6}>
        <Summary side={model.GameEventSide.Home}>
          { numOnTarget(model.GameEventSide.Home) }
        </Summary>
      </Grid>
      <Grid xs={6}>
        <Summary side={model.GameEventSide.Away}>
          { numOnTarget(model.GameEventSide.Away) }
        </Summary>
      </Grid>
    </Grid>
  </div>;
}

function goalSummary(game: model.Game, time: Date) {

  function summarizeEvent(e: model.GameEvent) {
    const when = secondsToMatchMinute(false, 0.001 * (e.timestamp.getTime() - game.start.getTime()));
    let kind;
    switch (e.kind) {
      case model.GameEventKind.Goal:
        kind = null;
        break;
      case model.GameEventKind.Injury:
        kind = <span className={'injury-icon'}></span>;
        break;
      case model.GameEventKind.YellowCard:
        kind = <span className={'yellowcard-icon'}></span>
        break;
      case model.GameEventKind.RedCard:
        kind = <span className={'redcard-icon'}></span>
        break;
      default:
        return;
    }
    return <div>
      {
        e.side == model.GameEventSide.Home
        ? <> {`${e.playerName} ${when}`} {kind}</>
        : <> {kind} {`${when} ${e.playerName}`}</>
      }
    </div>
  }

  return <div>
    <h4 className="game-summary-title">Goal Summary</h4>
    <Grid container>
      <Grid xs={6} spacing={2}>
        <div className="game-summary home-team game-summary-home">
          { allInterestingEvents(game, time)
              .filter(e => e.side == model.GameEventSide.Home)
              .map(summarizeEvent)
          }
        </div>
      </Grid>
      <Grid xs={6} spacing={2}>
        <div className="game-summary away-team game-summary-away">
          { allInterestingEvents(game, time)
              .filter(e => e.side == model.GameEventSide.Away)
              .map(summarizeEvent)
          }
        </div>
      </Grid>
    </Grid>
  </div>
}

function playerHalfPos(side: model.GameEventSide, pos: [number, number]): [number, number] {
  const xpadding = 50.0
  const ypadding = 50.0
  const xinc = (pitchX - 2 * xpadding) / 12
  const yinc = (pitchY - 2 * ypadding) / 4
  const xSideFlip = side == model.GameEventSide.Home ? 6 - pos[1] : pos[1] + 6;
  const ySideFlip = side == model.GameEventSide.Home ? pos[0] : 4 - pos[0];
  return [ xpadding + xSideFlip * xinc, ypadding + ySideFlip * yinc ];
}

function pitchPosPixelPos(pos: [number, number]): [number, number] {
  const [ x, y ] = pos;
  const xpadding = (y == 0 || y == 6) ? 50.0 : 5.0;
  const ypadding = 50.0;
  const xinc = (pitchX - 2 * xpadding) / 6;
  const yinc = (pitchY - 2 * ypadding) / 4;
  return [ xpadding + (6 - y) * xinc, ypadding + x * yinc ];
}

function sideColor(side: model.GameEventSide): string {
  return side == model.GameEventSide.Home ? 'blue' : 'red';
}

function secondsToMatchMinute(showSeconds: boolean, s: number): string {
  const seconds = showSeconds ? ":00" : "";
  if (s < 3 * 55) {
    const mins = (s / 3);
    if (mins <= 45) return `${mins.toFixed(0)}${seconds}`;
    else return `45+${(mins - 45).toFixed(0)}${seconds}`;
  }
  else if (s < 3 * 105) {
    const mins = (s / 3 - 10);
    if (mins <= 90) return `${mins.toFixed(0)}${seconds}`;
    else return `90+${(mins - 90).toFixed(0)}${seconds}`;
  }
  else if (s < 3 * 125) {
    const mins = (s / 3 - 15);
    if (mins <= 105) return `${mins.toFixed(0)}${seconds}`;
    else `105+${(mins - 105).toFixed(0)}${seconds}`;
  }
  const mins = (s / 3 - 20);
  if (mins <= 120) return `${mins.toFixed(0)}${seconds}`;
  else return `120+${(mins - 120).toFixed(0)}${seconds}`;
}

function matchMinute(game: model.Game, e: model.GameEvent): string {
  return secondsToMatchMinute(true, 0.001 * (e.timestamp.getTime() - game.start.getTime()))
}

function PitchView(props: { latestEvent?: model.GameEvent, game: model.Game }) {

  const drawTeam = (side: model.GameEventSide, team: model.Team) =>
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(idx => drawPlayer(side, team, idx));

  const drawPlayer = (side: model.GameEventSide, team: model.Team, idx: number) => {
    const [ xpos, ypos ] = playerHalfPos(side, team.formation[idx]);
    return <>
      <circle cx={xpos} cy={ypos} r={20} fill={sideColor(side)} fillOpacity={0.2} />
      <text x={xpos} y={ypos + 32} textAnchor="middle"
            className="match-player-label" fill="white" fillOpacity={0.2}>
        { team.players[idx].name }
      </text>
    </>;
  }

  const drawBall = (e: model.GameEvent) => {
    const [ xpos, ypos ] = pitchPosPixelPos(e.ballPos);
    return <g>
      <circle cx={xpos} cy={ypos} r={30} fill={'white'} />
      <circle cx={xpos} cy={ypos} r={15} fill={sideColor(e.side)} />
      <text x={xpos} y={ypos+48} textAnchor="middle"
            className="match-ball-label" fill="white">
        { e.playerName }
      </text>
    </g>
  }

  const matchMessage = (msg: string, color: string) =>
    <g>
      <text x={406} y={32} textAnchor="middle" className="match-event-message"
            fill={color} fillOpacity={1}>
        { msg }
      </text>
    </g>

  const gameTime = (e: model.GameEvent) =>
    <text x={740} y={32} textAnchor="middle" className="match-event-message"
          fill="white" fillOpacity={1}>
      { matchMinute(props.game, e) }
    </text>;

  return <svg width="100%" height="100%" viewBox={`0 0 ${pitchX} ${pitchY}`}>
    <image width="100%" height="100%" xlinkHref="/pitch_h.png" />
    <g>
      { /* draw players */ }
      { drawTeam(model.GameEventSide.Home, props.game.homeTeam) }
      { drawTeam(model.GameEventSide.Away, props.game.awayTeam) }
    </g>
    {
      props.latestEvent
      ? <>
          { drawBall(props.latestEvent) }
          { matchMessage(props.latestEvent.message, sideColor(props.latestEvent.side)) }
          { gameTime(props.latestEvent) }
        </>
      : matchMessage(
        `The match has not started: kick-off on ${format(props.game.start, 'E d MMM HH:mm')}`, 'white'
        )
    }
  </svg>;
}
