class Message < ApplicationRecord
  belongs_to :team

  def self.send_message(team, from, subject, body, date)
    # don't bother sending messages to AI users
    if not team.has_user? then
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
