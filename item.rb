class Item
  ITEMS =
[{:type=>:weapon, :name=>"鍛えた木刀", :number=>2, :nslots=>1},
 {:type=>:weapon, :name=>"こんぼう", :number=>3, :nslots=>3},
 {:type=>:weapon, :name=>"銅の剣", :number=>5, :nslots=>4},
 {:type=>:weapon, :name=>"カタナ", :number=>8, :nslots=>5},
 {:type=>:weapon, :name=>"エンドゲーム", :number=>10, :nslots=>6},
 {:type=>:weapon, :name=>"真・エンドゲーム", :number=>18, :nslots=>6},
 {:type=>:weapon, :name=>"成仏のカマ",         :seal=>"仏", :number=>4, :nslots=>5},
 {:type=>:weapon, :name=>"マリンスラッシャー", :seal=>"水", :number=>5, :nslots=>5},
 {:type=>:weapon, :name=>"一ツ目殺し",         :seal=>"目", :number=>6, :nslots=>4},
 {:type=>:weapon, :name=>"ドレインバスター",   :seal=>"ド", :number=>6, :nslots=>5},
 {:type=>:weapon, :name=>"三日月刀",           :seal=>"月", :number=>6, :nslots=>4},
 {:type=>:weapon, :name=>"ドラゴンキラー",     :seal=>"竜", :number=>15, :nslots=>3},
 {:type=>:weapon, :name=>"龍神剣",             :seal=>"龍", :number=>25, :nslots=>7},
 {:type=>:weapon, :name=>"衰弱の枝",           :seal=>"衰", :number=>1, :nslots=>3},
 {:type=>:weapon, :name=>"つるはし",           :seal=>"堀", :number=>2, :nslots=>5},
 {:type=>:weapon, :name=>"妖刀かまいたち",     :seal=>"三", :number=>2, :nslots=>4},
 {:type=>:weapon, :name=>"ガマラのムチ",       :seal=>"銭", :number=>2, :nslots=>4},
 {:type=>:weapon, :name=>"根性の竹刀",         :seal=>"根", :number=>3, :nslots=>2},
 {:type=>:weapon, :name=>"金の剣",             :seal=>"金", :number=>3, :nslots=>5, :rustproof=>true},
 {:type=>:weapon, :name=>"必中の剣",           :seal=>"必", :number=>3, :nslots=>3},
 {:type=>:weapon, :name=>"にぎりへんげの剣",   :seal=>"に", :number=>3, :nslots=>4},
 {:type=>:weapon, :name=>"かつおぶし",         :seal=>"か", :number=>4, :nslots=>2},
 {:type=>:weapon, :name=>"車輪のやいば",       :seal=>"車", :number=>4, :nslots=>3},
 {:type=>:weapon, :name=>"背水の剣",           :seal=>"背", :number=>5, :nslots=>4},
 {:type=>:weapon, :name=>"回復の剣",           :seal=>"回", :number=>6, :nslots=>3},
 {:type=>:weapon, :name=>"ケンゴウのカタナ",   :seal=>"ケ", :number=>7, :nslots=>4},
 {:type=>:weapon, :name=>"鉄扇",               :seal=>"扇", :number=>8, :nslots=>2},
 {:type=>:weapon, :name=>"サトリのつるはし",   :seal=>"サ", :number=>8, :nslots=>4, :break_count=>Float::INFINITY},
 {:type=>:weapon, :name=>"使い捨ての剣",       :seal=>"捨", :number=>35, :nslots=>3},
 {:type=>:weapon, :name=>"モーニングスター",   :seal=>"八", :unsealifiable=>true,
  :two_handed=>true, :number=>5, :nslots=>6},
 {:type=>:weapon, :name=>"如意棒",             :seal=>"棒", :unsealifiable=>true,
  :two_handed=>true, :number=>5, :nslots=>4},
 {:type=>:weapon, :name=>"アイアンヘッドの頭", :seal=>"頭", :unsealifiable=>true,
  :two_handed=>true, :number=>9, :nslots=>7},
 {:type=>:weapon, :name=>"ヤリ",               :seal=>"槍", :unsealifiable=>true,
  :two_handed=>true, :number=>10, :nslots=>8},
 {:type=>:weapon, :name=>"ぶっとびハンマー",   :seal=>"跳", :unsealifiable=>true,
  :two_handed=>true, :number=>10, :nslots=>7},
 {:type=>:weapon, :name=>"木づち",             :seal=>"木", :two_handed=>true, :number=>10, :nslots=>4},
 {:type=>:weapon, :name=>"ミノタウロスの斧",   :seal=>"会", :two_handed=>true, :number=>20, :nslots=>8},
 {:type=>:projectile, :name=>"木の矢"},
 {:type=>:projectile, :name=>"鉄の矢"},
 {:type=>:projectile, :name=>"毒矢"},
 {:type=>:projectile, :name=>"銀の矢"},
 {:type=>:projectile, :name=>"大砲の弾"},
 {:type=>:shield, :name=>"鍛えた木の盾", :number=>2, :nslots=>1},
 {:type=>:shield, :name=>"みやびやかな盾", :number=>2, :nslots=>7},
 {:type=>:shield, :name=>"青銅甲の盾", :number=>5, :nslots=>5},
 {:type=>:shield, :name=>"鉄甲の盾", :number=>9, :nslots=>5},
 {:type=>:shield, :name=>"獣王の盾", :number=>12, :nslots=>4},
 {:type=>:shield, :name=>"風魔の盾", :number=>16, :nslots=>6},
 {:type=>:shield, :name=>"サトリの盾", :seal=>"サ", :number=>1, :nslots=>1},
 {:type=>:shield, :name=>"皮の盾", :seal=>"皮", :number=>2, :nslots=>5, :rustproof=>true},
 {:type=>:shield, :name=>"見切りの盾", :seal=>"見", :number=>2, :nslots=>5},
 {:type=>:shield, :name=>"やまびこの盾", :seal=>"山", :number=>3, :nslots=>5},
 {:type=>:shield, :name=>"おまつりの盾", :seal=>"祭", :number=>4, :nslots=>5},
 {:type=>:shield, :name=>"トドの盾", :seal=>"ト", :number=>4, :nslots=>6},
 {:type=>:shield, :name=>"金の盾", :seal=>"金", :number=>4, :nslots=>4},
 {:type=>:shield, :name=>"ゴムバンの盾", :seal=>"ゴ", :number=>5, :nslots=>3},
 {:type=>:shield, :name=>"ガマラの盾", :seal=>"銭", :number=>5, :nslots=>5},
 {:type=>:shield, :name=>"地雷ナバリの盾", :seal=>"爆", :number=>5, :nslots=>5},
 {:type=>:shield, :name=>"バトルカウンター", :seal=>"バ", :number=>5, :nslots=>6},
 {:type=>:shield, :name=>"どんぶりの盾", :seal=>"丼", :number=>5, :nslots=>3},
 {:type=>:shield, :name=>"身かわしの盾", :seal=>"身", :number=>5, :nslots=>4},
 {:type=>:shield, :name=>"うろこの盾", :seal=>"う", :number=>6, :nslots=>5},
 {:type=>:shield, :name=>"しあわせの盾", :seal=>"幸", :number=>6, :nslots=>5},
 {:type=>:shield, :name=>"不動の盾", :seal=>"不", :number=>8, :nslots=>3},
 {:type=>:shield, :name=>"ドラゴンシールド", :seal=>"竜", :number=>10, :nslots=>3},
 {:type=>:shield, :name=>"重装の盾", :seal=>"重", :number=>12, :nslots=>5},
 {:type=>:shield, :name=>"正面戦士の盾", :seal=>"正", :number=>30, :nslots=>5},
 {:type=>:shield, :name=>"使い捨ての盾", :seal=>"捨", :number=>40, :nslots=>3},
 {:type=>:shield, :name=>"矛の盾", :unsealifiable=>true, :seal=>"星", :number=>7, :nslots=>5, :two_handed=>true},
 {:type=>:shield, :name=>"グランドカウンター", :unsealifiable=>true, :seal=>"グ", :number=>9, :nslots=>9, :two_handed=>true},
 {:type=>:herb, :name=>"薬草", :desc=>"HPを25回復する。", :seal=>"薬"},
 {:type=>:herb, :name=>"高級薬草", :desc=>"HPを100回復する。", :seal=>"高"},
 {:type=>:herb, :name=>"毒けし草", :desc=>"ちからが回復する。", :seal=>"消"},
 {:type=>:herb, :name=>"ちからの種", :desc=>"ちからが満タンの時に最大値を1つ増やす。", :seal=>"ち"},
 {:type=>:herb, :name=>"幸せの種", :desc=>"レベルが1つ上がる。", :seal=>"幸"},
 {:type=>:herb, :name=>"すばやさの種"},
 {:type=>:herb, :name=>"目薬草", :desc=>"ワナが見えるようになる。"},
 {:type=>:herb, :name=>"毒草"},
 {:type=>:herb, :name=>"目つぶし草"},
 {:type=>:herb, :name=>"まどわし草"},
 {:type=>:herb, :name=>"混乱草", :desc=>"混乱してしまう。投げて使おう。"},
 {:type=>:herb, :name=>"睡眠草", :desc=>"眠ってしまう。投げて使おう。"},
 {:type=>:herb, :name=>"ワープ草", :desc=>"フロアの別の場所にワープする。"},
 {:type=>:herb, :name=>"火炎草", :desc=>"口から火をはく。敵に投げても使える。", :seal=>"火"},
 {:type=>:scroll, :name=>"やりなおしの巻物"},
 {:type=>:scroll, :name=>"武器強化の巻物", :desc=>"武器が少し強くなる。"},
 {:type=>:scroll, :name=>"盾強化の巻物", :desc=>"盾が少し強くなる。"},
 {:type=>:scroll, :name=>"メッキの巻物", :desc=>"盾が錆びなくなる。"},
 {:type=>:scroll, :name=>"解呪の巻物", :desc=>"アイテムの呪いが解ける。", :seal=>"祓"},
 {:type=>:scroll, :name=>"同定の巻物", :desc=>"何のアイテムか判別する。", :seal=>"同"},
 {:type=>:scroll, :name=>"あかりの巻物", :desc=>"フロア全体が見えるようになる。"},
 {:type=>:scroll, :name=>"かなしばりの巻物", :desc=>"隣接している敵をかなしばり状態にする。"},
 {:type=>:scroll, :name=>"結界の巻物", :desc=>"床に置くと敵に攻撃されなくなる。"},
 {:type=>:scroll, :name=>"さいごの巻物"},
 {:type=>:scroll, :name=>"証明の巻物"},
 {:type=>:scroll, :name=>"豚鼻の巻物", :desc=>"アイテムの位置がわかるようになる。"},
 {:type=>:scroll, :name=>"兎耳の巻物", :desc=>"モンスターの位置がわかるようになる。"},
 {:type=>:scroll, :name=>"パンの巻物", :desc=>"アイテムを大きなパンに変えてしまう。"},
 {:type=>:scroll, :name=>"祈りの巻物", :desc=>"杖の回数を増やす。"},
 {:type=>:scroll, :name=>"爆発の巻物", :desc=>"部屋の敵にダメージを与える。"},
 {:type=>:scroll, :name=>"くちなしの巻物"},
 {:type=>:scroll, :name=>"時の砂の巻物"},
 {:type=>:scroll, :name=>"ワナの巻物"},
 {:type=>:scroll, :name=>"パルプンテの巻物"},
 {:type=>:scroll, :name=>"ワナけしの巻物"},
 {:type=>:scroll, :name=>"大部屋の巻物"},
 {:type=>:scroll, :name=>"ざわざわの巻物", :desc=>"ざわ… ざわ…"},
 {:type=>:staff, :name=>"いかずちの杖", :desc=>"敵にダメージを与える。"},
 {:type=>:staff, :name=>"鈍足の杖"},
 {:type=>:staff, :name=>"睡眠の杖", :desc=>"敵を眠らせる。"},
 {:type=>:staff, :name=>"メダパニの杖"},
 {:type=>:staff, :name=>"封印の杖"},
 {:type=>:staff, :name=>"ワープの杖"},
 {:type=>:staff, :name=>"変化の杖", :desc=>"敵を別の種類のモンスターに変化させる。"},
 {:type=>:staff, :name=>"ピオリムの杖"},
 {:type=>:staff, :name=>"とうめいの杖", :desc=>"敵をとうめい状態にする。"},
 {:type=>:staff, :name=>"転ばぬ先の杖"},
 {:type=>:staff, :name=>"分裂の杖", :desc=>"敵を分裂させてしまう。"},
 {:type=>:staff, :name=>"即死の杖", :desc=>"モンスターを即死させる。"},
 {:type=>:staff, :name=>"もろ刃の杖", :desc=>"敵のHPを残り1にするが、自分のHPが半分になる。"},
 {:type=>:staff, :name=>"大損の杖"},
 {:type=>:staff, :name=>"進化の杖", :desc=>"敵のレベルが1つ上がる。"},
 {:type=>:staff, :name=>"退化の杖", :desc=>"敵のレベルが1つ下がる。"},
 {:type=>:ring, :name=>"ちからの指輪"},
 {:type=>:ring, :name=>"毒けしの指輪", :desc=>"毒を受けなくなる。"},
 {:type=>:ring, :name=>"眠らずの指輪", :desc=>"眠らなくなる。"},
 {:type=>:ring, :name=>"ワープの指輪", :desc=>"攻撃を受けるとワープする。"},
 {:type=>:ring, :name=>"ハラヘラズの指輪", :desc=>"腹が減らなくなる。"},
 {:type=>:ring, :name=>"盗賊の指輪", :desc=>"敵を起こさずに部屋を出入りできる。"},
 {:type=>:ring, :name=>"きれいな指輪"},
 {:type=>:ring, :name=>"シャドーの指輪"},
 {:type=>:ring, :name=>"ハラペコの指輪"},
 {:type=>:ring, :name=>"ワナ抜けの指輪"},
 {:type=>:ring, :name=>"人形よけの指輪", :desc=>"敵にレベルやHPを下げられなくなる。"},
 {:type=>:ring, :name=>"ザメハの指輪"},
 {:type=>:ring, :name=>"壁抜けの指輪", :desc=>"壁に入れる。", :attrs=>[:kabenuke]},
 {:type=>:food, :name=>"パン", :desc=>"満腹度が50%回復する。", :seal=>"飯"},
 {:type=>:food, :name=>"大きなパン", :desc=>"満腹度が100%回復する。", :seal=>"飯"},
 {:type=>:food, :name=>"くさったパン", :desc=>"満腹度100%回復。ダメージを受けてちからが減る。"},
 {:type=>:jar, :name=>"保存の壺", :desc=>"アイテムをこれに入れておけば呪われたりしない。"},
 {:type=>:jar, :name=>"識別の壺", :desc=>"入れたアイテムが同定される。"},
 {:type=>:jar, :name=>"合成の壺", :desc=>"同種のアイテムが合成される。"},
 {:type=>:jar, :name=>"変化の壺", :desc=>"アイテムが変化する。"},
 {:type=>:jar, :name=>"祝福の壺", :desc=>"アイテムが祝福される。"},
 {:type=>:jar, :name=>"換金の壺", :desc=>"アイテムが換金される。"},
 {:type=>:jar, :name=>"弱化の壺", :desc=>"入れたアイテムが弱くなる。"},
 {:type=>:jar, :name=>"回復の壺", :desc=>"アイテムを入れると消えて、HPが回復する。"},
 {:type=>:jar, :name=>"手封じの壺", :desc=>"手が使えなくなる。"},
 {:type=>:jar, :name=>"底抜けの壺", :desc=>"割ると落とし穴が出る。"},
 {:type=>:jar, :name=>"水がめ", :desc=>"水を汲んで持ち運べる。"},
 {:type=>:jar, :name=>"やりすごしの壺", :desc=>"中に入ってモンスターをやりすごせる。"}]

  CHARS = {
    :box => "􄄺􄄻",
    :food => "􄀶􄀷",
    :herb => "􄀰􄀱",
    :projectile => "􄁌􄁍",
    :ring => "􄀸􄀹",
    :scroll => "􄀴􄀵",
    :shield => "􄀮􄀯",
    :staff => "􄀺􄀻",
    :weapon => "􄀬􄀭",
  }

  class << self
    def make_item(name)
      definition = ITEMS.find { |r| r[:name] == name }
      fail "no such item: #{name}" if definition.nil?

      case definition[:type]
      when :jar
        item = Jar.new(definition)
      else
        item = Item.new(definition)
      end

      case item.type
      when :staff
        case item.name
        when "転ばぬ先の杖", "即死の杖"
          item.number = 0
        else
          # 杖の場合 5~8 で回数を設定する。
          item.number = 3 + rand(5)
        end
      when :projectile
        item.number = rand(5..15)
      when :weapon
        r = rand(-1..+3)
        item.correction = r
        item.cursed = r == -1
      when :shield
        if item.name == "鍛えた木の盾"
          r = [-1, +4, +5, +6, +7, +8].sample
          item.correction = r
          item.cursed = (r == -1)
        else
          r = rand(-1..+3)
          item.correction = r
          item.cursed = r == -1
        end
      when :ring
        item.cursed = rand(5) == 0
      when :jar
        case item.name
        when "合成の壺"
          item.capacity = rand(2..4)
        else
          item.capacity = rand(3..5)
        end
      end

      return item
    end
  end

  attr :type, :name
  attr_accessor :number, :nslots
  attr_accessor :gold_plated
  attr_accessor :stuck
  attr_accessor :mimic
  attr_accessor :mimic_name
  attr_accessor :cursed
  attr_accessor :inspected
  attr_accessor :correction # 武器盾の修正値
  attr_accessor :own_seal
  attr_accessor :unsealifiable
  attr_accessor :break_count
  attr_accessor :two_handed
  attr :attrs

  def initialize(definition)
    @type      = definition[:type]
    @name      = definition[:name]
    @number    = definition[:number]
    @nslots    = definition[:nslots]
    @desc      = definition[:desc]
    @rustproof = definition[:rustproof] || false
    @unsealifiable = definition[:unsealifiable] || false
    @stuck = false
    @mimic = false
    @cursed = false
    @inspected = false
    @correction = nil
    @seals = []

    if definition[:seal]
      @own_seal = Seal.new(definition[:seal], seal_color(@type))
    else
      @own_seal = nil
    end

    @mimic_name = nil
    @break_count = definition[:break_count] || 50
    @two_handed = definition[:two_handed]
    @attrs = definition[:attrs] || []
  end

  def corrected_number
    @number + @correction
  end

  def char
    if @type == :scroll && @stuck
      return '􄅄􄅅'
    else
      c = CHARS[@type]
      unless c
        fail "type: #{@type}"
      end
      return c
    end
  end

  def to_s
    # weapon/shield number format
    ws_num_fmt = proc do |r|
      if r.nil?
        "?"
      elsif r == 0
        ""
      elsif r < 0
        r.to_s
      else
        "+#{r}"
      end
    end

    case type
    when :ring
      if @cursed
        prefix = "\u{10423C}"
      end
      "#{prefix}#{name}"
    when :weapon, :shield
      prefix = ""
      if @cursed
        prefix += "\u{10423C}"
      end
      if has_gold_seal?
        prefix += "\u{10423D}"
      end
      "#{prefix}#{name}#{ws_num_fmt.(@correction)}"
    when :staff
      "#{name}[#{number}]"
    when :projectile
      if number == 1
        name
      else
        "#{number}本の#{name}"
      end
    else
      name
    end
  end

  def actions
    case type
    when :box
      []
    when :food
      ["食べる"]
    when :herb
      ["飲む"]
    when :projectile
      ["装備"]
    when :ring
      ["装備"]
    when :scroll
      ["読む"]
    when :shield
      ["装備"]
    when :staff
      ["ふる"]
    when :weapon
      if effective_seals.any? { |s| s.char == "か" }
        ["装備", "かじる"]
      else
        ["装備"]
      end
    when :jar
      if two_way_jar?()
        ["見る", "入れる", "出す"]
      else
        ["見る", "入れる"]
      end
    else fail
      "uncovered case"
    end
  end

  def effective_seals
    [*self.own_seal, *self.seals]
  end

  def two_way_jar?
    case @name
    when "保存の壺", "水がめ"
      true
    else
      false
    end
  end

  def rustproof?
    @rustproof || has_gold_seal?
  end

  def has_gold_seal?
    @seals.any? {|s|s.char=="金"}
  end

  def sort_priority
    case @type
    when :weapon
      1
    when :shield
      2
    when :ring
      3
    when :projectile
      4
    when :food
      5
    when :herb
      6
    when :scroll
      7
    when :staff
      8
    when :jar
      9
    when :box
      10
    else
      fail "unknown item type #{type}"
    end
  end

  def projectile_strength
    fail unless type == :projectile
    return 5
  end

  def desc
    @desc || case type
             when :weapon
               "強さ#{@number}の武器だ。"
             when :shield
               "強さ#{@number}の盾だ。"
             when :projectile
               "投げて使う。"
             else
               "(なし)"
             end
  end

  def targeted_scroll?
    return false unless @type == :scroll

    case @name
    when "同定の巻物", "パンの巻物", "祈りの巻物", "メッキの巻物"
      true
    else
      false
    end
  end

  def seals
    @seals
  end

  def seal_color(type)
    case type
    when :herb, :food
      :green
    when :weapon, :shield
      :blue
    else
      :red
    end
  end

end

# 壺
class Jar < Item
  attr_accessor :capacity
  attr_accessor :contents
  attr_accessor :unbreakable

  def initialize(definition)
    super(definition)
    @contents = []
    @unbreakable = false
  end

  def to_s
    "#{name}[#{@capacity - @contents.size}]"
  end

  def char
    "\u{10432e}\u{10432f}"
  end

end

class Gold < Item
  attr_accessor :amount
  attr_accessor :cursed

  def initialize(amount)
    @amount = amount
    @cursed = false
  end

  def type
    :gold
  end

  def char; '􄀲􄀳' end

  def name
    "#{amount}ゴールド"
  end

  def to_s
    name
  end
end

