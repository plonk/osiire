# aka LevelGenerator
class Dungeon
  # [[Integer, [String,Integer], [String,Integer]...]...]
  MONSTER_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'monster_table.rb')))
  # [[Integer, [String,Integer], [String,Integer]...]...]
  ITEM_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'item_table.rb')))

  OBJECTIVE_NAME = "イェンダーの魔除け"

  # 階段を置く。
  def place_stair_case(level)
    level.put_object(StairCase.new, *level.get_random_place(:FLOOR))
  end

  def make_item(level_number)
    distribution = ITEM_TABLE.assoc(level_number)[1..-1] # 1Fに落ちるアイテムの分布
    name = select(distribution)
    return Item.make_item(name)
  end

  def make_random_item_or_gold(level_number)
    if rand < 0.1
      # アイテムではなく金を置く。
      Gold.new(rand(100..1000))
    else
      make_item(level_number)
    end
  end

  def place_items(level, level_number)
    nitems = rand(3..5)
    nitems.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.can_place?
        thing = make_random_item_or_gold(level_number)
        cell.put_object(thing)
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

  def make_monster(level_number)
    distribution = MONSTER_TABLE.assoc(level_number)[1..-1]
    selected_monster = select(distribution)
    return Monster.make_monster(selected_monster)
  end

  # rect: 避けるべきヒーローの視界。
  def place_monster(level, level_number, rect)
    while true
      x, y = level.get_random_place(:FLOOR)
      cell = level.cell(x, y)
      if !rect.include?(x, y) && !cell.monster
        m = make_monster(level_number)
        spawn_monster(m, cell)
        break
      end
    end
  end

  def spawn_monster(m, cell)
    cell.put_object(m)
  end

  # モンスターを配置する。
  def place_monsters(level, level_number)
    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.objects.none? { |obj| obj.is_a? Monster }
        m = make_monster(level_number)
        spawn_monster(m, cell)
      end
    end
  end

  def surrounded_by_empty_floor_tiles?(level, x, y)
    level.surroundings(x, y).each_coords do |xx, yy|
      c = level.cell(xx, yy)
      unless c.type == :FLOOR && c.objects.none?
        return false
      end
    end
    return true
  end

  def place_statues(level, level_number)
    num = rand(3..3)

    until num == 0
      x, y = level.get_random_place(:FLOOR)
      if surrounded_by_empty_floor_tiles?(level, x, y)
        level.cell(x, y).type = :STATUE
        num -= 1
      end
    end
  end

  def place_objective(level)
    loop do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.can_place?
        cell.put_object(Item.make_item(OBJECTIVE_NAME))
        return
      end
    end
  end

  def place_traps(level, level_number)
    # 30 では多い。
    10.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.can_place?
        cell.put_object(Trap.new(Trap::TRAPS.sample, false))
      end
    end
  end

  def place_traps_in_room(level, level_number, room)
    ((room.top+1)..(room.bottom-1)).each do |y|
      ((room.left+1)..(room.right-1)).each do |x|
        if rand() < 0.5
          if level.cell(x, y).can_place?
            level.cell(x, y).put_object(Trap.new(Trap::TRAPS.sample, false))
          end
        end
      end
    end
  end

  def place_items_in_room(level, level_number, room, nitems)
    points = ((room.top+1)..(room.bottom-1)).flat_map { |y|
      ((room.left+1)..(room.right-1)).map { |x|
        [x, y]
      }
    }
    points.sample(nitems).each do |x, y|
      if level.cell(x, y).can_place?
        level.cell(x, y).put_object(make_item(level_number))
      end
    end
  end

  def place_monsters_in_room(level, level_number, room, nmonsters)
    points = ((room.top+1)..(room.bottom-1)).flat_map { |y|
      ((room.left+1)..(room.right-1)).map { |x|
        [x, y]
      }
    }
    points.sample(nmonsters).each do |x, y|
      unless level.cell(x, y).monster
        m = make_monster(level_number)
        m.state = :asleep
        level.cell(x, y).put_object(m)
      end
    end
  end

  def make_level(level_number, hero)
    fail unless level_number.is_a? Integer and level_number >= 1

    level = Level.new

    place_statues(level, level_number)

    place_stair_case(level)
    unless on_return_trip?(hero)
      place_items(level, level_number)
    end
    place_traps(level, level_number)
    place_monsters(level, level_number)
    if level_number >= 27 && !on_return_trip?(hero)
      place_objective(level)
    end

    if rand() < 0.3
      r = level.rooms.sample
      level.party_room = r

      place_traps_in_room(level, level_number, r)
      unless on_return_trip?(hero)
        place_items_in_room(level, level_number, r, 10)
      end
      place_monsters_in_room(level, level_number, r, 10)
    end

    return level
  end

  def on_return_trip?(hero)
    hero.inventory.any? { |item|
      item.type == :box && item.name != "鉄の金庫"
    }
  end

end
