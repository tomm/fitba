import { includes } from 'rambda';

export function playerPositionFormat(positions: [number, number][]): string {
  if (includes([2, 6], positions)) return "GK";
  if (includes([2, 5], positions)) return "DC";
  if (includes([2, 4], positions)) return "DMC";
  if (includes([2, 3], positions)) return "MC";
  if (includes([2, 2], positions)) return "AMC";
  if (includes([2, 1], positions)) return "CF";
  if (includes([0, 5], positions)) return "DL";
  if (includes([4, 5], positions)) return "DR";
  if (includes([0, 4], positions)) return "DML";
  if (includes([4, 4], positions)) return "DMR";
  if (includes([0, 3], positions)) return "ML";
  if (includes([4, 3], positions)) return "MR";
  if (includes([0, 2], positions)) return "AML";
  if (includes([4, 2], positions)) return "AMR";
  return "ERROR";
}
