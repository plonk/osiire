require_relative 'monster'

class Gold < Struct.new(:amount)
  def char; '*' end
end

class Cell
  attr_accessor :lit, :explored, :type, :objects

  def initialize type
    @type = type
    @lit = false
    @explored = false
    @objects = []
  end

  def char
    visible_objects = @objects.select { |obj|
      if @lit
        true
      else
        if @explored
          obj.is_a? Gold
        else
          false
        end
      end
    }

    if !@explored
      return ' '
    end

    if !visible_objects.empty?
      return visible_objects.first.char
    end

    case @type
    when :WALL            then ' '
    when :HORIZONTAL_WALL then '-'
    when :VERTICAL_WALL   then '|'
    when :FLOOR
      if @lit then '.' else ' ' end
    when :PASSAGE         then '#'
    else '?'
    end
  end
end

class StairCase
  def char
    '%'
  end
end

class Hero < Struct.new(:x, :y, :curr_hp, :max_hp, :curr_strength, :max_strength, :gold, :exp)
  def name; 'よてえもん' end
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
    return x.between?(0, width-1) && y.between(0, height-1)
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
    @dungeon[y][x].objects << object
  end

  def remove_object(x, y, object)
    @dungeon[y][x].objects.delete(object)
  end
end
