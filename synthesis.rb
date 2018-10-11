module Synthesis
  module_function

  # 特殊合成。
  # Item → Item
  def transmute(item)
    post_process = lambda { |i|
      i.correction = 0
      i.cursed = item.cursed
      i.inspected = true
      return i
    }
    if item.name == "つるはし" &&
       item.seals.count { |s| s.char == "堀" } == 5
      post_process.(Item.make_item("サトリのつるはし"))
    elsif item.name == "木づち" &&
          item.seals.count { |s| s.char == "木" } == 4
      post_process.(Item.make_item("ぶっとびハンマー"))
    elsif item.name == "ドラゴンキラー" &&
          item.seals.count { |s| s.char == "竜" } == 3
      post_process.(Item.make_item("龍神剣"))
    else
      # 変化なし。
      item
    end
  end

  # 武器同士／盾同士の合成
  # (Item, Item) → [Item]
  def synthesize_weapon_or_shield(item1, item2)
    fail unless item1.type == item2.type

    if item2.unsealifiable
      [item1, item2]
    else
      seals =
        [*item1.seals, *item2.own_seal, *item2.seals]
        .take(item1.nslots)

      item1.seals.replace(seals)
      item1.correction += item2.correction
      item1.cursed ||= item2.cursed
      item1.inspected = true
      [transmute(item1)]
    end
  end

  # 杖合成。
  # (Item, Item) → [Item]
  def synthesize_staff(item1, item2)
    # XXX: unimplemented
    [item1, item2]
  end

  # 異種合成可能な組み合わせか？
  # (Item, Item) → true|false
  def heterosynthesizable?(item1, item2)
    # 剣に消印、盾にち印は入らない。
    if item1.type == :weapon &&
       item1.seals.size < item1.nslots &&
       item2.type != :weapon &&
       item2.type != :shield &&
       item2.own_seal &&
       item2.own_seal != "消"
      return true
    elsif item1.type == :shield &&
          item1.seals.size < item1.nslots &&
          item2.type != :weapon &&
          item2.type != :shield &&
          item2.own_seal &&
          item2.own_seal != "ち"
      return true
    else
      return false
    end
  end

  # 異種合成を行う。
  # (Item, Item) → [Item]
  def heterosynthesize(item1, item2)
    fail unless heterosynthesizable?(item1, item2)
    item1.seals.push(item2.own_seal)
    [transmute(item1)]
  end

  # 2つのアイテムの合成。allow_hetero 真偽値オプションで異種合成を許可。
  # (Item, Item) -> [Item]
  def synthesize(item1, item2, opts = {})
    allow_hetero = opts[:allow_hetero] || false

    if item1.type != item2.type
      if allow_hetero
        if heterosynthesizable?(item1, item2)
          heterosynthesize(item1, item2)
        else
          [item1, item2]
        end
      else
        [item1, item2] # 合成されない。
      end
    elsif item1.type == :weapon
      synthesize_weapon_or_shield(item1, item2)
    elsif item1.type == :shield
      synthesize_weapon_or_shield(item1, item2)
    elsif item1.type == :staff
      synthesize_staff(item1, item2)
    else
      [item1, item2]
    end
  end

  # 合成モンスターの持ち物にアイテムを追加。
  # ([Item], Item) → [Item]
  def heterosynthesis_add(contents, item)
    if contents.empty?
      [item]
    else
      contents[0...-1] + synthesize(contents[-1], item, allow_hetero: true)
    end
  end

  # 合成壺にアイテムを追加。
  # ([Item], Item) → [Item]
  def homosynthesis_add(contents, new_item)
    new_contents = []
    success = false
    contents.each do |item|
      if success
        new_contents.push(item)
      else
        result = synthesize(item, new_item, allow_hetero: false)
        if result.size == 2
          new_contents.push(item)
        elsif result.size == 1
          new_contents.push(result[0])
          success = true
        else fail
        end
      end
    end
    if success
      return new_contents
    else
      return new_contents + [new_item]
    end
  end

end
