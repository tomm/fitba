import * as React from 'react';
import Dialog from '@material-ui/core/Dialog';
import DialogTitle from '@material-ui/core/DialogTitle';
import DialogContent from '@material-ui/core/DialogContent';
import DialogActions from '@material-ui/core/DialogActions';
import Button from '@material-ui/core/Button';

export function ConfirmDialog(props: {
  open: boolean;
  title?: string;
  message?: string;
  okButtonLabel?: string;
  cancelButtonLabel?: string;
  onConfirm: (confirmed: boolean) => void;
}) {
  return <Dialog open={props.open} onClose={() => props.onConfirm(false)}>
    { props.title &&
      <DialogTitle>
        { props.title }
      </DialogTitle>
    }
    <DialogContent>
      <p>{ props.message }</p>
    </DialogContent>
    <DialogActions>
      <Button color="primary" onClick={e => props.onConfirm(true)}>
        { props.okButtonLabel || 'Yes' }
      </Button>
      <Button color="primary" onClick={e => props.onConfirm(false)}>
        { props.cancelButtonLabel || 'No' }
      </Button>
    </DialogActions>
  </Dialog>;
}

