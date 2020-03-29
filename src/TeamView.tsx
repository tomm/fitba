import React from 'react';
import * as model from './model';
import Grid from '@material-ui/core/Grid';
import Switch from '@material-ui/core/Switch';
import PersonIcon from '@material-ui/icons/Person';
import IconButton from '@material-ui/core/IconButton';
import Button from '@material-ui/core/Button';
import DialogTitle from '@material-ui/core/DialogTitle';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import { ConfirmDialog } from './ConfirmDialog';
//import DialogContentText from '@material-ui/core/DialogContentText';
import * as Uitk from './Uitk';
import * as logic from './logic';
import { Commands } from './commands';
import { bug } from './utils';
const includes = require('ramda/src/includes');
const take = require('ramda/src/take');
const flatten = require('ramda/src/flatten');
const unnest = require('ramda/src/unnest');

const positionCircleRadius = 75;
const playerGoodPositionOpacity = 0.5;
const playerBadPositionOpacity = 0.1;
const pitchX = 812;
const pitchY = 1280;

function pitchPosPixelPos(pos: [number, number]): [number, number] {
  const xpadding = 100;
  const ypadding = 100;
  const xinc = (pitchX - 2 * xpadding) / 4;
  const yinc = (pitchY - 2 * ypadding) / 6;
  return [xpadding + pos[0]*xinc, ypadding + pos[1]*yinc];
}

function PlayerOnPitch(props: { team: model.Team,
                                selected: model.PlayerIdx | undefined,
                                pos: [number, number],
                                playerIdx: model.PlayerIdx,
                                onSelect: () => void })
{
  const player: model.Player | undefined = props.team.players[props.playerIdx];
  const positionSuitsSelectedPlayer =
    props.selected
    ? includes(props.pos, props.team.players[props.selected].positions)
    : false;

  const [ label, color ] = player === undefined
    ? [ "Empty!", "red" ]
    : [ player.name,
        props.selected == props.playerIdx
        ? '#8080ff'
        : (includes(props.pos, player.positions) && player.injury == 0)
        ? 'white'
        : '#f77'
      ];

  const opacity = positionSuitsSelectedPlayer
    ? playerGoodPositionOpacity
    : playerBadPositionOpacity;

  const pitchPos = pitchPosPixelPos(props.pos);
    
  return <g>
    <circle
      onClick={() => props.onSelect()}
      cx={pitchPos[0]}
      cy={pitchPos[1]}
      r={positionCircleRadius}
      fill="black"
      fillOpacity={opacity}
    />
    <text
      onClick={() => props.onSelect()}
      textAnchor='middle'
      fill={color}
      x={pitchPos[0]}
      y={pitchPos[1]}
      fontSize={26}
    >
      <tspan x={pitchPos[0]} dy={-10}>
        { props.playerIdx + 1 }
      </tspan>
      <tspan x={pitchPos[0]} dy={30}>
        { label }
      </tspan>
    </text>
  </g>
} 

function teamTitle(t: model.Team): string {
  return `${t.name} (${t.manager || 'A.I. Manager'})`;
}

export function TeamView(props: { team: model.Team, commands: Commands }) {
  return <>
    <h2>{ teamTitle(props.team) }</h2>
    <Grid container spacing={5}>
      <Grid item sm={6} xs={12}>
        <h3>Squad</h3>
        <RosterView team={props.team} commands={props.commands} />
      </Grid>
      <Grid item sm={6} xs={12}>
        <h3>Formation</h3>
        <TacticsView team={props.team} commands={props.commands} />
      </Grid>
    </Grid>
  </>;
}

function PlayerDetailsDialog(props: {
  open: boolean,
  player: model.Player,
  handleClose: () => void,
  handleClickSell?: () => void
}) {
  return <>
    <Dialog onClose={props.handleClose} open={props.open}>
      <DialogTitle>{ props.player.forename } { props.player.name }</DialogTitle>
      <DialogContent>
        <table>
          <tr><th>Name</th><td>{ props.player.forename } { props.player.name }</td></tr>
          <tr><th>Age</th><td>{ props.player.age }</td></tr>
          <tr><th>Favoured Positions</th><td><Uitk.PlayerPositionBadge player={props.player} /></td></tr>
          <tr><th>Skill Average</th><td>{ logic.playerAvgSkill(props.player).toFixed(1) }</td></tr>
          <tr><th>Shooting</th><td>{ props.player.shooting }</td></tr>
          <tr><th>Passing</th><td>{ props.player.passing }</td></tr>
          <tr><th>Tackling</th><td>{ props.player.tackling }</td></tr>
          <tr><th>Handling</th><td>{ props.player.handling }</td></tr>
          <tr><th>Speed</th><td>{ props.player.speed }</td></tr>
        </table>
      </DialogContent>
      <DialogActions>
        <Button onClick={props.handleClose} color="primary">
          Back
        </Button>
        { props.handleClickSell &&
          <Button onClick={props.handleClickSell} color="secondary">
            Sell this player
          </Button>
        }
      </DialogActions>
    </Dialog>
  </>
}

function RosterView(props: { team: model.Team, commands: Commands }) {
  const [ selected, setSelected ] = React.useState<model.PlayerIdx | undefined>(undefined);
  const [ altView, setAltView ] = React.useState<boolean>(false);
  const [ playerDetailsDialogOpen, setPlayerDetailsDialogOpen ] = React.useState<boolean>(false);
  const [ openConfirmSell, setOpenConfirmSell ] = React.useState<boolean>(false);
  const isOwnTeam = props.commands.isOwnTeam(props.team.id);

  const rowStyle = (idx: number) => flatten([
    idx == selected ? ['active-table-row-style'] : [],
    props.team.players[idx].injury > 0 ? ['player-row-injury'] : [],
  ]);

  const handleSelectPlayer = (idx: number) => {
    // already selected deselects
    if (selected == idx) {
      setSelected(undefined);
    }
    else if (selected == undefined) {
      setSelected(idx);
    }
    else {
      // a player is already selected. swap them
      if (isOwnTeam) props.commands.swapPlayers(props.team, selected, idx);
      setSelected(idx);
    }
  }

  function handleSellPlayer() {
    if (selected == undefined) bug();
    if (isOwnTeam) props.commands.sellPlayer(props.team.players[selected]);
  }

  function handleConfirmSell(confirmed: boolean) {
    if (confirmed && selected != undefined) {
      handleSellPlayer();
    }
    setOpenConfirmSell(false);
  }

  return <>
    { selected != undefined && <>
        <ConfirmDialog
          open={openConfirmSell}
          message={`Do you really want to sell ${props.team.players[selected].name}?`}
          onConfirm={b => handleConfirmSell(b)}
        />
        <PlayerDetailsDialog
          open={playerDetailsDialogOpen}
          player={props.team.players[selected]}
          handleClose={() => setPlayerDetailsDialogOpen(false)}
          handleClickSell={isOwnTeam ? () => setOpenConfirmSell(true) : undefined}
        />
      </>
    }
    <Grid container>
      <Grid item xs={12}>
        <Switch color="default" checked={altView} onChange={e => setAltView(e.target.checked)} />
        <IconButton
            onClick={() => setPlayerDetailsDialogOpen(true)}
            disabled={selected==undefined} color={"secondary"}>
          <PersonIcon />
        </IconButton>
      </Grid>
    </Grid>
    <table className="squad-list">
      <thead>
        <tr>
          <th>#</th>
          <th>Pos.</th>
          <th>Name</th>
          <th>Av.</th>
          <th>{ altView ? 'Age' : 'Form' }</th>
          <th>Sh</th>
          <th>Pa</th>
          <th>Ta</th>
          <th>Ha</th>
          <th>Sp</th>
        </tr>
      </thead>
      <tbody>
        { props.team.players.map((p, idx) =>
            <tr className={rowStyle(idx)} onClick={() => handleSelectPlayer(idx)}>
              <td>{ idx + 1 }</td>
              <td>
                <Uitk.PlayerPositionBadge player={p} />
                <Uitk.PlayerInjuryBadge player={p} />
              </td>
              <td>{ p.name }</td>
              <td>{ logic.playerAvgSkill(p).toFixed(1) }</td>
              <td>{ altView ? p.age : `+${p.form}` }</td>
              <td>{ p.shooting }</td>
              <td>{ p.passing }</td>
              <td>{ p.tackling }</td>
              <td>{ p.handling }</td>
              <td>{ p.speed }</td>
            </tr>
          )
        }
      </tbody>
    </table>
  </>;
}

const movablePitchPositions: [number, number][] =
  unnest([0, 1, 2, 3, 4].map(x => [1,2,3,4,5].map(y => [x, y])));
  
function TacticsView(props: { team: model.Team, commands: Commands }) {
  const [ selected, setSelected ] = React.useState<model.PlayerIdx | undefined>(undefined);
  const isOwnTeam = props.commands.isOwnTeam(props.team.id);

  function emptyPitchPosition(pos: [number, number], positionSuitsPlayer: boolean) {
    const [xpos, ypos] = pitchPosPixelPos(pos);
    const opacity = positionSuitsPlayer ? playerGoodPositionOpacity : playerBadPositionOpacity;
    return <circle
      onClick={e => handleSelectEmptyPosition(pos)}
      cx={xpos}
      cy={ypos}
      r={positionCircleRadius}
      fill='black'
      fillOpacity={opacity}
    />
  }

  function handleSelectPlayer(idx: model.PlayerIdx) {
    if (selected == undefined) {
      setSelected(idx);
    }
    else if (selected == idx) {
      setSelected(undefined);
    }
    else {
      if (isOwnTeam) props.commands.swapPlayers(props.team, selected, idx);
      setSelected(undefined);
    }
  }

  function handleSelectEmptyPosition(pos: [number, number]) {
    if (isOwnTeam) props.commands.movePlayer(props.team, selected || bug(), pos);
    setSelected(undefined);
  }

  return <svg width="100%" height="auto" viewBox="0 0 812 1280">
    <image width="100%" height="100%" xlinkHref="/pitch.png"
      /*onclick SelectPlayer Nothing */ />
    { take(11, props.team.formation.map((pos, idx) => 
        <PlayerOnPitch
          team={props.team}
          selected={selected}
          playerIdx={idx}
          pos={pos}
          onSelect={() => handleSelectPlayer(idx)}
        />
      ))
    }
    {
      // show pitch positions the selected player can move to
      // (except idx=0 (GK), who can't be moved outfield
      (selected && selected > 0)
      &&
      movablePitchPositions.map(pos => {
        if (includes(pos, take(11, props.team.formation))) {
          return <text></text>
        } else {
          const player = props.team.players[selected];
          const positionSuitsPlayer = includes(pos, player.positions);
          return emptyPitchPosition(pos, positionSuitsPlayer);
        }
      })
    }
  </svg>;
}
