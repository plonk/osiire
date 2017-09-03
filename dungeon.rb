# aka LevelGenerator
class Dungeon
  # [[Integer, [String,Integer], [String,Integer]...]...]
  MONSTER_TABLE = eval(File.read(File.join(File.dirname(__FILE__), 'monster_table.rb')))

  # 金を置く。
  def place_gold(level)
    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.empty?
        cell.objects << Gold.new(rand(100..1000))
      end
    end
  end

  # 階段を置く。
  def place_stair_case(level)
    level.put_object(*level.get_random_place(:FLOOR), StairCase.new)
  end

  # ナンを置く
  def place_food(level)
    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.empty?
        cell.objects << Item.make_item("ナン")
      end
    end
  end

  # モンスターを配置する。
  def place_monsters(level)
    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.none? { |obj| obj.is_a? Monster }
        cell.objects << Monster.make_monster('スライム')
      end
    end
  end

  def make_level(level_number, hero)
    fail unless level_number.is_a? Integer and level_number >= 1

    level = Level.new

    place_stair_case(level)
    place_gold(level)
    place_food(level)
    place_monsters(level)

    return level
  end
end
