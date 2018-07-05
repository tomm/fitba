require 'singleton'

class NameGen
  include Singleton

  attr_reader :names

  def initialize
    f = File.open("surname.txt","r")
    @names = f.read.split("\n")
  end


  def self.pick
    NameGen.instance.names.sample.capitalize
  end
end
