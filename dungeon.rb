# aka LevelGenerator
class Dungeon
  # [[Integer, [String,Integer], [String,Integer]...]...]
  MONSTER_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'monster_table.rb')))
  # [[Integer, [String,Integer], [String,Integer]...]...]
  ITEM_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'item_table.rb')))

  OBJECTIVE_NAME = "イェンダーの魔除け"

  # 階段を置く。
  def place_staircase(level)
    x, y = level.get_random_place(:FLOOR)
    if x
      level.put_object(StairCase.new, x, y)
    else
      x, y = level.get_random_place(:PASSAGE)
      fail unless x
      level.put_object(StairCase.new, x, y)
    end
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

  def make_monster_from_dungeon
    species = MONSTER_TABLE.flat_map { |row| row.drop(1) }.map(&:first).uniq

    selected_monster = species.sample
    m = Monster.make_monster(selected_monster)
    # 化け狸、ミミックはそのまま出現。
    case m.name
    when "どろぼう猫"
      m.item = make_item(1) # 1Fのアイテムテーブルから持たせる。
    end
    return m
  end

  def make_monster(level_number)
    distribution = MONSTER_TABLE.assoc(level_number)[1..-1]
    selected_monster = select(distribution)
    if selected_monster == "ミミック"
      m = make_item(level_number)
      m.mimic = true
    else
      m = Monster.make_monster(selected_monster)
      case m.name
      when "どろぼう猫"
        m.item = make_item(level_number)
      when "化け狸"
        while true
          n = select(distribution)
          break unless n == "化け狸"
        end
        impersonated = Monster.make_monster(n)
        m.impersonating_name = impersonated.name
        m.impersonating_char = impersonated.char
      end
    end
    return m
  end

  # ターン経過でモンスターが湧く時。
  # rect: 避けるべきヒーローの視界。
  def place_monster(level, level_number, rect)
    list = level.all_cells_and_positions
    possibles = list.select { |cell, x, y|
      cell.type == :FLOOR && !cell.monster
    }
    if possibles.empty?
      fail "nowhere to put monster"
    end
    preferred = possibles.select { |cell, x, y| !rect.include?(x, y) }
    if preferred.empty?
      cell, = possibles.sample
    else
      cell, = preferred.sample
    end
    spawn_monster(make_monster(level_number), cell, level)
  end

  def spawn_other_three(m, cell, level)
    x, y = level.coordinates_of(m)
    offsets = [
      [[1,0],[0,1],[1,1]],     # 最初が左上
      [[1,0],[0,-1],[1,-1]],   # 最初が左下
      [[-1,0],[0,1],[-1,1]],   # 最初が右上
      [[-1,0],[0,-1],[-1,-1]], # 最初が右上
    ].sort_by { |offsets|
      offsets.count { |dx, dy|
        cell = level.cell(x+dx, y+dy)
        (cell.type == :FLOOR || cell.type == :PASSAGE) && cell.monster.nil?
      }
    }.reverse.first

    group = Array.new
    group << m
    offsets.each do |dx, dy|
      cell = level.cell(x+dx, y+dy)
      if (cell.type == :FLOOR || cell.type == :PASSAGE) && cell.monster.nil?
        friend = Monster.make_monster("四人トリオ")
        group << friend
        friend.group = group
        cell.put_object(friend)
      end
    end
    m.group = group
  end

  def spawn_monster(m, cell, level)
    if m.is_a?(Item) && cell.can_place? # ミミック
      cell.put_object(m)
      return true
    elsif m.is_a?(Monster) && !cell.monster
      cell.put_object(m)
      if cell.monster.name == "四人トリオ"
        spawn_other_three(m, cell, level)
      end
      return true
    else
      return false
    end
  end

  # モンスターを配置する。通常配置。
  def place_monsters(level, level_number)
    5.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      m = make_monster(level_number)
      spawn_monster(m, cell, level)
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
      if x.nil? # 部屋がない
        return
      end
      if surrounded_by_empty_floor_tiles?(level, x, y)
        level.cell(x, y).type = :STATUE
      end
      num -= 1
    end
  end

  def place_objective(level, level_number)
    loop do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.can_place?
        objective = Item.make_item(OBJECTIVE_NAME)
        objective.number = level_number
        cell.put_object(objective)
        return
      end
    end
  end

  def place_item(level, item)
    loop do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.can_place?
        cell.put_object(item)
        return
      end
    end
  end

  def place_traps(level, level_number)
    case level_number
    when 1..2
      n = 0
    when 3..10
      n = rand(1..3)
    when 11..20
      n = rand(3..5)
    when 21..30
      n = rand(5..7)
    else
      n = rand(7..9)
    end

    n.times do
      cell = level.cell(*level.get_random_place(:FLOOR))
      if cell.can_place?
        cell.put_object(Trap.new(Trap::TRAPS.sample, false))
      end
    end
  end

  def place_traps_in_room(level, level_number, room)
    cells = []
    ((room.top+1)..(room.bottom-1)).each do |y|
      ((room.left+1)..(room.right-1)).each do |x|
        c = level.cell(x, y)
        if c.can_place?
          cells << c
        end
      end
    end

    n = [(cells.size * 0.3).round, 50].min
    cells.sample(n).each do |cell|
      cell.put_object(Trap.new(Trap::TRAPS.sample, false))
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
      m = make_monster(level_number)
      case m
      when Monster
        unless level.cell(x, y).monster
          m.state = :asleep
          level.cell(x, y).put_object(m)
        end
      when Item
        if level.cell(x, y).can_place?
          level.cell(x, y).put_object(m)
        end
      end
    end
  end

  def tileset(level_number)
    case level_number
    when 1..2
      {
        :WALL            => '􄅦􄅧',
        :HORIZONTAL_WALL => '􄅠􄅡',
        :VERTICAL_WALL   => '􄅢􄅣',
      }
    when 3..4
      {
        :WALL            => '􄅘􄅙',
        :HORIZONTAL_WALL => '􄅔􄅕',
        :VERTICAL_WALL   => '􄅖􄅗',
      }
    when 5..6
      {
        :WALL            => '􄅞􄅟',
        :HORIZONTAL_WALL => '􄅚􄅛',
        :VERTICAL_WALL   => '􄅜􄅝',
      }
    when 7..9
      {
        :WALL            => '􄅰􄅱',
        :HORIZONTAL_WALL => '􄅬􄅭',
        :VERTICAL_WALL   => '􄅮􄅯',
      }
    when 10..12
      {
        :HORIZONTAL_WALL => "\u{104240}\u{104241}",
        :VERTICAL_WALL   => "\u{104242}\u{104243}",
        :WALL            => "\u{104244}\u{104245}",
      }
    when 13..15
      {
        :HORIZONTAL_WALL => '􄅲􄅳',
        :VERTICAL_WALL   => '􄅴􄅵',
        :WALL            => '􄅶􄅷',
      }
    when 16..18
      {
        :WALL            => '􄈪􄈫',
        :HORIZONTAL_WALL => '􄈦􄈧',
        :VERTICAL_WALL   => '􄈨􄈩',
      }
    when 19..21
      {
        :WALL            => '􄅌􄅍',
        :HORIZONTAL_WALL => '􄅈􄅉',
        :VERTICAL_WALL   => '􄅊􄅋',
      }
    when 25..26
      {
        :WALL            => '􄅒􄅓',
        :HORIZONTAL_WALL => '􄅐􄅑',
        :VERTICAL_WALL   => '􄅎􄅏',
      }
    when 22..24
      {
        :HORIZONTAL_WALL => '􄈠􄈡',
        :VERTICAL_WALL   => '􄈢􄈣',
        :WALL            => '􄈤􄈥',
      }
    when 27..99
      {
        :HORIZONTAL_WALL => '􄅸􄅹',
        :VERTICAL_WALL   => '􄅺􄅻',
        :WALL            => '􄅼􄅽',
      }
    else
      {
        :WALL            => '􄁀􄁁',
        :HORIZONTAL_WALL => '􄀢􄀣',
        :VERTICAL_WALL   => '􄀼􄀽',
      }
    end
  end

  def make_level(level_number, hero)
    fail unless level_number.is_a? Integer and level_number >= 1

    case level_number
    when 40
      type = :bigmaze
    when 50, 60, 70, 80, 90, 99
      type = :bigmaze
    else
      type = [*[:grid10, :grid9]*4, :grid4, :grid2].sample
    end

    case type
    when :grid10, :grid9
      party_room_prob = 0.15
    when :grid4, :grid2
      party_room_prob = 1.0
    else
      party_room_prob = 0.0
    end

    level = Level.new(tileset(level_number), type)

    mazes = []
    odd_rooms = level.rooms.select { |r|
      (r.right - r.left + 1).odd? && (r.top - r.bottom + 1).odd?
    }
    if odd_rooms.any?
      r = odd_rooms.sample
      level.make_maze(r)
      mazes << r
    end

    place_statues(level, level_number)

    place_staircase(level)
    unless on_return_trip?(hero)
      place_items(level, level_number)
    end
    place_traps(level, level_number)
    place_monsters(level, level_number)
    if level_number >= 27 && !on_return_trip?(hero)
      place_objective(level, level_number)
    end
    if level_number == 50 && !on_return_trip?(hero) && hero.inventory.none? { |item| item.name == "必中会心剣" }
      sword = Item.make_item("必中会心剣")
      sword.number = 20
      place_item(level, sword)
    end
    if level_number == 99 && !on_return_trip?(hero) && hero.inventory.none? { |item| item.name == "退魔の指輪" }
      ring = Item.make_item("退魔の指輪")
      place_item(level, ring)
    end

    mazes.each do |r|
      # level.replace_floor_to_passage(r)
      level.rooms.delete(r)
    end

    if level.rooms.any? && rand() < party_room_prob
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
