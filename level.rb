require_relative 'monster'
require_relative 'hero'
require_relative 'item'
require_relative 'trap'
require_relative 'vec'
require_relative 'charlevel'

class Cell
  attr_accessor :lit, :explored, :type, :objects
  attr_accessor :unbreakable
  attr_accessor :wet

  def initialize type
    @type = type
    @lit = false
    @explored = false
    @objects = [].freeze
    @unbreakable = false
    @wet = false
  end

  def first_visible_object(globally_lit, visible_p)
    return @objects.find { |obj|
      visible_p.(obj,
                 @lit,
                 globally_lit,
                 @explored)
    }
  end

  def background_char(hero_sees_everything, tileset, wall_map)
    lit = @lit || hero_sees_everything
    case @type
    when :STATUE
      if lit
        '􄄤􄄥' # モアイ像
      elsif @explored
        '􄀾􄀿' # 薄闇
      else
        '　'
      end
    when :WALL
      if lit || @explored
        if (!wall_map[2] || !wall_map[6]) && (!wall_map[0] || !wall_map[4])
          tileset[:WALL]
        elsif !wall_map[2] || !wall_map[6]
          tileset[:VERTICAL_WALL]
        elsif !wall_map[0] || !wall_map[4]
          tileset[:HORIZONTAL_WALL]
        elsif wall_map.all?
          tileset[:NOPPERI_WALL]
        else
          tileset[:WALL]
        end
      else
        '　'
      end
    when :FLOOR
      if lit
        if @wet
          "\u{10433e}\u{10433f}"
        else
          '􄀪􄀫' # 部屋の床
        end
      elsif @explored
        '􄀾􄀿' # 薄闇
      else
        '　'
      end
    when :PASSAGE
      if lit
        if @wet
          "\u{10433e}\u{10433f}"
        else
          '􄀤􄀥' # 通路
        end
      elsif @explored
        '􄀾􄀿' # 薄闇
      else
        '　'
      end
    when :WATER
      if lit || @explored
        "\u{10433c}\u{10433d}"
      else
        '　'
      end
    else '？'
    end
  end

  def wall?
    case @type
    when :WALL
      true
    else
      false
    end
  end

  def solid?
    @type==:STATUE || wall?
  end

  def score(object)
    case object
    when Monster, Hero
      10
    when Item, StairCase, Trap
      20
    else
      fail object.class.to_s
    end
  end

  def put_object(object)
    @objects = (@objects + [object]).sort_by { |x| score(x) }.freeze
  end

  def remove_object(object)
    @objects = (@objects - [object]).freeze
  end

  def can_place?
    return (@type == :FLOOR || @type == :PASSAGE || @type == :WATER) && @objects.none? { |x|
      case x
      when StairCase, Trap, Item
        true
      else
        false
      end
    }
  end

  def trap
    @objects.find { |x| x.is_a? Trap }
  end

  def monster
    @objects.find { |x| x.is_a? Monster }
  end

  def character
    @objects.find { |x| x.is_a? Character }
  end

  def item
    @objects.find { |x| x.is_a? Item }
  end

  def staircase
    @objects.find { |x| x.is_a? StairCase }
  end

end

class StairCase
  attr_accessor :upwards

  def initialize(upwards = false)
    @upwards = upwards
  end

  def char
    if upwards
      '􄄸􄄹'
    else
      '􄀨􄀩'
    end
  end

  def name
    "階段"
  end
end

class Rect
  attr_accessor :top, :bottom, :left, :right
  include Enumerable

  def initialize(top, bottom, left, right)
    @top = top
    @bottom = bottom
    @left = left
    @right = right
  end

  def each_coords
    (top .. bottom).each do |y|
      (left .. right).each do |x|
        yield(x, y)
      end
    end
  end

  alias each each_coords

  def include?(x, y)
    (left .. right).include?(x) && (top .. bottom).include?(y)
  end
end

module DungeonGeneration
  module_function

  def generate(tileset, type)
    level = Level.new(tileset)

    case type
    when :bigmaze # 大迷路
      level.rooms = []
      make_maze(level, Room.new(1, 21, 25, 54))
    when :grid9 # 9分割
      # 0 1 2
      # 3 4 5
      # 6 7 8
      level.rooms = []
      level.rooms << Room.new(0, 7, 0, 24)
      level.rooms << Room.new(0, 7, 26, 51)
      level.rooms << Room.new(0, 7, 53, 79)
      level.rooms << Room.new(9, 15, 0, 24)
      level.rooms << Room.new(9, 15, 26, 51)
      level.rooms << Room.new(9, 15, 53, 79)
      level.rooms << Room.new(17, 23, 0, 24)
      level.rooms << Room.new(17, 23, 26, 51)
      level.rooms << Room.new(17, 23, 53, 79)

      level.connections = []

      level.add_connection(level.rooms[0], level.rooms[1], :horizontal)
      level.add_connection(level.rooms[0], level.rooms[3], :vertical)
      level.add_connection(level.rooms[1], level.rooms[2], :horizontal)
      level.add_connection(level.rooms[1], level.rooms[4], :vertical)
      level.add_connection(level.rooms[2], level.rooms[5], :vertical)
      level.add_connection(level.rooms[3], level.rooms[4], :horizontal)
      level.add_connection(level.rooms[3], level.rooms[6], :vertical)
      level.add_connection(level.rooms[4], level.rooms[5], :horizontal)
      level.add_connection(level.rooms[4], level.rooms[7], :vertical)
      level.add_connection(level.rooms[5], level.rooms[8], :vertical)
      level.add_connection(level.rooms[6], level.rooms[7], :horizontal)
      level.add_connection(level.rooms[7], level.rooms[8], :horizontal)

      until level.all_rooms_connected?
        conn = level.connections.sample
        conn.realized = true
      end

      level.rooms.each do |room|
        room.distort!
      end

      level.rooms.each do |room|
        level.render_room(room)
      end
      level.connections.each do |conn|
        if conn.realized
          conn.draw(level.dungeon)
        end
      end
    when :grid2 # 2分割。MH用
      # 0 1
      level.rooms = []
      level.rooms << Room.new(1, 22, 20, 38)
      level.rooms << Room.new(1, 22, 40, 58)

      level.connections = []

      level.add_connection(level.rooms[0], level.rooms[1], :horizontal)

      level.connections[0].realized = true

      level.rooms.each do |room|
        room.distort!(min_width: 15, min_height: 18)
      end

      level.rooms.each do |room|
        level.render_room(room)
      end
      level.connections[0].draw(level.dungeon)
    when :dumbbell # 眼鏡マップ
      # 0 1
      w = (7..23).select(&:odd?).sample
      v = (7..[(80 - w - 1), 23].min).select(&:odd?).sample
      m = [80 - w - v, 15].min


      level.rooms = []
      level.rooms << Room.new(12 - w/2, 12 + (w/2.0).ceil - 1,
                              0, w - 1)
      level.rooms << Room.new(12 - v/2, 12 + (v/2.0).ceil - 1,
                              w + m, w + m + v - 1)

      level.connections = []

      level.render_circular_room(level.rooms[0], w/2.0 - 1)
      level.render_circular_room(level.rooms[1], v/2.0 - 1)

      my = (level.rooms[0].top+level.rooms[0].bottom)/2
      (level.rooms[0].right .. level.rooms[1].left).each do |x|
        level.dungeon[my][x].type = :PASSAGE
      end
    when :grid4 # アルティメット4分割
      # 0 1
      # 2 3
      level.rooms = []
      level.rooms << Room.new(0, 10, 0, 38)
      level.rooms << Room.new(0, 10, 40, 78)
      level.rooms << Room.new(12, 22, 0, 38)
      level.rooms << Room.new(12, 22, 40, 78)

      level.connections = []

      level.add_connection(level.rooms[0], level.rooms[1], :horizontal)
      level.add_connection(level.rooms[2], level.rooms[3], :horizontal)
      level.add_connection(level.rooms[0], level.rooms[2], :vertical)
      level.add_connection(level.rooms[1], level.rooms[3], :vertical)

      level.connections.each do |conn|
        conn.realized = true
      end

      level.rooms.each do |room|
        room.distort!(min_width: 30, min_height: 8)
      end

      level.rooms.each do |room|
        level.render_room(room)
      end

      level.connections.each do |conn|
        conn.draw(level.dungeon)
      end
    when :grid10 # まんなかで通路が交差している10分割
      # 0 1 2 3
      # 4     5
      # 6 7 8 9
      level.rooms = []
      level.rooms << Room.new(0, 6, 0, 18)
      level.rooms << Room.new(0, 6, 20, 38)
      level.rooms << Room.new(0, 6, 40, 58)
      level.rooms << Room.new(0, 6, 60, 78)
      level.rooms << Room.new(8, 14, 0, 18)
      level.rooms << Room.new(8, 14, 60, 78)
      level.rooms << Room.new(16, 22, 0, 18)
      level.rooms << Room.new(16, 22, 20, 38)
      level.rooms << Room.new(16, 22, 40, 58)
      level.rooms << Room.new(16, 22, 60, 78)

      level.connections = []

      level.add_connection(level.rooms[1], level.rooms[7], :vertical)
      level.add_connection(level.rooms[2], level.rooms[8], :vertical)
      level.add_connection(level.rooms[4], level.rooms[5], :horizontal)
      level.connections.each do |conn|
        conn.realized = true
      end

      level.add_connection(level.rooms[0], level.rooms[1], :horizontal)
      level.add_connection(level.rooms[1], level.rooms[2], :horizontal)
      level.add_connection(level.rooms[2], level.rooms[3], :horizontal)

      level.add_connection(level.rooms[6], level.rooms[7], :horizontal)
      level.add_connection(level.rooms[7], level.rooms[8], :horizontal)
      level.add_connection(level.rooms[8], level.rooms[9], :horizontal)

      level.add_connection(level.rooms[0], level.rooms[4], :vertical)
      level.add_connection(level.rooms[4], level.rooms[6], :vertical)

      level.add_connection(level.rooms[3], level.rooms[5], :vertical)
      level.add_connection(level.rooms[5], level.rooms[9], :vertical)


      until level.all_rooms_connected?
        conn = level.connections.sample
        conn.realized = true
      end

      level.rooms.each do |room|
        room.distort!(min_width: 5, min_height: 5)
      end

      level.rooms.each do |room|
        level.render_room(room)
      end

      level.connections.each do |conn|
        if conn.realized
          conn.draw(level.dungeon)
        end
      end
    else
      fail "unknown type #{type}"
    end

    harden_perimeter(level)

    return level
  end

  # 部屋の内部を迷路にする。
  def make_maze(level, room)
    ((room.top) .. (room.bottom)).each do |y|
      ((room.left) .. (room.right)).each do |x|
        case level.dungeon[y][x].type
        when :PASSAGE
        else
          level.dungeon[y][x].type = :WALL
        end
      end
    end

    visited = {}

    f = proc do |x, y|
      level.dungeon[y][x].type = :FLOOR
      visited[[x,y]] = true
      [[-2,0], [0,-2], [+2,0], [0,+2]].shuffle.each do |dx, dy|
        unless !room.properly_in?(x+dx, y+dy) || visited[[x+dx,y+dy]]
          level.dungeon[y+dy/2][x+dx/2].type = :FLOOR
          f.(x+dx, y+dy)
        end
      end
    end

    f.(room.left + 1, room.top + 1)
  end

  # マップの外周を壊れない壁にする。
  def harden_perimeter(level)
    (0...level.dungeon.size).each do |y|
      (0...level.dungeon[0].size).each do |x|
        if (x == 0 || x == level.dungeon[0].size-1) ||
           (y == 0 || y == level.dungeon.size-1)
          level.dungeon[y][x].unbreakable = true
        end
      end
    end
  end

end

class Level
  attr_accessor :stairs_going_up
  attr_accessor :whole_level_lit
  attr_accessor :turn
  attr_accessor :party_room
  attr_accessor :rooms
  attr_accessor :tileset
  attr_accessor :connections
  attr_reader   :dungeon

  def initialize(tileset)
    @dungeon = Array.new(24) { Array.new(80) { Cell.new(:WALL) } }

    @stairs_going_up = false
    @whole_level_lit = false
    @turn = 0

    @tileset = tileset
  end

  def replace_floor_to_passage(room)
    ((room.top) .. (room.bottom)).each do |y|
      ((room.left) .. (room.right)).each do |x|
        case @dungeon[y][x].type
        when :FLOOR
          @dungeon[y][x].type = :PASSAGE
        end
      end
    end
  end

  def first_visible_object(x, y, visible_p)
    @dungeon[y][x].first_visible_object(@whole_level_lit, visible_p)
  end

  def background_char(x, y)
    wall_map = [[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1]].map do |dx,dy|
      if in_dungeon?(x+dx, y+dy)
        @dungeon[y+dy][x+dx].wall?
      else
        true
      end
    end
    @dungeon[y][x].background_char(@whole_level_lit, @tileset, wall_map)
  end

  def width
    @dungeon[0].size
  end

  def height
    @dungeon.size
  end

  def get_random_place(kind)
    candidates = (0 ... height).flat_map do |y|
      (0 ... width).flat_map do |x|
        @dungeon[y][x].type == kind ? [[x, y]] : []
      end
    end
    candidates.sample
  end

  # pred: Proc(cell, x, y)
  def find_random_place(&pred)
    candidates = []
    (0 ... height).each do |y|
      (0 ... width).each do |x|
        if pred.call(@dungeon[y][x], x, y)
          candidates << [x, y]
        end
      end
    end
    return candidates.sample
  end

  def all_cells_and_positions
    res = []
    (0 ... height).each do |y|
      (0 ... width).each do |x|
        res << [@dungeon[y][x], x, y]
      end
    end
    return res
  end

  def each_coords
    (0 ... height).each do |y|
      (0 ... width).each do |x|
        yield(x, y)
      end
    end
  end

  # add potential connection between rooms
  def add_connection(room1, room2, direction)
    conn = Connection.new(room1, room2, direction)
    @connections << conn
  end

  def connected_rooms(room)
    @connections.each_with_object([]) do |conn, res|
      next unless conn.realized
      if conn.room1 == room || conn.room2 == room
        res << conn.other_room(room)
      end
    end
  end

  def all_rooms_connected?
    all_connected?(@rooms)
  end

  def all_connected?(rooms)
    visited = []

    visit = -> (r) {
      return if visited.include?(r)
      visited << r
      connected_rooms(r).each do |other|
        visit.(other)
      end
    }

    visit.(rooms[0])
    return visited.size == rooms.size
  end

  def render_room(room)
    (room.top .. room.bottom).each do |y|
      (room.left .. room.right).each do |x|
        if y == room.top || y == room.bottom
          @dungeon[y][x] = Cell.new(:WALL)
        elsif x == room.left || x == room.right
          @dungeon[y][x] = Cell.new(:WALL)
        else
          @dungeon[y][x] = Cell.new(:FLOOR)
        end
      end
    end
  end

  def render_circular_room(room, radius)
    my = (room.top + room.bottom)/2.0
    mx = (room.left + room.right)/2.0

    (room.top .. room.bottom).each do |y|
      (room.left .. room.right).each do |x|
        if Math.sqrt((mx-x)**2 + (my-y)**2) < radius
          @dungeon[y][x] = Cell.new(:FLOOR)
        end
      end
    end
  end

  def passable?(x, y)
    unless x.between?(0, width - 1) && y.between?(0, height - 1)
      # 画面外
      return false
    end

    return (@dungeon[y][x].type == :FLOOR || @dungeon[y][x].type == :PASSAGE)
  end

  # ナナメ移動を阻害しないタイル。
  def uncornered?(x, y)
    unless x.between?(0, width - 1) && y.between?(0, height - 1)
      # 画面外
      return false
    end

    return (@dungeon[y][x].type == :FLOOR ||
            @dungeon[y][x].type == :PASSAGE ||
            @dungeon[y][x].type == :STATUE ||
            @dungeon[y][x].type == :WATER)
  end

  def room_at(x, y)
    @rooms.each do |room|
      if room.properly_in?(x, y)
        return room
      end
    end
    return nil
  end

  def room_exits(room)
    res = []
    rect = Rect.new(room.top, room.bottom, room.left, room.right)
    rect.each_coords do |x, y|
      if @dungeon[y][x].type == :PASSAGE
        res << [x, y]
      end
    end
    return res
  end

  def in_dungeon?(x, y)
    return x.between?(0, width-1) && y.between?(0, height-1)
  end

  # (x, y) と周辺の8マスを探索済みとしてマークする
  def mark_explored(x, y)
    offsets = [[0,0],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1]]

    offsets.each do |dx, dy|
      if in_dungeon?(x+dx, y+dy)
        @dungeon[y+dy][x+dx].explored = true
      end
    end
  end

  # (x, y)地点での視野 Rect を返す。
  def fov(x, y)
    r = room_at(x, y)
    if r
      return Rect.new(r.top, r.bottom, r.left, r.right)
    else
      return surroundings(x, y)
    end
  end

  def surroundings(x, y)
    top = [0, y-1].max
    bottom = [height-1, y+1].min
    left = [0, x-1].max
    right = [width-1, x+1].min
    return Rect.new(top, bottom, left, right)
  end

  def light_up(fov)
    fov.each_coords do |x, y|
      @dungeon[y][x].lit = true
    end
  end

  def mark_explored(fov)
    fov.each_coords do |x, y|
      @dungeon[y][x].explored = true
    end
  end

  def cell(x, y)
    fail TypeError unless x.is_a?(Integer) && y.is_a?(Integer)
    fail RangeError unless in_dungeon?(x, y)
    @dungeon[y][x]
  end

  def put_object(object, x, y)
    fail TypeError unless x.is_a?(Integer) && y.is_a?(Integer)
    fail RangeError unless in_dungeon?(x, y)
    @dungeon[y][x].put_object(object)
  end

  def remove_object(object, x, y)
    @dungeon[y][x].remove_object(object)
  end

  def move_object(object, x, y)
    ox, oy = pos_of(object)
    @dungeon[oy][ox].remove_object(object)
    @dungeon[y][x].put_object(object)
  end

  def stairs_going_up=(bool)
    (0 ... height).each do |y|
      (0 ... width).each do |x|
        st = @dungeon[y][x].objects.find { |obj| obj.is_a?(StairCase) }
        if st
          st.upwards = bool
          return
        end
      end
    end
    fail "no stairs!"
  end

  def has_type_at?(type, x, y)
    @dungeon[y][x].objects.any? { |x| x.is_a?(type) }
  end

  def all_monsters_with_position
    (0 ... height).flat_map do |y|
      (0 ... width).flat_map do |x|
        @dungeon[y][x].objects.select { |obj| obj.is_a?(Monster) }.map { |m| [m, x, y] }
      end
    end
  end

  def all_traps_with_position
    (0 ... height).flat_map do |y|
      (0 ... width).flat_map do |x|
        @dungeon[y][x].objects.select { |obj| obj.is_a?(Trap) }.map { |t| [t, x, y] }
      end
    end
  end

  def monster_count
    all_monsters_with_position.size
  end

  def can_move_to?(m, mx, my, tx, ty)
    return !@dungeon[ty][tx].character &&
      Vec.chess_distance([mx, my], [tx, ty]) == 1 &&
      passable?(tx, ty) &&
      uncornered?(tx, my) &&
      uncornered?(mx, ty)
  end

  def can_move_to_terrain?(m, mx, my, tx, ty)
    return Vec.chess_distance([mx, my], [tx, ty]) == 1 &&
           passable?(tx, ty) &&
           uncornered?(tx, my) &&
           uncornered?(mx, ty)
  end

  def can_attack?(m, mx, my, tx, ty)
    # m の特性によって場合分けすることもできる。

    return Vec.chess_distance([mx, my], [tx, ty]) == 1 &&
           (passable?(tx, ty) || cell(tx, ty).type == :WATER) &&
           uncornered?(tx, my) &&
           uncornered?(mx, ty)
  end

  def get_random_character_placeable_place
    loop do
      x, y = get_random_place(:FLOOR)
      unless has_type_at?(Monster, x, y)
        return x, y
      end
    end
  end

  def coordinates_of_cell(cell)
    fail TypeError unless cell.is_a? Cell

    (0 ... height).each do |y|
      (0 ... width).each do |x|
        if @dungeon[y][x].equal?(cell)
          return [x, y]
        end
      end
    end
    return nil
  end

  def pos_of(obj)
    (0 ... height).each do |y|
      (0 ... width).each do |x|
        if @dungeon[y][x].objects.any? { |z| z.equal?(obj) }
          return [x, y]
        end
      end
    end
    return nil
  end

  def darken
    (0 ... height).each do |y|
      (0 ... width).each do |x|
        @dungeon[y][x].lit = false
      end
    end
  end

  def update_lighting(x, y)
    darken
    rect = fov(x, y)
    mark_explored(rect)
    light_up(rect)
  end

  def first_cells_in(room)
    res = []
    (room.left+1 .. room.right-1).each do |x|
      if cell(x, room.top).type == :PASSAGE
        res << [x, room.top+1]
      end

      if cell(x, room.bottom).type == :PASSAGE
        res << [x, room.bottom-1]
      end
    end

    (room.top+1 .. room.bottom-1).each do |y|
      if cell(room.left, y).type == :PASSAGE
        res << [room.left+1, y]
      end

      if cell(room.right, y).type == :PASSAGE
        res << [room.right-1, y]
      end
    end

    return res
  end
end
