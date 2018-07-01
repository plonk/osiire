class Gold < Struct.new(:amount)
  def char; '􄀲􄀳' end

  def to_s
    "#{amount}ゴールド"
  end
end

class Item
  ITEMS = [
    [:weapon, "こん棒", 1],
    [:weapon, "金の剣", 2],
    [:weapon, "銅の剣", 3],
    [:weapon, "鉄の斧", 4],
    [:weapon, "ドラゴンキラー", 5],
    [:weapon, "メタルヨテイチの剣", 7],
    [:weapon, "エクスカリバー", 10],
    [:projectile, "木の矢", nil],
    [:projectile, "鉄の矢", nil],
    [:projectile, "銀の矢", nil],
    [:shield, "皮の盾", 3],
    [:shield, "青銅の盾", 3],
    [:shield, "うろこの盾", 4],
    [:shield, "銀の盾", 5],
    [:shield, "鋼鉄の盾", 6],
    [:shield, "ドラゴンシールド", 7],
    [:shield, "メタルヨテイチの盾", 10],
    [:herb, "薬草", nil],
    [:herb, "高級薬草", nil],
    [:herb, "毒けし草", nil],
    [:herb, "ちからの種", nil],
    [:herb, "幸せの種", nil],
    [:herb, "すばやさの種", nil],
    [:herb, "目薬草", nil],
    [:herb, "毒草", nil],
    [:herb, "目つぶし草", nil],
    [:herb, "まどわし草", nil],
    [:herb, "混乱草", nil],
    [:herb, "睡眠草", nil],
    [:herb, "ワープ草", nil],
    [:herb, "火炎草", nil],
    [:scroll, "やりなおしの巻物", nil],
    [:scroll, "武器強化の巻物", nil],
    [:scroll, "盾強化の巻物", nil],
    [:scroll, "メッキの巻物", nil],
    [:scroll, "シャナクの巻物", nil],
    [:scroll, "インパスの巻物", nil],
    [:scroll, "あかりの巻物", nil],
    [:scroll, "かなしばりの巻物", nil],
    [:scroll, "結界の巻物", nil],
    [:scroll, "さいごの巻物", nil],
    [:scroll, "証明の巻物", nil],
    [:scroll, "千里眼の巻物", nil],
    [:scroll, "地獄耳の巻物", nil],
    [:scroll, "パンの巻物", nil],
    [:scroll, "祈りの巻物", nil],
    [:scroll, "爆発の巻物", nil],
    [:scroll, "くちなしの巻物", nil],
    [:scroll, "時の砂の巻物", nil],
    [:scroll, "ワナの巻物", nil],
    [:scroll, "パルプンテの巻物", nil],
    [:staff, "いかずちの杖", nil],
    [:staff, "ボミオスの杖", nil],
    [:staff, "睡眠の杖", nil],
    [:staff, "メダパニの杖", nil],
    [:staff, "封印の杖", nil],
    [:staff, "ワープの杖", nil],
    [:staff, "変化の杖", nil],
    [:staff, "ピオリムの杖", nil],
    [:staff, "レオルムの杖", nil],
    [:staff, "転ばぬ先の杖", nil],
    [:staff, "分裂の杖", nil],
    [:staff, "ザキの杖", nil],
    [:staff, "もろ刃の杖", nil],
    [:staff, "大損の杖", nil],
    [:ring, "ちからの指輪", nil],
    [:ring, "毒けしの指輪", nil],
    [:ring, "眠らずの指輪", nil],
    [:ring, "ルーラの指輪", nil],
    [:ring, "ハラヘラズの指輪", nil],
    [:ring, "盗賊の指輪", nil],
    [:ring, "きれいな指輪", nil],
    [:ring, "シャドーの指輪", nil],
    [:ring, "ハラペコの指輪", nil],
    [:ring, "ワナ抜けの指輪", nil],
    [:ring, "人形よけの指輪", nil],
    [:ring, "ザメハの指輪", nil],
    [:food, "パン", nil],
    [:food, "大きなパン", nil],
    [:food, "くさったパン", nil],
    [:box, "鉄の金庫", nil],
    [:box, "王様の宝石箱", nil],
    [:box, "イェンダーの魔除け", nil],
    [:box, "奇妙な箱", nil],
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

      type, name, number = row
      item = Item.new(type, name, number)

      case item.type
      when :staff
        if item.name == "転ばぬ先の杖"
          item.number = 0
        else
          # 杖の場合 5~8 で回数を設定する。
          item.number = 3 + rand(5)
        end
      when :projectile
        item.number = rand(5..15)
      end

      return item
    end
  end

  attr :type, :name
  attr_accessor :number
  attr_accessor :gold_plated
  attr_accessor :stuck

  def initialize(type, name, number)
    @type   = type
    @name   = name
    @number = number
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
  end

  def relative_number
    row = ITEMS.find { |r| r[1] == @name }
    if row
      return @number - row[2]
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
    when :weapon, :shield
      star = @gold_plated ? "★" : ""
      "#{star}#{name}#{ws_num_fmt.(relative_number)}"
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
    basics = ["投げる", "置く", "説明"]
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

end
