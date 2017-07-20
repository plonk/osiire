# どうして MonsterGenerator のようなものが必要なのだろう？

class Monster
  SPECIES = [
    # char, name, max_hp, strength, defense, exp
    ['M', 'まんまる', 5, 2, 0, 3],
  ]

  class << self
    def make_monster(name)
      row = SPECIES.find { |r| r[1] == name }
      fail "no such monster: #{name}" if row.nil?

      char, name, max_hp, strength, defense, exp = row
      return Monster.new(char, name, max_hp, strength, defense, exp)
    end
  end

  attr :char, :name, :max_hp, :strength, :defense, :exp

  def initialize(char, name, max_hp, strength, defense, exp)
    fail unless char =~ /\A[A-Z]\z/
    @char     = char
    @name     = name
    @max_hp   = max_hp
    @strength = strength
    @defense  = defense
    @exp      = exp
  end
end
