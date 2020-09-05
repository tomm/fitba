# typed: true
class Message < ApplicationRecord
  belongs_to :team

  def self.send_message(team, from, subject, body, date)
    # don't bother sending messages to AI users
    if not team.is_actively_managed_by_human? then
      return
    end

    Message.create(team: team, from: from, subject: subject, body: body, date: date)
  end

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
