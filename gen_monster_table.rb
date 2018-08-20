MIMIC_TABLE = eval IO.read File.join File.dirname(__FILE__),'mimic_definition.rb'
SPECIES = eval IO.read File.join File.dirname(__FILE__),'monster_definition.rb'

MONSTER_TABLE = SPECIES.map { |s|
  [s[:name], 1..99]
}
MONSTER_TABLE.concat(MIMIC_TABLE.map.with_index(1) { |s,n| [s[:name], n] })

require 'pp'

#pp MONSTER_TABLE

output = (1..99).map { |f| [f] }
#p output

MONSTER_TABLE.each do |name, ranges|
  if ranges.is_a? Integer
    ranges = ranges..ranges
  end
  if ranges.is_a? Range
    ranges = [ranges]
  end

  ranges.each do |r|
    r.each do |f|
      row = output.assoc(f)
      row.push([name, 10])
    end
  end
end

pp output
