module RngHelper
  def self.int_range(min, max)
    min + (rand*(1+max-min)).to_i
  end

  def self.dice(n,s)
    x=0
    (1..n).each do |_|
      x += 1 + (rand*s).to_i; 
    end
    x
  end

  def self.normalize_probability_list(list)
    tot = list.map {|elem| elem[1]}.reduce(&:+)
    list.map {|elem| [elem[0], elem[1] / tot.to_f]}
  end

  # [(item,probability), ...] -> item | nil
  # probabilities must be normalized (sum to 1) using normalize_probability_list
  def self.sample_prob(list)
    sum = 0
    r = rand()
    list.each {|elem| if r <= sum + elem[1] then return elem[0] else sum += elem[1] end }
    nil
  end
end
