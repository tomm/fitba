# typed: false
require 'singleton'

class NameGen
  include Singleton

  attr_reader :names, :forenames

  def initialize
    f = File.open("surname.txt","r")
    @names = f.read.lines.map(&:chomp)

    f = File.open("forename.txt","r")
    @forenames = f.read.lines.map(&:chomp)
  end

  def self.surname
    NameGen.instance.names.sample.capitalize
  end

  def self.forename
    NameGen.instance.forenames.sample.capitalize
  end
end
