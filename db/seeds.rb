# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'digest/md5'

t = Team.create(name: "Balls Utd.", formation_id: 1)
l = League.create(rank: 1, name: "First Division", isFinished: false)
TeamLeague.create(team_id: t.id, league_id: l.id)

User.create(name: "tom", team: t, secret: Digest::MD5.hexdigest("password"))
