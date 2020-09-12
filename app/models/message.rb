# typed: strict
class Message < ApplicationRecord
  extend T::Sig

  belongs_to :team

  sig {params(team: Team, from: String, subject: String, body: String, date: Time).void}
  def self.send_message(team, from, subject, body, date)
    # don't bother sending messages to AI users
    if not team.is_actively_managed_by_human? then
      return
    end

    Message.create(team: team, from: from, subject: subject, body: body, date: date)
  end

  sig {returns(T.untyped)}
  def to_api
    {
      id: self.id,
      from: self.from,
      subject: self.subject,
      body: self.body,
      date: self.date
    }
  end
end
