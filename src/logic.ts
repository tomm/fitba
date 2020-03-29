import * as model from './model';

export function playerAvgSkill(p: model.Player): number {
  return 0.2 * (p.shooting + p.passing + p.tackling + p.handling + p.speed);
}
