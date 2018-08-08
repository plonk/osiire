class Gold
  attr_accessor :amount
  attr_accessor :cursed

  def initialize(amount)
    @amount = amount
    @cursed = false
  end

  def char; '􄀲􄀳' end

  def name
    "#{amount}ゴールド"
  end

  def to_s
    name
  end
end

class Item
  ITEMS = [
    [:weapon, "こん棒", 1, nil],
    [:weapon, "金の剣", 2, nil],
    [:weapon, "銅の剣", 3, nil],
    [:weapon, "鉄の斧", 4, nil],
    [:weapon, "ドラゴンキラー", 5, nil],
    [:weapon, "メタルヨテイチの剣", 7, nil],
    [:weapon, "エンドゲーム", 10, nil],
    [:weapon, "必中会心剣", 20, "必ず当たり、会心の一撃が出る事もある強さ20の剣。"],
    [:projectile, "木の矢", nil, nil],
    [:projectile, "鉄の矢", nil, nil],
    [:projectile, "銀の矢", nil, nil],
    [:shield, "皮の盾", 3, "強さ3の盾。腹が減りにくくなる。"],
    [:shield, "青銅の盾", 3, nil],
    [:shield, "うろこの盾", 4, "強さ4の盾。毒を受けなくなる。"],
    [:shield, "銀の盾", 5, nil],
    [:shield, "鋼鉄の盾", 6, nil],
    [:shield, "ドラゴンシールド", 7, nil],
    [:shield, "メタルヨテイチの盾", 10, nil],
    [:herb, "薬草", nil, "HPを25回復する。"],
    [:herb, "高級薬草", nil, "HPを100回復する。"],
    [:herb, "毒けし草", nil, "ちからが回復する。"],
    [:herb, "ちからの種", nil, "ちからが満タンの時に最大値を1つ増やす。"],
    [:herb, "幸せの種", nil, "レベルが1つ上がる。"],
    [:herb, "すばやさの種", nil, nil],
    [:herb, "目薬草", nil, "ワナが見えるようになる。"],
    [:herb, "毒草", nil, nil],
    [:herb, "目つぶし草", nil, nil],
    [:herb, "まどわし草", nil, nil],
    [:herb, "混乱草", nil, "混乱してしまう。投げて使おう。"],
    [:herb, "睡眠草", nil, "眠ってしまう。投げて使おう。"],
    [:herb, "ワープ草", nil, "フロアの別の場所にワープする。"],
    [:herb, "火炎草", nil, "口から火をはく。敵に投げても使える。"],
    [:scroll, "やりなおしの巻物", nil, nil],
    [:scroll, "武器強化の巻物", nil, "武器が少し強くなる。"],
    [:scroll, "盾強化の巻物", nil, "盾が少し強くなる。"],
    [:scroll, "メッキの巻物", nil, "盾が錆びなくなる。"],
    [:scroll, "解呪の巻物", nil, "アイテムの呪いが解ける。"],
    [:scroll, "同定の巻物", nil, "何のアイテムか判別する。"],
    [:scroll, "あかりの巻物", nil, "フロア全体が見えるようになる。"],
    [:scroll, "かなしばりの巻物", nil, "隣接している敵をかなしばり状態にする。"],
    [:scroll, "結界の巻物", nil, "床に置くと敵に攻撃されなくなる。"],
    [:scroll, "さいごの巻物", nil, nil],
    [:scroll, "証明の巻物", nil, nil],
    [:scroll, "豚鼻の巻物", nil, "アイテムの位置がわかるようになる。"],
    [:scroll, "兎耳の巻物", nil, "モンスターの位置がわかるようになる。"],
    [:scroll, "パンの巻物", nil, "アイテムを大きなパンに変えてしまう。"],
    [:scroll, "祈りの巻物", nil, "杖の回数を増やす。"],
    [:scroll, "爆発の巻物", nil, "部屋の敵にダメージを与える。"],
    [:scroll, "くちなしの巻物", nil, nil],
    [:scroll, "時の砂の巻物", nil, nil],
    [:scroll, "ワナの巻物", nil, nil],
    [:scroll, "パルプンテの巻物", nil, nil],
    [:scroll, "ワナけしの巻物", nil, nil],
    [:scroll, "大部屋の巻物", nil, nil],
    [:staff, "いかずちの杖", nil, "敵にダメージを与える。"],
    [:staff, "鈍足の杖", nil, nil],
    [:staff, "睡眠の杖", nil, "敵を眠らせる。"],
    [:staff, "メダパニの杖", nil, nil],
    [:staff, "封印の杖", nil, nil],
    [:staff, "ワープの杖", nil, nil],
    [:staff, "変化の杖", nil, "敵を別の種類のモンスターに変化させる。"],
    [:staff, "ピオリムの杖", nil, nil],
    [:staff, "とうめいの杖", nil, "敵をとうめい状態にする。"],
    [:staff, "転ばぬ先の杖", nil, nil],
    [:staff, "分裂の杖", nil, "敵を分裂させてしまう。"],
    [:staff, "即死の杖", nil, "モンスターを即死させる。"],
    [:staff, "もろ刃の杖", nil, "敵のHPを残り1にするが、自分のHPが半分になる。"],
    [:staff, "大損の杖", nil, nil],
    [:ring, "ちからの指輪", nil, nil],
    [:ring, "毒けしの指輪", nil, "毒を受けなくなる。"],
    [:ring, "眠らずの指輪", nil, "眠らなくなる。"],
    [:ring, "ルーラの指輪", nil, nil],
    [:ring, "ハラヘラズの指輪", nil, "腹が減らなくなる。"],
    [:ring, "盗賊の指輪", nil, "敵を起こさずに部屋を出入りできる。"],
    [:ring, "きれいな指輪", nil, nil],
    [:ring, "シャドーの指輪", nil, nil],
    [:ring, "ハラペコの指輪", nil, nil],
    [:ring, "ワナ抜けの指輪", nil, nil],
    [:ring, "人形よけの指輪", nil, "敵にレベルやHPを下げられなくなる。"],
    [:ring, "ザメハの指輪", nil, nil],
    [:ring, "退魔の指輪", nil, "敵がおびえて逃げていく。"],
    [:food, "パン", nil, "満腹度が50%回復する。"],
    [:food, "大きなパン", nil, "満腹度が100%回復する。"],
    [:food, "くさったパン", nil, "満腹度100%回復。ダメージを受けてちからが減る。"],
    [:box, "鉄の金庫", nil, nil],
    [:box, "王様の宝石箱", nil, nil],
    [:box, "イェンダーの魔除け", nil, "これを取ったら帰り道。"],
    [:box, "奇妙な箱", nil, nil],
  ]

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
      row = ITEMS.find { |r| r[1] == name }
      fail "no such item: #{name}" if row.nil?

      type, name, number, desc = row
      item = Item.new(type, name, number, desc)

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
        item.number = item.number + r
        item.cursed = r == -1
      when :shield
        r = rand(-1..+3)
        item.number = item.number + r
        item.cursed = r == -1
      when :ring
        item.cursed = rand(0..1) == 0
      end

      return item
    end
  end

  attr :type, :name
  attr_accessor :number
  attr_accessor :gold_plated
  attr_accessor :stuck
  attr_accessor :mimic
  attr_accessor :cursed
  attr_accessor :inspected

  def initialize(type, name, number, desc)
    @type   = type
    @name   = name
    @number = number
    @desc   = desc
    if type == :shield
      if name == "銀の盾" || name == "皮の盾"
        @rustproof = true
      else
        @rustproof = false
      end
    else
      @rustproof = nil
    end
    @stuck = false
    @mimic = false
    @cursed = false
    @inspected = false
  end

  def original_number
    row = ITEMS.find { |r| r[1] == @name }
    if row
      return row[2]
    else
      return nil
    end
  end

  def relative_number
    n = original_number
    if n
      return @number - n
    else
      return nil
    end
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
      if @cursed
        prefix = "\u{10423C}"
      elsif @gold_plated
        prefix = "★"
      else
        prefix = ""
      end
      "#{prefix}#{name}#{ws_num_fmt.(relative_number)}"
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
    basics = ["投げる", "置く"]
    case type
    when :box
      [] + basics
    when :food
      ["食べる"] + basics
    when :herb
      ["飲む"] + basics
    when :projectile
      ["装備"] + basics
    when :ring
      ["装備"] + basics
    when :scroll
      ["読む"] + basics
    when :shield
      ["装備"] + basics
    when :staff
      ["ふる"] + basics
    when :weapon
      ["装備"] + basics
    else fail
      "uncovered case"
    end
  end

  def rustproof?
    @rustproof || @gold_plated
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
    when :box
      9
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
               "強さ#{original_number}の武器だ。"
             when :shield
               "強さ#{original_number}の盾だ。"
             when :projectile
               "投げて使う。"
             else
               "(なし)"
             end
  end

  def targeted_scroll?
    return false unless @type == :scroll

    case @name
    when "同定の巻物", "パンの巻物", "祈りの巻物"
      true
    else
      false
    end
  end

end
