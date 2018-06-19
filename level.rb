require_relative 'monster'
require_relative 'item'
require_relative 'trap'

class Cell
  attr_accessor :lit, :explored, :type, :objects

  def initialize type
    @type = type
    @lit = false
    @explored = false
    @objects = [].freeze
  end

  def char
    visible_objects = @objects.select { |obj|
      case obj
      when Trap
        obj.visible
      else
        if @lit
          true
        else
          if @explored
            obj.is_a?(Gold) || obj.is_a?(Item)
          else
            false
          end
        end
      end
    }

    if !@explored
      return '　'
    end

    if !visible_objects.empty?
      return visible_objects.first.char
    end

    case @type
    when :WALL            then '􄁀􄁁'
    when :HORIZONTAL_WALL then '􄀢􄀣'
    when :VERTICAL_WALL   then '􄀼􄀽'
    when :FLOOR
      if @lit then '􄀪􄀫' else '􄀾􄀿' end
    when :PASSAGE         then '􄀤􄀥'
    else '？'
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
    @objects.none? { |x|
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

  def item
    @objects.find { |x| x.is_a? Item }
  end

  def gold
    @objects.find { |x| x.is_a? Gold }
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
end

class Hero < Struct.new(:x, :y, :hp, :max_hp, :strength, :max_strength, :gold, :exp, :fullness, :max_fullness, :lv)
  attr_reader :inventory
  attr_accessor :weapon, :shield

  def initialize(*args)
    super
    @inventory = []
  end

  def char
    '􄀦􄀧'
  end

  def remove_from_inventory(item)
    if item.equal?(weapon)
      self.weapon = nil
    end
    if item.equal?(shield)
      self.shield = nil
    end
    @inventory -= [item]
  end

  def name; 'よてえもん' end

  def full?
    fullness > max_fullness - 1.0
  end

  def increase_fullness(amount)
    fail TypeError unless amount.is_a?(Numeric)
    self.fullness = [fullness + amount, max_fullness].min
  end

  def increase_max_fullness(amount)
    fail TypeError unless amount.is_a?(Numeric)
    self.max_fullness = [max_fullness + amount, 200.0].min
  end

  def strength_maxed?
    strength >= max_strength
  end

  def hp_maxed?
    hp > max_hp - 1.0
  end

end

class Rect < Struct.new(:top, :bottom, :left, :right)
  def each_coords
    (top .. bottom).each do |y|
      (left .. right).each do |x|
        yield(x, y)
      end
    end
  end
end

class Level
  attr_reader :stairs_going_up

  def initialize
    @dungeon = Array.new(24) { Array.new(80) { Cell.new(:WALL) } }

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

    @stairs_going_up = false
  end

  def dungeon_char(x, y)
    @dungeon[y][x].char
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

  def passable?(subject, x, y)
    unless x.between?(0, width - 1) && y.between?(0, height - 1)
      # 画面外
      puts "画面外"
      return false
    end
    return @dungeon[y][x].type == :FLOOR || @dungeon[y][x].type == :PASSAGE
  end

  def room_at(x, y)
    @rooms.each do |room|
      if room.properly_in?(x, y)
        return room
      end
    end
    return nil
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

  # 主体 subject の視野 Rect を返す。
  def fov(subject)
    r = room_at(subject.x, subject.y)
    if r
      return Rect.new(r.top, r.bottom, r.left, r.right)
    else
      top = [0, subject.y-1].max
      bottom = [height-1, subject.y+1].min
      left = [0, subject.x-1].max
      right = [width-1, subject.x+1].min
      return Rect.new(top, bottom, left, right)
    end
  end

  def light_up(fov)
    fov.each_coords do |x, y|
      @dungeon[y][x].lit = true
    end
  end

  def darken(fov)
    fov.each_coords do |x, y|
      @dungeon[y][x].lit = false
    end
  end

  def mark_explored(fov)
    fov.each_coords do |x, y|
      @dungeon[y][x].explored = true
    end
  end

  def cell(x, y)
    @dungeon[y][x]
  end

  def put_object(x, y, object)
    @dungeon[y][x].put_object(object)
  end

  def remove_object(x, y, object)
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

end
