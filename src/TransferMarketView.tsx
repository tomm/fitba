import React from 'react';
import * as model from './model';
import { format } from 'date-fns';
import * as Uitk from './Uitk';
import * as logic from './logic';
import Typography from '@material-ui/core/Typography';
import Card from '@material-ui/core/Card';
import Grid from '@material-ui/core/Grid';
import Box from '@material-ui/core/Box';
import CardActions from '@material-ui/core/CardActions';
import CardContent from '@material-ui/core/CardContent';
import Button from '@material-ui/core/Button';
import DialogTitle from '@material-ui/core/DialogTitle';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import AddIcon from '@material-ui/icons/Add';
import RemoveIcon from '@material-ui/icons/Remove';
import { bug } from './utils';
//import Slider from '@material-ui/core/Slider';

const formatMoney = (amount: number): string =>
  (amount).toLocaleString("en-GB", {style: "currency", currency: "GBP", minimumFractionDigits: 0});

function listingStatusShort(listing: model.TransferListing): string {
  switch (listing.status) {
    case 'OnSale': return format(listing.deadline, 'E HH:mm');
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
          <tr><th>Name</th><td>{ player.forename } { player.name }</td></tr>
          <tr><th>Age</th><td>{ player.age }</td></tr>
          <tr><th>Favoured Positions</th><td><Uitk.PlayerPositionBadge player={player} /></td></tr>
          <tr><th>Skill Average</th><td>{ logic.playerAvgSkill(player).toFixed(1) }</td></tr>
          <tr><th>Shooting</th><td>{ player.shooting }</td></tr>
          <tr><th>Passing</th><td>{ player.passing }</td></tr>
          <tr><th>Tackling</th><td>{ player.tackling }</td></tr>
          <tr><th>Handling</th><td>{ player.handling }</td></tr>
          <tr><th>Speed</th><td>{ player.speed }</td></tr>
          <tr><th><strong>Minimum bid</strong></th><td><strong>{ formatMoney(props.listing.minPrice) }</strong></td></tr>
        </table>

        { props.listing.sellerTeamId == props.ownTeam.id
          ? <Typography variant="body1">
              You are the seller
            </Typography>

          : <Grid container spacing={2}>
              <Grid xs={12}>
                <Box padding={1}>
                  <Card>
                    <CardContent>
                      <Typography component="h2">
                        { formatMoney(nextBid) }
                      </Typography>
                    </CardContent>
                    <CardActions>
                      <Button variant="contained" onClick={() => decBid()}>
                        <RemoveIcon />
                      </Button>
                      <Button variant="contained" onClick={() => incBid()}>
                        <AddIcon />
                      </Button>
                      <Button variant="contained" color="primary" onClick={() => props.handleMakeBid(props.listing.id, nextBid)}>Place bid</Button>
                    </CardActions>
                  </Card>
                </Box>
              </Grid>
              { props.listing.youBid != undefined &&
                <Grid xs={12}>
                  <Box padding={1}>
                    <Card>
                      <CardContent>
                        <Typography component="h2">
                          Current bid: { formatMoney(props.listing.youBid) }
                        </Typography>
                      </CardContent>
                      <CardActions>
                        <Button variant="contained" color="secondary" onClick={() => props.handleMakeBid(props.listing.id, undefined)}>Withdraw</Button>
                      </CardActions>
                    </Card>
                  </Box>
                </Grid>
              }
            </Grid>
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
  
  const [ listings, setListings ] = React.useState<model.TransferListing[] | undefined>(undefined);
  const [ viewingListingId, setViewingListingId ] = React.useState<number | undefined>(undefined);

  React.useEffect(() => {
    model.getTransferListings.call({}).then(setListings);
  }, []);

  function handleMakeBid(transfer_listing_id: number, amount: number | undefined): void {
    if (listings == undefined) return bug();
    // update listings with your new bid amount
    setListings(
      listings.map(l =>
        l.id == transfer_listing_id ? { ...l, youBid: amount } : l
      )
    );
    // tell back-end
    model.makeBid.call({ transfer_listing_id, amount });
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
      <h2>Transfer Market</h2>

      <table className="transfer-listings">
        <tr>
          <th>Name</th>
          <th>Pos</th>
          <th>Min Bid</th>
          <th>End</th>
          <th>Your Bid</th>
          <th>Avg.</th>
          <th>Sh</th>
          <th>Pa</th>
          <th>Ta</th>
          <th>Ha</th>
          <th>Sp</th>
        </tr>
        { listings.map(l =>
            <tr onClick={() => setViewingListingId(l.id)}>
              <td>{ l.player.name }</td>
              <td>
                <Uitk.PlayerPositionBadge player={l.player} />
                <Uitk.PlayerInjuryBadge player={l.player} />
              </td>
              <td>{ formatMoney(l.minPrice) }</td>
              <td>{ listingStatusShort(l) }</td>
              <td>{
                l.sellerTeamId == props.ownTeam.id
                ? 'You are seller'
                : l.youBid
                ? formatMoney(l.youBid)
                : ''
              }</td>
              <td>{ logic.playerAvgSkill(l.player).toFixed(1) }</td>
              <td>{ l.player.shooting }</td>
              <td>{ l.player.passing }</td>
              <td>{ l.player.tackling }</td>
              <td>{ l.player.handling }</td>
              <td>{ l.player.speed }</td>
            </tr>
          )
        }
      </table>
    </>
  }
}
