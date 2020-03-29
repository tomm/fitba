import React from 'react';
import * as model from './model';
import { playerPositionFormat } from './formatters';

export function PlayerPositionBadge(props: { player: model.Player }) {
  const pos = playerPositionFormat(props.player.positions);
  return <span className={`player-position-badge player-position-${pos}`}>{ pos }</span>;
}

export const ButtonBar = (props: { children: any }) =>
  <div style={{ display: 'block', float: 'left' }}>{ props.children }</div>

export const PlayerInjuryBadge = (props: { player: model.Player }) =>
  <span className={props.player.injury ? 'injury-icon' : ''}></span>
