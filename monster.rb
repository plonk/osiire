# どうして MonsterGenerator のようなものが必要なのだろう？

class StatusEffect < Struct.new(:type, :remaining_duration)
  attr_accessor :caster

  # def on_start
  # end

  # def on_end
  # end
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
end

class Monster
  SPECIES = [
    # char, name, max_hp, exp, strength, defense, drop, asleep_rate
    ['􄁂􄁃', 'スライム', 5, 1, 2, 1, 0.01, 0.5],            # 弱い
    ['􄁆􄁇', 'コウモリ', 7, 2, 3, 1, 0.01, 0.5],            # ふらふら
    ['􄁈􄁉', 'オオウミウシ', 7, 3, 2, 4, 0.01, 0.5],        # 体当たり
    ['􄁊􄁋', 'ツバメ', 5, 2, 3, 9, 0.01, 0.5],              # 速い
    ['􄁎􄁏', 'ワラビー', 8, 5, 4, 9, 0.01, 0.5],            # 蹴ってくる
    ['􄁐􄁑', '催眠術師', 16, 12, 6, 11, 0.33, 0.0],         # 寝てる。眠らせる
    ['􄁒􄁓', 'ピューシャン', 9, 5, 4, 15, 0.01, 0.5],       # 矢を打つ
    ['􄁔􄁕', 'ファンガス', 17, 6, 6, 8, 0.16, 0.5],         # 胞子で力を下げる
    ['􄁖􄁗', 'グール', 10, 7, 4, 15, 0.01, 0.5],            # 増える
    ['􄁘􄁙', '木乃伊', 16, 16, 10, 19, 0.01, 0.5],          # 回復アイテムでダメージ
    ['􄁚􄁛', 'ノーム', 20, 10, 0, 16,1.0, 0.5],             # 金を盗む
    ['􄁜􄁝', 'ハゲタカ', 27, 25, 10, 16, 0.16, 0.5],        # クチバシが痛い
    ['􄁞􄁟', 'ソーサラー', 23, 15, 10, 16, 0.01, 0.5],      # 瞬間移動の杖を振る
    ['􄁄􄁅', 'メタルヨテイチ', 3, 500, 30, 49, 1.0, 0.5],   # 回避性のレアモン
    ['􄁠􄁡', 'おめん武者', 35, 40, 15, 26, 0.16, 0.5],      # 鎧の中は空洞だ
    ['􄁢􄁣', 'アクアター', 30, 25, 0, 19, 0.01, 0.5],       # ガッポーン。盾が錆びるぞ
    ['􄁤􄁥', 'どろぼう猫', 40, 20, 0, 17, 1.0, 0.0],        # アイテムを盗む
    ['􄄤􄄥', 'ガーゴイル', 45, 50, 18, 27, 0.33, 0.5],      # 石像のふりをしている
    ['􄁨􄁩', '四人トリオ', 60, 10, 11, 3, 0.0, 1.0],        # 4人で固まって出現する
    ['􄁪􄁫', '白い手', 72, 40, 7, 23, 0.0, 0.0],            # つかまると倒すまで動けない
    ['􄁬􄁭', 'ゴーレム', 52, 180, 32, 27, 0.33, 0.5],       # 巨大な泥人形
    ['􄁮􄁯', 'ボンプキン', 70, 30, 12, 23, 0.01, 0.5],      # 爆発する
    ['􄁰􄁱', 'パペット', 36, 40, 13, 23, 0.16, 0.5],        # レベルを下げる
    ['􄁲􄁳', 'ゆうれい', 60, 150, 17, 27, 0.0, 0.5],        # 見えない。ふらふら
    ['􄁴􄁵', 'ミミック', 50, 30, 24, 24, 0.0, 0.5],         # アイテム・階段に化ける
    ['􄄠􄄡', 'トロール', 51, 380, 51, 21, 0.16, 0.5],       # 強い
    ['􄁶􄁷', '目玉', 62, 250, 31, 27, 0.16, 0.5],           # 混乱させてくる
    ['􄁸􄁹', '化け狸', 80, 20, 9, 14, 0.0, 0.5],            # 別のモンスターに化ける
    ['􄁺􄁻', '土偶', 70, 150, 17, 24, 0.0, 0.5],            # HP、ちから最大値を下げる
    ['􄄢􄄣', 'デビルモンキー', 78, 600, 26, 25, 0.16, 0.5], # 二倍速
    ['􄁼􄁽', 'マルスボース', 75, 750, 51, 29, 0.16, 0.5],   # 強い
    ['􄁾􄁿', '竜', 100, 3000, 68, 30, 0.75, 0.5],           # テラ強い。火を吐く
  ]

  class << self
    def make_monster(name)
      row = SPECIES.find { |r| r[1] == name }
      fail "no such monster: #{name}" if row.nil?

      char, name, max_hp, exp, strength, defense, drop_rate, asleep_rate = row
      state = if asleep_rate < rand() then :awake else :asleep end
      return Monster.new(char, name, max_hp, strength, defense, exp, drop_rate,
                        state, [1,1], nil)
    end
  end

  attr :char, :name, :max_hp, :strength, :defense, :exp, :drop_rate
  attr_accessor :hp
  attr_accessor :state, :facing, :goal
  attr_accessor :item

  include StatusEffectPredicates

  def initialize(char, name, max_hp, strength, defense, exp, drop_rate,
                 state, facing, goal)
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
    when "催眠術師", "どろぼう猫"
      # 攻撃されると即反撃するモンスター
      @status_effects << StatusEffect.new(:paralysis, Float::INFINITY)
    when "ノーム"
      @item = Gold.new(rand(250..1500))
    when  "白い手"
      @status_effects << StatusEffect.new(:held, Float::INFINITY)
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
    else
      0.0
    end
  end

  def double_speed?
    case @name
    when "デビルモンキー", "ツバメ"
      true
    else
      false
    end
  end

  def single_attack?
    case @name
    when "デビルモンキー"
      false
    else
      true
    end
  end

end
