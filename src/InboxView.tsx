import React from 'react';
import * as model from './model';
import { format } from 'date-fns';
import Grid from '@material-ui/core/Grid';
import IconButton from '@material-ui/core/IconButton';
import DeleteIcon from '@material-ui/icons/Delete';

export function InboxView(props: { inbox: model.InboxMessage[], onClickDeleteMessage: (id: number) => void }) {
  return <>
    <h2>Inbox</h2>
    {
      props.inbox.length == 0
      ? <div className="center">Your inbox is empty</div>
      : props.inbox.map(msg =>
          <div className="inbox-message">
            <Grid container>
              <Grid xs={2}>
                <IconButton onClick={e => props.onClickDeleteMessage(msg.id)}>
                  <DeleteIcon />
                </IconButton>
              </Grid>
              <Grid xs={10}>
                <Grid container>
                  <Grid xs={6}>
                    <div className="inbox-message-from">
                      From: { msg.from }
                    </div>
                    <div className="inbox-message-subject">
                      Subject: { msg.subject }
                    </div>
                  </Grid>
                  <Grid xs={6}>
                    <div className="inbox-message-date">
                      Date: { format(msg.date, 'E d MMM HH:mm') }
                    </div>
                  </Grid>
                </Grid>
                <div className="inbox-message-body">
                  { msg.body }
                </div>
              </Grid>
            </Grid>
          </div>
        )
    }
  </>;
}
