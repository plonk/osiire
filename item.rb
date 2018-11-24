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
 {:type=>:projectile, :strength=>5, :name=>"木の矢", :desc=>"強さ5の矢"},
 {:type=>:projectile, :strength=>9, :name=>"鉄の矢", :desc=>"強さ9の矢"},
 {:type=>:projectile, :name=>"毒矢"},
 {:type=>:projectile, :strength=>11, :name=>"銀の矢",:desc=>"強さ11の矢。敵を貫通する。", :penetrating=>true},
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
 {:type=>:herb, :name=>"薬草", :desc=>"HPを25回復する。", :seal=>"薬", :abbrev=>"やくそう"},
 {:type=>:herb, :name=>"高級薬草", :desc=>"HPを100回復する。", :seal=>"高", :abbrev=>"こうきう"},
 {:type=>:herb, :name=>"命の草", :desc=>"最大HPを5上げる。", :seal=>"命", :abbrev=>"いのち"},
 {:type=>:herb, :name=>"毒けし草", :desc=>"ちからが回復する。", :seal=>"消", :abbrev=>"どくけし"},
 {:type=>:herb, :name=>"ちからの種", :desc=>"ちからが満タンの時に最大値を1つ増やす。", :seal=>"ち", :abbrev=>"ちから"},
 {:type=>:herb, :name=>"幸せの種", :desc=>"レベルが1つ上がる。", :seal=>"幸", :abbrev=>"しあわせ"},
 {:type=>:herb, :name=>"不幸の種", :desc=>"レベルが3つ下がる。", :seal=>"不", :abbrev=>"ふこう"},
 {:type=>:herb, :name=>"すばやさの種", :abbrev=>"すばやさ"},
 {:type=>:herb, :name=>"目薬草", :desc=>"ワナが見えるようになる。", :abbrev=>"めぐすり"},
 {:type=>:herb, :name=>"毒草", :abbrev=>"どくそう"},
 {:type=>:herb, :name=>"目つぶし草", :abbrev=>"めつぶし"},
 {:type=>:herb, :name=>"まどわし草", :abbrev=>"まどわし"},
 {:type=>:herb, :name=>"混乱草", :desc=>"混乱してしまう。投げて使おう。", :abbrev=>"こんらん"},
 {:type=>:herb, :name=>"睡眠草", :desc=>"眠ってしまう。投げて使おう。", :abbrev=>"すいみん"},
 {:type=>:herb, :name=>"ワープ草", :desc=>"フロアの別の場所にワープする。", :abbrev=>"わーぷ"},
 {:type=>:herb, :name=>"火炎草", :desc=>"口から火をはく。敵に投げても使える。", :seal=>"火", :abbrev=>"かえん"},
 # {:type=>:scroll, :name=>"やりなおしの巻物"},
 {:type=>:scroll, :name=>"武器強化の巻物", :desc=>"武器が少し強くなる。", :abbrev=>"ぶき"},
 {:type=>:scroll, :name=>"盾強化の巻物", :desc=>"盾が少し強くなる。", :abbrev=>"たて"},
 {:type=>:scroll, :name=>"メッキの巻物", :desc=>"盾が錆びなくなる。", :abbrev=>"めっき"},
 {:type=>:scroll, :name=>"解呪の巻物", :desc=>"アイテムの呪いが解ける。", :seal=>"祓", :abbrev=>"かいじゅ"},
 {:type=>:scroll, :name=>"同定の巻物", :desc=>"何のアイテムか判別する。", :seal=>"同", :abbrev=>"どうてい"},
 {:type=>:scroll, :name=>"あかりの巻物", :desc=>"フロア全体が見えるようになる。", :abbrev=>"あかり"},
 {:type=>:scroll, :name=>"かなしばりの巻物", :desc=>"隣接している敵をかなしばり状態にする。", :abbrev=>"かなしば"},
 {:type=>:scroll, :name=>"結界の巻物", :desc=>"床に置くと敵に攻撃されなくなる。", :abbrev=>"けっかい"},
 # {:type=>:scroll, :name=>"さいごの巻物"},
 # {:type=>:scroll, :name=>"証明の巻物"},
 {:type=>:scroll, :name=>"豚鼻の巻物", :desc=>"アイテムの位置がわかるようになる。", :abbrev=>"ぶたばな"},
 {:type=>:scroll, :name=>"兎耳の巻物", :desc=>"モンスターの位置がわかるようになる。", :abbrev=>"うさみみ"},
 {:type=>:scroll, :name=>"パンの巻物", :desc=>"アイテムを大きなパンに変えてしまう。", :abbrev=>"ぱん"},
 {:type=>:scroll, :name=>"祈りの巻物", :desc=>"杖の回数を増やす。", :abbrev=>"いのり"},
 {:type=>:scroll, :name=>"爆発の巻物", :desc=>"部屋の敵にダメージを与える。", :abbrev=>"ばくはつ"},
 # {:type=>:scroll, :name=>"くちなしの巻物"},
 # {:type=>:scroll, :name=>"時の砂の巻物"},
 {:type=>:scroll, :name=>"ワナの巻物", :abbrev=>"わな"},
 # {:type=>:scroll, :name=>"パルプンテの巻物"},
 {:type=>:scroll, :name=>"ワナけしの巻物", :abbrev=>"わなけし"},
 {:type=>:scroll, :name=>"大部屋の巻物", :abbrev=>"おおべや"},
 {:type=>:scroll, :name=>"パーティールームの巻物", :abbrev=>"ぱーてぃ"},
 {:type=>:scroll, :name=>"混乱の巻物", :abbrev=>"こんらん"},
 {:type=>:scroll, :name=>"ざわざわの巻物", :desc=>"ざわ… ざわ…", :abbrev=>"ざわざわ"},
 {:type=>:staff, :name=>"いかずちの杖", :desc=>"敵にダメージを与える。", :abbrev=>"いかずち"},
 {:type=>:staff, :name=>"鈍足の杖", :abbrev=>"どんそく"},
 {:type=>:staff, :name=>"睡眠の杖", :desc=>"敵を眠らせる。", :abbrev=>"すいみん"},
 # {:type=>:staff, :name=>"メダパニの杖", :abbrev=>"めだぱに"},
 {:type=>:staff, :name=>"封印の杖", :abbrev=>"ふういん"},
 {:type=>:staff, :name=>"ワープの杖", :abbrev=>"わーぷ"},
 {:type=>:staff, :name=>"変化の杖", :desc=>"敵を別の種類のモンスターに変化させる。", :abbrev=>"へんげ"},
 {:type=>:staff, :name=>"ピオリムの杖", :abbrev=>"ばいそく"}, # XXX
 {:type=>:staff, :name=>"とうめいの杖", :desc=>"敵をとうめい状態にする。", :abbrev=>"とうめい"},
 {:type=>:staff, :name=>"転ばぬ先の杖", :abbrev=>"ころばぬ"},
 {:type=>:staff, :name=>"分裂の杖", :desc=>"敵を分裂させてしまう。", :abbrev=>"ぶんれつ"},
 {:type=>:staff, :name=>"即死の杖", :desc=>"モンスターを即死させる。", :abbrev=>"そくし"},
 {:type=>:staff, :name=>"もろ刃の杖", :desc=>"敵のHPを残り1にするが、自分のHPが半分になる。", :abbrev=>"もろは"},
 {:type=>:staff, :name=>"大損の杖", :abbrev=>"おおぞん"},
 {:type=>:staff, :name=>"進化の杖", :desc=>"敵のレベルが1つ上がる。", :abbrev=>"しんか"},
 {:type=>:staff, :name=>"退化の杖", :desc=>"敵のレベルが1つ下がる。", :abbrev=>"たいか"},
 {:type=>:staff, :name=>"ばしがえの杖", :desc=>"敵と位置を入れ替える。", :abbrev=>"ばしがえ"},
 {:type=>:staff, :name=>"いちしのの杖", :desc=>"敵を階段上にワープさせる。", :abbrev=>"いちしの"},
 {:type=>:staff, :name=>"ふきとばの杖", :desc=>"敵をふきとばす。", :abbrev=>"ふきとば"},
 {:type=>:staff, :name=>"かなしばの杖", :desc=>"敵がかなしばり状態になる。", :abbrev=>"かなしば"},
 {:type=>:ring, :name=>"ちからの指輪", :abbrev=>"いから"},
 {:type=>:ring, :name=>"毒けしの指輪", :desc=>"毒を受けなくなる。", :abbrev=>"どくけし"},
 {:type=>:ring, :name=>"眠らずの指輪", :desc=>"眠らなくなる。", :abbrev=>"ねむらず"},
 {:type=>:ring, :name=>"ワープの指輪", :desc=>"攻撃を受けるとワープする。", :abbrev=>"わーぷ"},
 {:type=>:ring, :name=>"ハラヘラズの指輪", :desc=>"腹が減らなくなる。", :abbrev=>"はらへら"},
 {:type=>:ring, :name=>"盗賊の指輪", :desc=>"敵を起こさずに部屋を出入りできる。", :abbrev=>"とうぞく"},
 {:type=>:ring, :name=>"きれいな指輪", :abbrev=>"きれいな"},
 {:type=>:ring, :name=>"シャドーの指輪", :abbrev=>"しゃどー"},
 {:type=>:ring, :name=>"ハラペコの指輪", :abbrev=>"はらぺこ"},
 {:type=>:ring, :name=>"ワナ抜けの指輪", :abbrev=>"わなぬけ"},
 {:type=>:ring, :name=>"人形よけの指輪", :desc=>"敵にレベルやHPを下げられなくなる。", :abbrev=>"にんぎょう"},
 {:type=>:ring, :name=>"ザメハの指輪", :abbrev=>"ざめは"},
 {:type=>:ring, :name=>"壁抜けの指輪", :desc=>"壁に入れる。", :attrs=>[:kabenuke], :abbrev=>"かべぬけ"},
 {:type=>:ring, :name=>"身代わりの指輪", :desc=>"死んでも生きかえる。", :abbrev=>"みがわり"},
 {:type=>:food, :name=>"パン", :desc=>"満腹度が50%回復する。", :seal=>"飯"},
 {:type=>:food, :name=>"大きなパン", :desc=>"満腹度が100%回復する。", :seal=>"飯"},
 {:type=>:food, :name=>"くさったパン", :desc=>"満腹度100%回復。ダメージを受けてちからが減る。"},
 {:type=>:food, :name=>"こんがりトースト", :desc=>"満腹度が50%、HPが30回復。"},
 {:type=>:jar, :name=>"保存の壺", :desc=>"アイテムをこれに入れておけば呪われたりしない。", :abbrev=>"ほぞん"},
 {:type=>:jar, :name=>"識別の壺", :desc=>"入れたアイテムが同定される。", :abbrev=>"しきべつ"},
 {:type=>:jar, :name=>"合成の壺", :desc=>"同種のアイテムが合成される。", :abbrev=>"ごうせい"},
 {:type=>:jar, :name=>"変化の壺", :desc=>"アイテムが変化する。", :abbrev=>"へんげ"},
 {:type=>:jar, :name=>"祝福の壺", :desc=>"アイテムが祝福される。", :abbrev=>"しくふく"},
 {:type=>:jar, :name=>"換金の壺", :desc=>"アイテムが換金される。", :abbrev=>"かんきん"},
 {:type=>:jar, :name=>"弱化の壺", :desc=>"入れたアイテムが弱くなる。", :abbrev=>"じゃくか"},
 {:type=>:jar, :name=>"回復の壺", :desc=>"アイテムを入れると消えて、HPが回復する。", :abbrev=>"かいふく"},
 {:type=>:jar, :name=>"手封じの壺", :desc=>"手が使えなくなる。", :abbrev=>"てふうじ"},
 {:type=>:jar, :name=>"底抜けの壺", :desc=>"割ると落とし穴が出る。", :abbrev=>"そこぬけ"},
 {:type=>:jar, :name=>"水がめ", :desc=>"水を汲んで持ち運べる。", :abbrev=>"みずがめ"},
 {:type=>:jar, :name=>"やりすごしの壺", :desc=>"中に入ってモンスターをやりすごせる。", :abbrev=>"やりすご"},
 {:type=>:water, :name=>"水", :desc=>"ワナを消す。かけると効果のあるモンスターもいる。"},
 {:type=>:trap, :name=>"落とし穴", :desc=>"次のフロアに落ちてしまう。"},
]

  CHARS = {
    :box => "􄄺􄄻",
    :food => "􄀶􄀷",
    :herb => "􄀰􄀱",
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
      when :water
        item = Water.new(definition)
      when :projectile
        item = Projectile.new(definition)
      when :trap
        item = TrapItem.new(definition)
      when :ring
        item = Ring.new(definition)
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
        case item.name
        when "木の矢"
          item.number = rand(10..20)
        when "鉄の矢"
          item.number = rand(5..15)
        when "銀の矢"
          item.number = rand(5..10)
        else
          item.number = rand(5..15)
        end
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
    else
      []
    end
  end

  def effective_seals
    [*self.own_seal, *self.seals]
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

  def toast!
    fail unless type == :food
    @name = "こんがりトースト"
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

  def actions
    if @name == "水がめ"
      ["見る", "入れる", "出す"]
    else
      ["見る", "入れる"]
    end
  end

end

# 水がめに入れる水
class Water < Item
  def initialize(definitioin)
    super
  end

  def char
    "\u{10442c}\u{10442d}"
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

  def desc
    "敵に当てると金額の1/10のダメージを与える。"
  end

  def to_s
    name
  end

end

class Projectile < Item
  attr_reader :strength

  def initialize(definition)
    super
    @strength = definition[:strength] || 0
    @penetrating = definition[:penetrating] || false
  end

  def penetrating?
    @penetrating
  end

  def char
    case name
    when "大砲の弾"
      "\u{104452}\u{104453}"
    else
      "􄁌􄁍" # 矢
    end
  end

  def to_s
    if number == 1
      name
    elsif name == "大砲の弾"
      "#{number}個の#{name}"
    else
      "#{number}本の#{name}"
    end
  end

end

class TrapItem < Item
  def initialize(definition)
    super
  end

  def to_trap(opts = {})
    Trap.new(@name, opts[:visible] || false)
  end

  def char
    Trap::TRAPS[@name][:char]
  end
end

class Ring < Item
  attr_accessor :life

  def initialize(definition)
    super
    @life = 25
  end

  def cracked?
    @life <= 5
  end

  def to_s
    if @cursed
      prefix = "\u{10423C}"
    end
    if cracked?
      suffix = "(\u{104454}\u{104455})"
    end
    "#{prefix}#{name}#{suffix}"
  end
end

