# どうして MonsterGenerator のようなものが必要なのだろう？

class StatusEffect
  attr_accessor :caster
  attr_accessor :type, :remaining_duration

  def initialize(type, remaining_duration = Float::INFINITY)
    @type = type
    @remaining_duration = remaining_duration
  end

  def name
    case type
    when :sleep
      "睡眠"
    when :paralysis
      "かなしばり"
    when :held
      "はりつけ"
    when :confused
      "混乱"
    when :hallucination
      "まどわし"
    when :quick
      "倍速"
    when :bomb
      "爆弾"
    when :audition_enhancement
      "兎耳"
    when :olfaction_enhancement
      "豚鼻"
    else
      type.to_s
    end
  end
end

module StatusEffectPredicates
  attr :status_effects

  def paralyzed?
    @status_effects.any? { |e| e.type == :paralysis }
  end

  def asleep?
    @status_effects.any? { |e| e.type == :sleep }
  end

  def held?
    @status_effects.any? { |e| e.type == :held }
  end

  def confused?
    @status_effects.any? { |e| e.type == :confused }
  end

  def hallucinating?
    @status_effects.any? { |e| e.type == :hallucination }
  end

  def quick?
    @status_effects.any? { |e| e.type == :quick }
  end

  def bomb?
    @status_effects.any? { |e| e.type == :bomb }
  end

  def nullified?
    @status_effects.any? { |e| e.type == :nullification }
  end

  def audition_enhanced?
    @status_effects.any? { |e| e.type == :audition_enhancement }
  end

  def olfaction_enhanced?
    @status_effects.any? { |e| e.type == :olfaction_enhancement }
  end

end

class Monster
  # mimic.rb による生成。
  MIMIC_TABLE = eval IO.read File.join File.dirname(__FILE__),'mimic_definition.rb'
  SPECIES = eval IO.read File.join File.dirname(__FILE__),'monster_definition.rb'
  SPECIES.concat(MIMIC_TABLE)

  class << self
    def make_monster(name)
      definition = SPECIES.find { |r| r[:name] == name }
      fail "no such monster: #{name}" unless definition

      asleep_rate = definition[:asleep_rate] || 0.0
      state = (rand() < asleep_rate) ? :asleep : :awake
      facing = [1,1]
      goal = nil
      return Monster.new(definition, state, facing, goal)
    end
  end

  attr :defense, :exp
  attr_accessor :drop_rate
  attr_accessor :hp, :max_hp, :strength
  attr_accessor :state, :facing, :goal
  attr_accessor :item
  attr :trick_range
  attr_accessor :invisible
  attr_accessor :action_point, :action_point_recovery_rate
  attr_accessor :group
  attr_accessor :impersonating_name, :impersonating_char
  attr_reader :contents
  attr_accessor :capacity

  include StatusEffectPredicates

  def initialize(definition,
                 state, facing, goal)
    @char     = definition[:char] || fail
    @name     = definition[:name] || fail
    @max_hp   = definition[:max_hp] || fail
    @strength = definition[:strength] || fail
    @defense  = definition[:defense] || fail
    @exp      = definition[:exp] || fail
    @drop_rate = definition[:drop_rate] || 0.0

    @state = state
    @facing = facing
    @goal = goal

    @hp = @max_hp

    @status_effects = []
    @item = nil
    case @name
    when "催眠術師", "どろぼう猫", "四人トリオ"
      # 攻撃されるまで動き出さないモンスター
      @status_effects << StatusEffect.new(:paralysis, Float::INFINITY)
    when "ノーム"
      @item = Gold.new(rand(250..1500))
    when "白い手", "動くモアイ像"
      @status_effects << StatusEffect.new(:held, Float::INFINITY)
    when "メタルヨテイチ"
      @status_effects << StatusEffect.new(:hallucination, Float::INFINITY)
      @item = Item::make_item("幸せの種")
    when "化け狸"
      @impersonating_name = @name
      @impersonating_char = @char
    when "ボンプキン"
      @status_effects << StatusEffect.new(:bomb, Float::INFINITY)
    end

    @trick_range = definition[:trick_range] || :none

    case @name
    when "ゆうれい"
      @invisible = true
    else
      @invisible = false
    end

    @action_point = 0
    @action_point_recovery_rate = definition[:action_point_recovery_rate] || 2

    # 合成モンスター。
    @contents = []
    @capacity = definition[:capacity]
  end

  # state = :awake の操作は別。モンスターの特殊な状態を解除して動き出
  # させる。
  def on_party_room_intrusion
    case @name
    when "催眠術師", "どろぼう猫", "四人トリオ"
      # 攻撃されるまで動き出さないモンスター
      @status_effects.reject! { |e| e.type == :paralysis }
    when "動くモアイ像"
      @status_effects.reject! { |e| e.type == :held }
    end
  end

  def char
    case @name
    when "ボンプキン"
      if hp < 1.0
        "\u{104238}\u{104239}" # puff of smoke
      elsif !nullified? && bomb? && hp <= max_hp/2
        '􄁮􄁯'
      else
        @char
      end
    when "化け狸"
      if hp < 1.0
        @char
      else
        @impersonating_char
      end
    when "動くモアイ像"
      if held?
        @char
      else
        "\u{104066}\u{104067}"
      end
    else
      if hp < 1.0
        "\u{104238}\u{104239}" # puff of smoke
      else
        @char
      end
    end
  end

  def reveal_self!
    if @name == "化け狸"
      @impersonating_name = @name
      @impersonating_char = @char
    end
  end

  def name
    if @name == "化け狸"
      @impersonating_name
    else
      @name
    end
  end

  def tipsy?
    @name == "コウモリ" || @name == "ゆうれい"
  end

  def trick_rate
    case @name
    when "白い手"
      1.0
    when '催眠術師'
      0.25
    when 'ファンガス'
      0.33
    when 'ノーム'
      0.5
    when 'ピューシャン'
      0.75
    when "アクアター"
      0.5
    when "パペット"
      0.5
    when "土偶"
      0.5 # HP 0.25 / ちから 0.25
    when "目玉"
      0.25
    when "どろぼう猫"
      0.5
    when "竜"
      0.5
    when "ソーサラー"
      0.33
    when "怪盗クジラ"
      0.5
    else
      0.0
    end
  end

  def single_attack?
    case @name
    when "ツバメ", "四人トリオ"
      true
    else
      false
    end
  end

  def divide?
    case @name
    when "グール"
      true
    else
      false
    end
  end

  def poisonous?
    case @name
    when 'ファンガス', '土偶'
      true
    else
      false
    end
  end

  def undead?
    case @name
    when '木乃伊', 'ゆうれい'
      true
    else
      false
    end
  end

  def hp_maxed?
    @hp == @max_hp
  end

  def damage_capped?
    @name == "メタルヨテイチ"
  end

  def teleport_on_attack?
    @name == "メタルヨテイチ"
  end

  PHYLOGENY = [
    ["スライム", "緑スライム", "紫スライム"]
  ]

  def descendant
    PHYLOGENY.each do |series|
      # 演算子の優先度がよくわかってない。
      if (i = series.index(@name)) && (i < series.size - 1)
        return series[i + 1]
      end
    end
    return nil
  end

  def ancestor
    PHYLOGENY.each do |series|
      if (i = series.index(@name)) && (i > 0)
        return series[i - 1]
      end
    end
    return nil
  end

private

end
