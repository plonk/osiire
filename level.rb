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

  def background_char(hero_sees_everything, tileset)
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
        tileset[:WALL]
      else
        '　'
      end
    when :HORIZONTAL_WALL
      if lit || @explored
        tileset[:HORIZONTAL_WALL]
      else
        '　'
      end
    when :VERTICAL_WALL
      if lit || @explored
        tileset[:VERTICAL_WALL]
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
    when :WALL, :HORIZONTAL_WALL, :VERTICAL_WALL
      true
    else
      false
    end
  end

  def score(object)
    case object
    when Monster
      10
    when Gold, Item, StairCase, Trap
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
      when StairCase, Trap, Item, Gold
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

  def item
    @objects.find { |x| x.is_a? Item }
  end

  def gold
    @objects.find { |x| x.is_a? Gold }
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

class Level
  attr_reader :stairs_going_up
  attr_accessor :whole_level_lit
  attr_accessor :turn
  attr_accessor :party_room
  attr_reader :rooms
  attr :tileset

  def initialize(tileset, type = :grid2)
    @dungeon = Array.new(24) { Array.new(80) { Cell.new(:WALL) } }

    case type
    when :bigmaze
      @rooms = []
      make_maze(Room.new(0, 23, 20, 59))
    when :grid9
      # 0 1 2
      # 3 4 5
      # 6 7 8
      @rooms = []
      @rooms << Room.new(0, 7, 0, 24)
      @rooms << Room.new(0, 7, 26, 51)
      @rooms << Room.new(0, 7, 53, 79)
      @rooms << Room.new(9, 15, 0, 24)
      @rooms << Room.new(9, 15, 26, 51)
      @rooms << Room.new(9, 15, 53, 79)
      @rooms << Room.new(17, 23, 0, 24)
      @rooms << Room.new(17, 23, 26, 51)
      @rooms << Room.new(17, 23, 53, 79)

      @connections = []

      add_connection(@rooms[0], @rooms[1], :horizontal)
      add_connection(@rooms[0], @rooms[3], :vertical)
      add_connection(@rooms[1], @rooms[2], :horizontal)
      add_connection(@rooms[1], @rooms[4], :vertical)
      add_connection(@rooms[2], @rooms[5], :vertical)
      add_connection(@rooms[3], @rooms[4], :horizontal)
      add_connection(@rooms[3], @rooms[6], :vertical)
      add_connection(@rooms[4], @rooms[5], :horizontal)
      add_connection(@rooms[4], @rooms[7], :vertical)
      add_connection(@rooms[5], @rooms[8], :vertical)
      add_connection(@rooms[6], @rooms[7], :horizontal)
      add_connection(@rooms[7], @rooms[8], :horizontal)

      until all_connected?(@rooms)
        conn = @connections.sample
        conn.realized = true
      end

      @rooms.each do |room|
        room.distort!
      end

      @rooms.each do |room|
        render_room(@dungeon, room)
      end
      @connections.each do |conn|
        if conn.realized
          conn.draw(@dungeon)
        end
      end
    when :grid2
      # 0 1
      @rooms = []
      @rooms << Room.new(1, 22, 20, 38)
      @rooms << Room.new(1, 22, 40, 58)

      @connections = []

      add_connection(@rooms[0], @rooms[1], :horizontal)

      @connections[0].realized = true

      @rooms.each do |room|
        room.distort!(min_width: 15, min_height: 18)
      end

      @rooms.each do |room|
        render_room(@dungeon, room)
      end
      @connections[0].draw(@dungeon)
    when :grid4
      # 0 1
      # 2 3
      @rooms = []
      @rooms << Room.new(0, 10, 0, 38)
      @rooms << Room.new(0, 10, 40, 78)
      @rooms << Room.new(12, 22, 0, 38)
      @rooms << Room.new(12, 22, 40, 78)

      @connections = []

      add_connection(@rooms[0], @rooms[1], :horizontal)
      add_connection(@rooms[2], @rooms[3], :horizontal)
      add_connection(@rooms[0], @rooms[2], :vertical)
      add_connection(@rooms[1], @rooms[3], :vertical)

      @connections.each do |conn|
        conn.realized = true
      end

      @rooms.each do |room|
        room.distort!(min_width: 30, min_height: 8)
      end

      @rooms.each do |room|
        render_room(@dungeon, room)
      end

      @connections.each do |conn|
        conn.draw(@dungeon)
      end
    when :grid10
      # 0 1 2 3
      # 4     5
      # 6 7 8 9
      @rooms = []
      @rooms << Room.new(0, 6, 0, 18)
      @rooms << Room.new(0, 6, 20, 38)
      @rooms << Room.new(0, 6, 40, 58)
      @rooms << Room.new(0, 6, 60, 78)
      @rooms << Room.new(8, 14, 0, 18)
      @rooms << Room.new(8, 14, 60, 78)
      @rooms << Room.new(16, 22, 0, 18)
      @rooms << Room.new(16, 22, 20, 38)
      @rooms << Room.new(16, 22, 40, 58)
      @rooms << Room.new(16, 22, 60, 78)

      @connections = []

      add_connection(@rooms[1], @rooms[7], :vertical)
      add_connection(@rooms[2], @rooms[8], :vertical)
      add_connection(@rooms[4], @rooms[5], :horizontal)
      @connections.each do |conn|
        conn.realized = true
      end

      add_connection(@rooms[0], @rooms[1], :horizontal)
      add_connection(@rooms[1], @rooms[2], :horizontal)
      add_connection(@rooms[2], @rooms[3], :horizontal)

      add_connection(@rooms[6], @rooms[7], :horizontal)
      add_connection(@rooms[7], @rooms[8], :horizontal)
      add_connection(@rooms[8], @rooms[9], :horizontal)

      add_connection(@rooms[0], @rooms[4], :vertical)
      add_connection(@rooms[4], @rooms[6], :vertical)

      add_connection(@rooms[3], @rooms[5], :vertical)
      add_connection(@rooms[5], @rooms[9], :vertical)


      until all_connected?(@rooms)
        conn = @connections.sample
        conn.realized = true
      end

      @rooms.each do |room|
        room.distort!(min_width: 5, min_height: 5)
      end

      @rooms.each do |room|
        render_room(@dungeon, room)
      end

      @connections.each do |conn|
        if conn.realized
          conn.draw(@dungeon)
        end
      end
    else
      fail "unknown type #{type}"
    end

    @stairs_going_up = false
    @whole_level_lit = false
    @turn = 0

    @tileset = tileset

    harden_perimeter
  end

  def harden_perimeter
    (0...@dungeon.size).each do |y|
      (0...@dungeon[0].size).each do |x|
        if (x == 0 || x == @dungeon[0].size-1) ||
           (y == 0 || y == @dungeon.size-1)
          @dungeon[y][x].unbreakable = true
        end
      end
    end
  end

  def make_maze(room)
    ((room.top) .. (room.bottom)).each do |y|
      ((room.left) .. (room.right)).each do |x|
        case @dungeon[y][x].type
        when :PASSAGE
        else
          @dungeon[y][x].type = :WALL
        end
      end
    end

    visited = {}

    f = proc do |x, y|
      @dungeon[y][x].type = :FLOOR
      visited[[x,y]] = true
      [[-2,0], [0,-2], [+2,0], [0,+2]].shuffle.each do |dx, dy|
        unless !room.properly_in?(x+dx, y+dy) || visited[[x+dx,y+dy]]
          @dungeon[y+dy/2][x+dx/2].type = :FLOOR
          f.(x+dx, y+dy)
        end
      end
    end

    f.(room.left + 1, room.top + 1)
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
    @dungeon[y][x].background_char(@whole_level_lit, @tileset)
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

  def r(n)
    if false
      0
    else
      rand(n)
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

  def render_room(dungeon, room)
    (room.top .. room.bottom).each do |y|
      (room.left .. room.right).each do |x|
        if y == room.top || y == room.bottom
          @dungeon[y][x] = Cell.new(:HORIZONTAL_WALL)
        elsif x == room.left || x == room.right
          @dungeon[y][x] = Cell.new(:VERTICAL_WALL)
        else
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
    return !@dungeon[ty][tx].monster &&
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

  def coordinates_of(obj)
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
