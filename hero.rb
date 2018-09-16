require_relative 'monster'

class Hero < Struct.new(:x, :y, :hp, :max_hp,
                        :raw_strength, :raw_max_strength,
                        :gold, :exp, :fullness, :max_fullness, :lv)
  attr_accessor :inventory
  attr_accessor :weapon, :shield, :ring, :projectile
  attr_accessor :name
  attr_accessor :action_point
  attr_accessor :invisible

  include StatusEffectPredicates

  def initialize(*args)
    super
    @inventory = []
    @status_effects = []
    @name = "名無しさん"
    @action_point = 0
    @invisible = false
  end

  def strength
    if ring&.name == "ちからの指輪"
      raw_strength + (3 * (ring.cursed ? -1 : +1))
    else
      raw_strength
    end
  end

  def max_strength
    if ring&.name == "ちからの指輪"
      raw_max_strength + (3 * (ring.cursed ? -1 : +1))
    else
      raw_max_strength
    end
  end

  def action_point_recovery_rate
    if quick?
      4
    else
      2
    end
  end

  def state
    :awake
  end

  def char
    if hp < 1.0
      '􄅂􄅃'
    elsif asleep?
      '􄅂􄅃'
    else
      if weapon && shield
        '􄀦􄀧'
      elsif weapon
        '􄄾􄄿'
      elsif shield
        '􄄼􄄽'
      else
        '􄅀􄅁'
      end
    end
  end

  def equipped?(x)
    return x.equal?(weapon) ||
           x.equal?(shield) ||
           x.equal?(ring) ||
           x.equal?(projectile)
  end

  def remove_from_inventory(item)
    if item.equal?(weapon)
      self.weapon = nil
    end
    if item.equal?(shield)
      self.shield = nil
    end
    if item.equal?(ring)
      self.ring = nil
    end
    if item.equal?(projectile)
      self.projectile = nil
    end
    old_size = @inventory.size
    @inventory = @inventory.reject { |x|
      x.equal?(item)
    }
    fail unless @inventory.size == old_size - 1
  end

  # 成功したら true。さもなくば false。
  def add_to_inventory(item)
    if item.type == :projectile
      stock = @inventory.find { |x| x.name == item.name }
      if stock
        stock.number = [stock.number + item.number, 99].min
        return true
      end
    end

    if @inventory.size >= 20
      return false
    else
      @inventory.push(item)
      return true
    end
  end

  def full?
    fullness > max_fullness - 1.0
  end

  def increase_fullness(amount)
    fail TypeError unless amount.is_a?(Numeric)
    self.fullness = [fullness + amount, max_fullness].min
  end

  def increase_max_fullness(amount)
    fail TypeError unless amount.is_a?(Numeric)
    self.max_fullness = [max_fullness + amount, 200.0].min
  end

  def strength_maxed?
    strength >= max_strength
  end

  def hp_maxed?
    hp >= max_hp
  end

  def hunger_per_turn
    if ring&.name == "ハラヘラズの指輪"
      0.0
    elsif shield&.name == "皮の盾"
      0.05
    else
      0.1
    end
  end

  def poison_resistent?
    ring&.name == "毒けしの指輪" || shield&.name == "うろこの盾"
  end

  def sleep_resistent?
    ring&.name == "眠らずの指輪"
  end

  def puppet_resistent?
    ring&.name == "人形よけの指輪"
  end

  def sort_inventory!
    self.inventory = inventory.map.with_index.sort { |(a,i), (b,j)|
      [a.sort_priority, i] <=> [b.sort_priority, j]
    }.map(&:first).group_by { |i| i.name }.values.flatten(1)
  end

  def pos
    [x, y]
  end

  def critical?
    weapon&.name == "必中会心剣"
  end

  def no_miss?
    weapon&.name == "必中会心剣"
  end

end
