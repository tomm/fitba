#!/usr/bin/env ruby
require "./config/environment"
require 'securerandom'

if ARGV.length == 0
  puts "Usage: ./make_invites.rb <hostname> <num invites>"
  exit
end

hostname = ARGV[0]
num_invites = ARGV[1].to_i
num_invites.times do
  invite = UserInvite.create(code: SecureRandom.hex(4))
  puts "https://#{hostname}/invite/#{invite.code}"
end
