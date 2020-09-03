import React from 'react';
import Table from '@material-ui/core/Table';
import TableBody from '@material-ui/core/TableBody';
import TableCell from '@material-ui/core/TableCell';
import TableContainer from '@material-ui/core/TableContainer';
import TableHead from '@material-ui/core/TableHead';
import TableRow from '@material-ui/core/TableRow';
import * as model from './model';
import * as Uitk from './Uitk';

export function FinancesView(props: { ownTeam: model.Team }) {

  const [ finances, setFinances ] = React.useState<model.Finances | undefined>(undefined);

  React.useEffect(() => {
    model.getFinances.call({}).then(setFinances);
  }, []);

  function sum(items: { amount: number }[]): number {
    return items.reduce((p,n) => p + n.amount, 0);
  }

  function sumExcludingTransfers(items: { description: string, amount: number }[]): number {
    return items.reduce((p,n) => p + (n.description.startsWith('Transfer') ? 0 : n.amount), 0);
  }

  function timeperiod(title: string, items: { description: string, amount: number }[]) {
    return <>
      <h2>{ title }</h2>
      <TableContainer>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Description</TableCell>
              <TableCell align="right">Amount £</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            { items.map(item =>
              <TableRow>
                <TableCell>{ item.description }</TableCell>
                <TableCell align="right">£{ item.amount.toLocaleString() }</TableCell>
              </TableRow>
            )}
            <TableRow>
              <TableCell>Total (excluding transfers)</TableCell>
              <TableCell align="right">£{ sumExcludingTransfers(items).toLocaleString() }</TableCell>
            </TableRow>
            <TableRow>
              <TableCell><strong>Total</strong></TableCell>
              <TableCell align="right"><strong>£{ sum(items).toLocaleString() }</strong></TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </TableContainer>
    </>
  }

  if (finances === undefined) {
    return <Uitk.Loading />;
  } else {
    return <>
      <h2>Funds available</h2>
      <TableContainer>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell align="center"><strong>£{ props.ownTeam.money?.toLocaleString() }</strong></TableCell>
            </TableRow>
          </TableHead>
        </Table>
      </TableContainer>

      { timeperiod("Cashflow today", finances.todayItems) }
      { timeperiod("Cashflow this season", finances.seasonItems) }
    </>
  }
}
