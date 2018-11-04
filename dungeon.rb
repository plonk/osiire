# aka LevelGenerator
class Dungeon
  # [[Integer, [String,Integer], [String,Integer]...]...]
  MONSTER_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'monster_table.rb')))
  # [[Integer, [String,Integer], [String,Integer]...]...]
  ITEM_TABLE = eval(IO.read(File.join(File.dirname(__FILE__), 'item_table.rb')))

  # ランキングなどに表示されるダンジョンの名前。
  def name
    "じゃんじょん"
  end

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
      # 1F 200 ゴールド程度、深層で 2000 ゴールド程度欲しい。
      amount = rand(0.875 .. 1.125) * (200 + 1800 * (level_number / 100.0))
      Gold.new([amount.to_i, 1].max)
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

  # [[項目,整数], ...] で定義される確率分布からランダムに項目を選択す
  # る。
  def select(distribution)
    fail TypeError, 'Array expected' unless distribution.is_a?(Array)
    fail 'empty distribution' if distribution.empty?

    denominator = distribution.map(&:last).inject(:+)
    r = rand(denominator)
    selected_monster = distribution.each do |name, prob|
      if r < prob
        return name
      end
      r -= prob
    end
    fail "バグバグりん #{distribution.inspect}"
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
    if selected_monster =~ /ミミック/
      m = make_item(level_number)
      m.mimic = true
      m.mimic_name = selected_monster
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

  def spawn_monster(m, cell, level)
    if m.is_a?(Item) && cell.can_place? # ミミック
      cell.put_object(m)
      return true
    elsif m.is_a?(Monster) && !cell.monster
      cell.put_object(m)
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
      n = rand(3..5)
    when 3..10
      n = rand(3..5)
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
        cell.put_object(Trap.new(Trap::TRAPS.keys.sample, false))
      end
    end
  end

  # 部屋のMH化。
  def make_party_room(level, level_number, room)
    nitems = 10
    nmonsters = 10

    place_traps_in_party_room(level, level_number, room)
    place_items_in_party_room(level, level_number, room, nitems)
    place_monsters_in_party_room(level, level_number, room, nmonsters)
  end

  # MH罠配置。
  def place_traps_in_party_room(level, level_number, room)
    cells = []
    ((room.top+1)..(room.bottom-1)).each do |y|
      ((room.left+1)..(room.right-1)).each do |x|
        c = level.cell(x, y)
        if c.can_place?
          cells << c
        end
      end
    end

    n = [(cells.size * 0.1).round, 50].min
    cells.sample(n).each do |cell|
      cell.put_object(Trap.new(Trap::TRAPS.keys.sample, false))
    end
  end

  # MHアイテム配置。
  def place_items_in_party_room(level, level_number, room, nitems)
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

  # MHモンスター配置。
  def place_monsters_in_party_room(level, level_number, room, nmonsters)
    points = ((room.top+1)..(room.bottom-1)).flat_map { |y|
      ((room.left+1)..(room.right-1)).map { |x|
        [x, y]
      }
    }.reject { |x, y|
      level.cell(x,y).type != :FLOOR
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

  TILESETS =
    [
      # ペイズリー
      {
        :WALL            => "\u{104164}\u{104165}",
        :HORIZONTAL_WALL => '􄅠􄅡',
        :VERTICAL_WALL   => '􄅢􄅣',
        :NOPPERI_WALL    => '􄅦􄅧',
      },
      # 石づくり
      {
        :WALL            => '􄅘􄅙',
        :HORIZONTAL_WALL => '􄅔􄅕',
        :VERTICAL_WALL   => '􄅖􄅗',
        :NOPPERI_WALL    => "\u{104460}\u{104461}",
      },
      # 木材
      {
        :WALL            => '􄅞􄅟',
        :HORIZONTAL_WALL => '􄅚􄅛',
        :VERTICAL_WALL   => '􄅜􄅝',
        :NOPPERI_WALL    => "\u{10446a}\u{10446b}",
      },
      # 土砂
      {
        :WALL            => "\u{10446c}\u{10446d}",
        :HORIZONTAL_WALL => '􄅬􄅭',
        :VERTICAL_WALL   => '􄅮􄅯',
        :NOPPERI_WALL    => '􄅰􄅱',
      },
      # 泥
      {
        :HORIZONTAL_WALL => "\u{104240}\u{104241}",
        :VERTICAL_WALL   => "\u{104242}\u{104243}",
        :WALL            => "\u{104244}\u{104245}",
        :NOPPERI_WALL    => "\u{10446e}\u{10446f}",
      },
      # モアイを作る黒い石
      {
        :HORIZONTAL_WALL => '􄅲􄅳',
        :VERTICAL_WALL   => '􄅴􄅵',
        :WALL            => '􄅶􄅷',
        :NOPPERI_WALL    => "\u{104470}\u{104471}",
      },
      # ラスコー洞窟
      {
        :WALL            => '􄈪􄈫',
        :HORIZONTAL_WALL => '􄈦􄈧',
        :VERTICAL_WALL   => '􄈨􄈩',
        :NOPPERI_WALL    => "\u{104468}\u{104469}",
      },
      # 氷
      {
        :WALL            => '􄅌􄅍',
        :HORIZONTAL_WALL => '􄅈􄅉',
        :VERTICAL_WALL   => '􄅊􄅋',
        :NOPPERI_WALL    => "\u{104474}\u{104475}",
      },
      # 溶岩
      {
        :WALL            => '􄅒􄅓',
        :HORIZONTAL_WALL => '􄅐􄅑',
        :VERTICAL_WALL   => '􄅎􄅏',
        :NOPPERI_WALL    => "\u{104464}\u{104465}",
      },
      # 化石
      {
        :HORIZONTAL_WALL => '􄈠􄈡',
        :VERTICAL_WALL   => '􄈢􄈣',
        :WALL            => '􄈤􄈥',
        :NOPPERI_WALL    => "\u{104466}\u{104467}",
      },
      # 水の湧き出る壁
      {
        :HORIZONTAL_WALL => '􄅸􄅹',
        :VERTICAL_WALL   => '􄅺􄅻',
        :WALL            => '􄅼􄅽',
        :NOPPERI_WALL    => "\u{104462}\u{104463}",
      },
      # レンガ
      {
        :WALL            => '􄁀􄁁',
        :HORIZONTAL_WALL => '􄀢􄀣',
        :VERTICAL_WALL   => '􄀼􄀽',
        :NOPPERI_WALL    => "\u{104472}\u{104473}",
      }
    ]

  def tileset(level_number)
    TILESETS[(level_number - 1) % TILESETS.size]
  end

  # 壁を水路に置き換える。
  def place_water(level, level_number)
    level.each_coords do |x, y|
      c = level.cell(x, y)
      if c.wall? && !c.unbreakable
        level.cell(x, y).type = :WATER
      end
    end
  end

  # 部屋の迷路化が起こり得るマップタイプか。
  def maze_possible?(type)
    case type
    when :dumbbell
      false
    else
      true
    end
  end

  # 指定のマップタイプでMHが配置される確率。
  def party_room_prob(type)
    case type
    when :grid10, :grid9, :dumbbell
      0.15
    when :grid4, :grid2
      1.0
    else
      0.0
    end
  end

  def make_level(level_number)
    fail unless level_number.is_a? Integer and level_number >= 1

    type = select [[:bigmaze, 1.0/9],
                   [:grid10, 4], [:grid9, 4],
                   [:grid4, 1], [:grid2, 1], [:dumbbell, 1]]

    level = DungeonGeneration.generate(tileset(level_number), type)

    mazes = []
    if maze_possible?(type)
      odd_rooms = level.rooms.select { |r|
        (r.right - r.left + 1).odd? && (r.top - r.bottom + 1).odd?
      }
      if odd_rooms.any?
        r = odd_rooms.sample
        DungeonGeneration.make_maze(level, r)
        mazes << r
      end
    end

    #place_water(level, level_number)

    place_staircase(level)
    place_items(level, level_number)
    place_traps(level, level_number)
    place_monsters(level, level_number)

    mazes.each do |r|
      level.rooms.delete(r)
    end

    if level.rooms.any? && rand() < party_room_prob(type)
      room = level.rooms.sample
      level.party_room = room

      make_party_room(level, level_number, room)
    end

    return level
  end

end
