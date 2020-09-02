import React from 'react';
import * as model from './model';
import { format, isSameDay } from 'date-fns';
import * as Uitk from './Uitk';
import * as logic from './logic';
import Typography from '@material-ui/core/Typography';
import Box from '@material-ui/core/Box';
import Button from '@material-ui/core/Button';
import DialogTitle from '@material-ui/core/DialogTitle';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import AddIcon from '@material-ui/icons/Add';
import Switch from '@material-ui/core/Switch';
import FormControlLabel from '@material-ui/core/FormControlLabel';
import RemoveIcon from '@material-ui/icons/Remove';
import { bug } from './utils';
const seedrandom = require('seedrandom');

const formatMoney = (amount: number): string =>
  (amount).toLocaleString("en-GB", {style: "currency", currency: "GBP", minimumFractionDigits: 0, maximumFractionDigits: 0});

const formatMoneyMillions = (amount: number): string =>
  (amount / 1e6).toLocaleString("en-GB", {style: "currency", currency: "GBP", minimumFractionDigits: 1, maximumFractionDigits: 1}) + "M";

function randomClubName(seed: string) {
  const r = seedrandom(seed);
  const pre = ['Ab', 'Col', 'Nur', 'Saltz', 'Sturm', 'Hart', 'Wolfs', 
    'Oden', 'Sonder', 'Lyng', 'Hobro', 'Esbj', 'Anger', 'Nime'];
  const suf = ['borg', 'jerg', 'jysk', 'ondby', 'arhus', 'havn', 'burg',
    'ton', 'lin', 'land', 'antes', 'naco', 'iens', 'pellier', 'eaux', 'orino'];
  const wtf = ['', '', '', '', '', '',
    ' AC', ' FC', ' Utd', ' Athletic', ' City'];
  return pre[Math.abs(r.int32()) % pre.length] +
         suf[Math.abs(r.int32()) % suf.length] +
         wtf[Math.abs(r.int32()) % wtf.length];
}

function listingStatusShort(listing: model.TransferListing): string {
  switch (listing.status) {
    case 'OnSale': {
      const now = new Date();
      const endingInMinutes = (listing.deadline.getTime() - now.getTime()) / (60*1000);
      // if less than a minute till deadline
      if (endingInMinutes <= 1) {
        return 'now!';
      // if less than an hour till deadline
      } else if (endingInMinutes <= 60) {
        return `${endingInMinutes.toFixed(0)} mins`;
      } else if (isSameDay(listing.deadline, new Date())) {
        return format(listing.deadline, 'HH:mm');
      } else {
        return format(listing.deadline, 'E HH:mm');
      }
    }
    case 'Sold': return 'Sold';
    case 'Unsold': return 'Unsold';
    case 'YouWon': return 'You won!';
    case 'OutBid': return 'Outbid';
    case 'TeamRejected': return 'Rejected';
    case 'PlayerRejected': return 'Rejected';
    case 'InsufficientMoney': return 'No funds';
  }
}

function ListingDetailsDialog(props: {
  ownTeam: model.Team,
  listing: model.TransferListing,
  handleClose: () => void,
  handleMakeBid: (transfer_listing_id: number, amount: number | undefined) => void;
}) {
  const [ nextBid, setNextBid ] = React.useState<number>(props.listing.youBid || props.listing.minPrice);

  function incBid() {
    setNextBid(Math.round(nextBid + Math.max(100000, nextBid*0.01)));
  }

  function decBid() {
    setNextBid(Math.max(
      props.listing.minPrice,
      Math.round(nextBid - Math.max(100000, nextBid*0.01))
    ));
  }

  const player = props.listing.player;
  return <>
    <Dialog onClose={props.handleClose} open={true} fullWidth={true}>
      <DialogTitle>{ player.forename } { player.name }</DialogTitle>
      <DialogContent>
        <table>
          <tr><th>Favoured Positions</th><td><Uitk.PlayerPositionBadge player={player} /></td></tr>
          <tr><th>Age</th><td>{ player.age }</td></tr>
          <tr><th>Skill Average</th><td>{ logic.playerAvgSkill(player).toFixed(1) }</td></tr>
          <tr><th>Current club</th><td>{ props.listing.sellerTeamName || randomClubName(player.forename + ' ' + player.name) }</td></tr>
          <tr><th>Daily wage</th><td>£{ props.listing.player.wage.toLocaleString() }</td></tr>
          <tr><th><strong>Minimum bid</strong></th><td><strong>{ formatMoney(props.listing.minPrice) }</strong></td></tr>
          <tr><th><strong># Bidders</strong></th><td><strong>{ props.listing.numBids }</strong></td></tr>
        </table>
      
        <table>
          <tr>
            <th>Shooting</th>
            <th>Passing</th>
            <th>Tacking</th>
            <th>Handling</th>
            <th>Speed</th>
          </tr>
          <tr>
            <td>{ player.shooting }</td>
            <td>{ player.passing }</td>
            <td>{ player.tackling }</td>
            <td>{ player.handling }</td>
            <td>{ player.speed }</td>
          </tr>
        </table>

        { props.listing.sellerTeamId == props.ownTeam.id
          ? <Typography variant="body1">
              You are the seller
            </Typography>

          : <>
              <Box display="flex" padding={0} justifyContent="center">
                <Box padding={1}>
                  <Button variant="contained" size="small" onClick={() => decBid()}>
                    <RemoveIcon />
                  </Button>
                </Box>
                <Box padding={1}>
                  <Button variant="contained" size="small" color="primary" onClick={() => props.handleMakeBid(props.listing.id, nextBid)}>
                    Bid { formatMoneyMillions(nextBid) }
                  </Button>
                </Box>
                <Box padding={1}>
                  <Button variant="contained" size="small" onClick={() => incBid()}>
                    <AddIcon />
                  </Button>
                </Box>
              </Box>
              { props.listing.youBid != undefined &&
                <>
                  <Box display="flex" padding={1} justifyContent="center">
                    Current bid: { formatMoney(props.listing.youBid) }
                  </Box>
                  <Box display="flex" padding={1} justifyContent="center">
                    <Button size="small" variant="contained" color="secondary" onClick={() => props.handleMakeBid(props.listing.id, undefined)}>Withdraw</Button>
                  </Box>
                </>
              }
          </>
        }

      </DialogContent>
      <DialogActions>
        <Button onClick={props.handleClose} color="primary">
          Back
        </Button>
      </DialogActions>
    </Dialog>
  </>
}

export function TransferMarketView(props: { ownTeam: model.Team }) {
  
  const [ altView, setAltView ] = React.useState(false);
  const [ listings, setListings ] = React.useState<model.TransferListing[] | undefined>(undefined);
  const [ viewingListingId, setViewingListingId ] = React.useState<number | undefined>(undefined);
  const yourBids = listings ? listings.filter(l => l.youBid != undefined) : [];

  React.useEffect(reloadListings, []);

  function reloadListings() {
    model.getTransferListings.call({}).then(setListings);
  }

  function handleMakeBid(transfer_listing_id: number, amount: number | undefined): void {
    if (listings == undefined) return bug();
    // update listings with your new bid amount
    setListings(
      listings.map(l =>
        l.id == transfer_listing_id ? { ...l, youBid: amount } : l
      )
    );
    // tell back-end
    model.makeBid.call(
      { transfer_listing_id, amount }
    ).then(reloadListings);
  }

  function transferListingCssClass(l: model.TransferListing): string {
    return l.sellerTeamId == props.ownTeam.id
    ? 'transfer-listing-own'
    : l.youBid
    ? 'transfer-listing-bid'
    : '';
  }

  if (listings == undefined) {
    return <Uitk.Loading />
  } else {
    return <>
      { viewingListingId &&
        <ListingDetailsDialog
          ownTeam={props.ownTeam}
          listing={listings.find(l => l.id == viewingListingId) || bug()}
          handleClose={() => setViewingListingId(undefined)}
          handleMakeBid={handleMakeBid}
        />
      }
      <h2>
        Transfer Market
      </h2>

      { props.ownTeam.money &&
        <Typography variant="subtitle1" gutterBottom={true}>
          You have { formatMoney(props.ownTeam.money) } available for transfers
        </Typography>
      }

      { yourBids.length > 0 &&
        <>
          <h2>
            Your bids
          </h2>
          <table className="transfer-listings">
            <tr>
              <th>Name</th>
              <th>Pos</th>
              <th>Age</th>
              <th>Avg.</th>
              <th>End</th>
              <th>Min Bid</th>
              <th>Your Bid</th>
              <th># Bidders</th>
            </tr>
            { yourBids.map(l =>
              <tr className="transfer-listing-bid"
                  onClick={() => setViewingListingId(l.id)}
              >
                <td>{ l.player.name }</td>
                <td>
                  <Uitk.PlayerPositionBadge player={l.player} />
                  <Uitk.PlayerInjuryBadge player={l.player} />
                </td>
                <td>{ l.player.age }</td>
                <td>{ logic.playerAvgSkill(l.player).toFixed(1) }</td>
                <td>{ formatMoneyMillions(l.minPrice) }</td>
                <td>{ listingStatusShort(l) }</td>
                <td>{
                  l.youBid
                  ? formatMoneyMillions(l.youBid)
                  : ''
                }</td>
                <td>{ l.numBids }</td>
              </tr>
              )
            }
          </table>
        </>
      }

      <h2>
        All listings
      </h2>

      <Box padding={1}>
        <FormControlLabel
          control={
            <Switch color="default" checked={altView} onChange={e => setAltView(e.target.checked)} />
          }
          label={'Toggle bidding / player information'}
        />
      </Box>

      <table className="transfer-listings">
        <tr>
          <th>Name</th>
          <th>Pos</th>
          { altView
            ? <>
                <th>Age</th>
                <th>Avg.</th>
                <th>Sh</th>
                <th>Pa</th>
                <th>Ta</th>
                <th>Ha</th>
                <th>Sp</th>
              </>
            : <>
                <th>Age</th>
                <th>Avg.</th>
                <th>Min Bid</th>
                <th># Bidders</th>
                <th>Ending</th>
              </>
          }
        </tr>
        { listings.map(l =>
            <tr onClick={() => setViewingListingId(l.id)}
                className={transferListingCssClass(l)}>
              <td>{ l.player.name }</td>
              <td>
                <Uitk.PlayerPositionBadge player={l.player} />
                <Uitk.PlayerInjuryBadge player={l.player} />
              </td>
              { altView
                ? <>
                    <td>{ l.player.age }</td>
                    <td>{ logic.playerAvgSkill(l.player).toFixed(1) }</td>
                    <td>{ l.player.shooting.toFixed(0) }</td>
                    <td>{ l.player.passing.toFixed(0) }</td>
                    <td>{ l.player.tackling.toFixed(0) }</td>
                    <td>{ l.player.handling.toFixed(0) }</td>
                    <td>{ l.player.speed.toFixed(0) }</td>
                  </>
                : <>
                    <td>{ l.player.age }</td>
                    <td>{ logic.playerAvgSkill(l.player).toFixed(1) }</td>
                    <td>{ formatMoneyMillions(l.minPrice) }</td>
                    <td>{ l.numBids }</td>
                    <td>{ listingStatusShort(l) }</td>
                  </>
              }
            </tr>
          )
        }
      </table>
    </>
  }
}
