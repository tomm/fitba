import React from 'react';
import * as model from './model';

function calcPoints(record: model.TeamLeagueRecord) {
  return record.won * 3 + record.drawn * 1
}

export function LeagueTableView(props: {
  league: model.LeagueTable,
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
