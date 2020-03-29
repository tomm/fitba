const contains = require('ramda/src/contains');

export function playerPositionFormat(positions: [number, number][]): string {
  if (contains([2, 6], positions)) return "GK";
  if (contains([2, 5], positions)) return "DC";
  if (contains([2, 4], positions)) return "DMC";
  if (contains([2, 3], positions)) return "MC";
  if (contains([2, 2], positions)) return "AMC";
  if (contains([2, 1], positions)) return "CF";
  if (contains([0, 5], positions)) return "DL";
  if (contains([4, 5], positions)) return "DR";
  if (contains([0, 4], positions)) return "DML";
  if (contains([4, 4], positions)) return "DMR";
  if (contains([0, 3], positions)) return "ML";
  if (contains([4, 3], positions)) return "MR";
  if (contains([0, 2], positions)) return "AML";
  if (contains([4, 2], positions)) return "AMR";
  return "ERROR";
}
