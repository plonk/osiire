# aka LevelGenerator
class Dungeon
  def make_level(level_number, hero)
    fail unless level_number.is_a? Integer and level_number >= 1
    level = Level.new

    # 階段を置く。
    level.put_object(*level.get_random_place(:FLOOR), StairCase.new)

    # 金を置く。
    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.empty?
        cell.objects << Gold.new(rand(100..1000))
      end
    end

    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.empty?
        cell.objects << Item.make_item("ナン")
      end
    end

    # モンスターを配置する。
    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.none? { |obj| obj.is_a? Monster }
        cell.objects << Monster.make_monster('まんまる')
      end
    end

    return level
  end
end
