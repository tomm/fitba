module RngHelper
  def self.dice(n,s)
    x=0
    (1..n).each do |_|
      x += 1 + (rand*s).to_i; 
    end
    x
  end
end
