require 'pp'

@dungeon = Array.new(24) { Array.new(80) { :WALL } }

def show_dungeon
  @dungeon.map { |row|
    row.map { |kind|
      case kind
      when :WALL then ' '
      when :HORIZONTAL_WALL then '-'
      when :VERTICAL_WALL then '|'
      when :FLOOR then '.'
      when :PASSAGE then '#'
      end
    }.join
  }.join("R\n") + "R\n"
end

# WALL (several kind)
# FLOOR (wet or dry)
# WATER

class Room < Struct.new(:top, :bottom, :left, :right)
  def initialize(*args)
    super
  end

  def in?(x, y)
    return x >= left && x <= right  &&
           y >= top  && y <= bottom
  end

  def distort!
    self.top = rand(top .. (bottom - 5))
    self.bottom = rand((top + 5) .. bottom)
    self.left = rand(left .. (right - 5))
    self.right = rand((left + 5) .. right)
  end
end

class Connection
  attr_accessor :realized
  attr_accessor :direction
  attr :room1, :room2

  def initialize(room1, room2, direction)
    @room1 = room1
    @room2 = room2
    @direction = direction
    @realized = false
  end

  def other_room(r)
    if r == room1
      room2
    elsif r == room2
      room1
    else
      fail 'invalid argument'
    end
  end

  def draw(dungeon)
    case direction
    when :horizontal
      y1 = ((room1.top+1) .. (room1.bottom-1)).to_a.sample
      y2 = ((room2.top+1) .. (room2.bottom-1)).to_a.sample
      midway = (room1.right + room2.left).div(2)
      (room1.right .. midway).each do |x|
        dungeon[y1][x] = :PASSAGE
      end
      (y1 > y2 ? (y2 .. y1) : (y1 .. y2)).each do |y|
        dungeon[y][midway] = :PASSAGE
      end
      (midway .. room2.left).each do |x|
        dungeon[y2][x] = :PASSAGE
      end
    when :vertical
      x1 = ((room1.left+1) .. (room1.right-1)).to_a.sample
      x2 = ((room2.left+1) .. (room2.right-1)).to_a.sample
      midway = (room1.bottom + room2.top).div(2)
      (room1.bottom .. midway).each do |y|
        dungeon[y][x1] = :PASSAGE
      end
      (x1 > x2 ? (x2 .. x1) : (x1 .. x2)).each do |x|
        dungeon[midway][x] = :PASSAGE
      end
      (midway .. room2.top).each do |y|
        dungeon[y][x2] = :PASSAGE
      end
    else
      fail
    end
  end
end

def render_room(dungeon, room)
  (room.top .. room.bottom).each do |y|
    (room.left .. room.right).each do |x|
      if y == room.top || y == room.bottom
        @dungeon[y][x] = :HORIZONTAL_WALL
      elsif x == room.left || x == room.right
        @dungeon[y][x] = :VERTICAL_WALL
      else
        @dungeon[y][x] = :FLOOR
      end
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

# 012
# 345
# 678

def connect_rooms(dungeon, room1, room2, direction)
  case direction
  when :horizontally
    y1 = ((room1.top+1) .. (room1.bottom-1)).to_a.sample
    y2 = ((room2.top+1) .. (room2.bottom-1)).to_a.sample
    midway = (room1.right + room2.left).div(2)
    (room1.right .. midway).each do |x|
      dungeon[y1][x] = :PASSAGE
    end
    (y1 > y2 ? (y2 .. y1) : (y1 .. y2)).each do |y|
      dungeon[y][midway] = :PASSAGE
    end
    (midway .. room2.left).each do |x|
      dungeon[y2][x] = :PASSAGE
    end
  when :vertically
    x1 = ((room1.left+1) .. (room1.right-1)).to_a.sample
    x2 = ((room2.left+1) .. (room2.right-1)).to_a.sample
    midway = (room1.bottom + room2.top).div(2)
    (room1.bottom .. midway).each do |y|
      dungeon[y][x1] = :PASSAGE
    end
    (x1 > x2 ? (x2 .. x1) : (x1 .. x2)).each do |x|
      dungeon[midway][x] = :PASSAGE
    end
    (midway .. room2.top).each do |y|
      dungeon[y][x2] = :PASSAGE
    end
  else
    fail
  end
end

@connections = []

# add potential connection between rooms
def add_connection(room1, room2, direction)
  conn = Connection.new(room1, room2, direction)
  @connections << conn
end

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

puts show_dungeon

