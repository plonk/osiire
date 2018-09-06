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
    when :nullification
      "封印"
    when :blindness
      "盲目"
    when :trap_detection
      "ワナ感知"
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

  def blind?
    @status_effects.any? { |e| e.type == :blindness }
  end

  def trap_detecting?
    @status_effects.any? { |e| e.type == :trap_detection }
  end

end

class Monster
  SPECIES = [
    # char, name, max_hp, exp, strength, defense, drop, asleep_rate, range
    ['􄁂􄁃', 'スライム', 5, 1, 2, 1, 0.01, 0.5, :none],            # 弱い
    ['􄁆􄁇', 'コウモリ', 7, 2, 3, 1, 0.01, 0.5, :none],            # ふらふら
    ['􄁈􄁉', 'オオウミウシ', 7, 3, 2, 4, 0.01, 0.5, :none],        # 体当たり
    ['􄁊􄁋', 'ツバメ', 5, 2, 3, 9, 0.01, 0.5, :none],              # 速い
    ['􄁎􄁏', 'ワラビー', 8, 5, 4, 9, 0.01, 0.5, :none],            # 蹴ってくる
    ['􄁐􄁑', '催眠術師', 16, 12, 6, 11, 0.33, 0.0, :reach],        # 寝てる。眠らせる
    ['􄁒􄁓', 'ピューシャン', 9, 5, 4, 15, 0.01, 0.5, :line],       # 矢を打つ
    ['􄁔􄁕', 'ファンガス', 17, 6, 6, 8, 0.16, 0.5, :reach],        # 胞子で力を下げる
    ['􄁖􄁗', 'グール', 10, 7, 4, 15, 0.01, 0.5, :none],            # 増える
    ['􄁘􄁙', '木乃伊', 16, 16, 10, 19, 0.01, 0.5, :none],          # 回復アイテムでダメージ
    ['􄁚􄁛', 'ノーム', 20, 10, 0, 16,1.0, 0.5, :reach],            # 金を盗む
    ['􄁜􄁝', 'ハゲタカ', 27, 25, 10, 16, 0.16, 0.5, :none],        # クチバシが痛い
    ['􄁞􄁟', 'ソーサラー', 23, 15, 10, 16, 0.01, 0.5, :reach],     # 瞬間移動の杖を振る
    ['􄁄􄁅', 'メタルヨテイチ', 3, 500, 30, 49, 1.0, 0.0, :none],   # 回避性のレアモン
    ['􄁠􄁡', 'おめん武者', 35, 40, 15, 26, 0.16, 0.5, :none],      # 鎧の中は空洞だ
    ['􄁢􄁣', 'アクアター', 30, 25, 0, 19, 0.01, 0.5, :reach],      # ガッポーン。盾が錆びるぞ
    ['􄁤􄁥', 'どろぼう猫', 40, 20, 0, 17, 0.0, 0.0, :reach],       # アイテムを盗む
    ['􄄤􄄥', '動くモアイ像', 45, 50, 18, 27, 0.33, 0.0, :none],    # 石像のふりをしている
    ['􄁨􄁩', '四人トリオ', 60, 10, 11, 3, 0.0, 1.0, :none],        # 4人で固まって出現する
    ['􄁪􄁫', '白い手', 72, 40, 7, 23, 0.0, 0.0, :reach],           # つかまると倒すまで動けない
    ['􄁬􄁭', 'ゴーレム', 52, 180, 32, 27, 0.33, 0.5, :none],       # 巨大な泥人形
    ['􄈬􄈭', 'ボンプキン', 70, 30, 12, 23, 0.01, 0.5, :none],      # 爆発する
    ['􄁰􄁱', 'パペット', 36, 40, 13, 23, 0.16, 0.5, :reach],       # レベルを下げる
    ['􄁲􄁳', 'ゆうれい', 60, 150, 17, 27, 0.0, 0.5, :none],        # 見えない。ふらふら
    ['􄁴􄁵', 'ミミック', 50, 30, 24, 24, 0.0, 0.0, :none],         # アイテム・階段に化ける
    ['􄄠􄄡', 'トロール', 51, 380, 51, 21, 0.16, 0.5, :none],       # 強い
    ['􄁶􄁷', '目玉', 62, 250, 31, 27, 0.16, 0.5, :sight],          # 混乱させてくる
    ['􄁸􄁹', '化け狸', 80, 20, 9, 14, 0.0, 0.5, :none],            # 別のモンスターに化ける
    ['􄁺􄁻', '土偶', 70, 150, 17, 24, 0.0, 0.5, :reach],           # HP、ちから最大値を下げる
    ['􄄢􄄣', 'デビルモンキー', 78, 600, 26, 25, 0.16, 0.5, :none], # 二倍速
    ['􄁼􄁽', 'マルスボース', 75, 750, 51, 29, 0.16, 0.5, :none],   # 強い
    ['􄁾􄁿', '竜', 100, 3000, 68, 30, 0.75, 0.5, :line],           # テラ強い。火を吐く
  ]

  class << self
    def make_monster(name)
      row = SPECIES.find { |r| r[1] == name }
      fail "no such monster: #{name}" if row.nil?

      char, name, max_hp, exp, strength, defense, drop_rate, asleep_rate, trick_range = row
      state = (rand() < asleep_rate) ? :asleep : :awake
      return Monster.new(char, name, max_hp, strength, defense, exp, drop_rate,
                        state, [1,1], nil, trick_range)
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

  include StatusEffectPredicates

  def initialize(char, name, max_hp, strength, defense, exp, drop_rate,
                 state, facing, goal, trick_range)
    @char     = char
    @name     = name
    @max_hp   = max_hp
    @strength = strength
    @defense  = defense
    @exp      = exp
    @drop_rate = drop_rate

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

    @trick_range = trick_range

    case @name
    when "ゆうれい"
      @invisible = true
    else
      @invisible = false
    end

    @action_point = 0
    @action_point_recovery_rate = double_speed? ? 4 : 2
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

private

  def double_speed?
    case @name
    when "デビルモンキー", "ツバメ", "四人トリオ", "メタルヨテイチ"
      true
    else
      false
    end
  end

end
