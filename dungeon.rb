# aka LevelGenerator
class Dungeon
  # [[Integer, [String,Integer], [String,Integer]...]...]
  MONSTER_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'monster_table.rb')))
  # [[Integer, [String,Integer], [String,Integer]...]...]
  ITEM_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'item_table.rb')))

  # 階段を置く。
  def place_stair_case(level)
    level.put_object(*level.get_random_place(:FLOOR), StairCase.new)
  end

  def make_item(distribution)
    name = select(distribution)
    return Item.make_item(name)
  end

  def place_items(level, level_number)
    item_distribution = ITEM_TABLE.assoc(level_number)[1..-1] # 1Fに落ちるアイテムの分布
    nitems = rand(3..5)
    nitems.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.empty?
        if rand < 0.1
          # アイテムではなく金を置く。
          cell.put_object(Gold.new(rand(100..1000)))
        else
          cell.put_object(make_item(item_distribution))
        end
      end
    end
  end

  def select(distribution)
    denominator = distribution.map(&:last).inject(:+)
    r = rand(denominator)
    selected_monster = distribution.each do |name, prob|
      if r < prob
        return name
      end
      r -= prob
    end
    fail 'バグバグりん'
  end

  def make_monster(distribution)
    selected_monster = select(distribution)
    return Monster.make_monster(selected_monster)
  end

  # モンスターを配置する。
  def place_monsters(level, level_number)
    monster_distribution = MONSTER_TABLE.assoc(level_number)[1..-1]

    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.none? { |obj| obj.is_a? Monster }
        cell.put_object(make_monster(monster_distribution))
      end
    end
  end

  def make_level(level_number, hero)
    fail unless level_number.is_a? Integer and level_number >= 1

    level = Level.new

    place_stair_case(level)
    place_items(level, level_number)
    place_monsters(level, level_number)

    return level
  end
end
