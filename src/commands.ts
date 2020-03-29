import * as model from './model';

export enum UiTab {
  SquadTab
}

export interface Commands {
  deleteInboxMessage(id: number): Promise<void>;
  reloadRootState(): void;
  openTab(tab: UiTab): void;
  swapPlayers(t: model.Team, idx1: model.PlayerIdx, idx2: model.PlayerIdx): Promise<void>;
  movePlayer(t: model.Team, idx: model.PlayerIdx, pos: [number, number]): Promise<void>;
  sellPlayer(p: model.Player): Promise<void>;
  isOwnTeam(teamId: number): boolean;
}
