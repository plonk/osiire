require 'pp'

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

class Hero < Struct.new(:x, :y)
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

class Level
  def initialize
    @dungeon = Array.new(24) { Array.new(80) { :WALL } }

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
    case @dungeon[y][x]
    when :WALL            then ' '
    when :HORIZONTAL_WALL then '-'
    when :VERTICAL_WALL   then '|'
    when :FLOOR           then '.'
    when :PASSAGE         then '#'
    else '?'
    end
  end

  def width
    @dungeon[0].size
  end

  def height
    @dungeon.size
  end

  def show_dungeon
    (0...height).map do |y|
      (0...width).map do |x|
        dungeon_char(x, y)
      end.join + "R\n"
    end.join
  end

  def get_random_place(kind)
    candidates = (0 ... height).flat_map do |y|
      (0 ... width).flat_map do |x|
        @dungeon[y][x] == kind ? [[x, y]] : []
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
          @dungeon[y][x] = :HORIZONTAL_WALL
        elsif x == room.left || x == room.right
          @dungeon[y][x] = :VERTICAL_WALL
        else
          @dungeon[y][x] = :FLOOR
        end
      end
    end
  end

  def enterable?(subject, x, y)
    p [x, y]
    unless x.between?(0, width - 1) && y.between?(0, height - 1)
      # 画面外
      puts "画面外"
      return p(false)
    end
    p @dungeon[y][x]
    return p(@dungeon[y][x] == :FLOOR || @dungeon[y][x] == :PASSAGE)
  end
end

class Game
  def main
    @level = Level.new
    x, y = @level.get_random_place(:FLOOR)
    @hero = Hero.new(x, y)
    play_level
  end

  def play_level
    @quitting = false
    until @quitting
      puts render

      c = read_command
      dispatch_command(c)
    end
  end

  def read_command
    return STDIN.read(1)
  end

  # def read_command
  #   loop do
  #     line = gets

  #     if line.nil?
  #       return 'q'
  #     end

  #     line.chomp!
  #     if line.empty?
  #       redo
  #     end
  #     return line[0]
  #   end
  # end

  def dispatch_command(c)
    case c
    when 'h','j','k','l','y','u','b','n'
      hero_move(c)
    when 'q'
      @quitting = true
    end
  end

  def hero_move(c)
    vec = { 'h' => [-1,  0],
            'j' => [ 0, +1],
            'k' => [ 0, -1],
            'l' => [+1,  0],
            'y' => [-1, -1],
            'u' => [+1, -1],
            'b' => [-1, +1],
            'n' => [+1, +1] }[c]
    x, y = vec
    if x * y != 0
      allowed = @level.enterable?(@hero, @hero.x + x, @hero.y + y) &&
                @level.enterable?(@hero, @hero.x + x, @hero.y) &&
                @level.enterable?(@hero, @hero.x, @hero.y + y)
    else
      allowed = @level.enterable?(@hero, @hero.x + x, @hero.y + y)
    end

    if allowed
      @hero.x += x
      @hero.y += y
    end
  end

  def render
    (0 ... @level.height).map do |y|
      (0 ... @level.width).map do |x|
        if @hero.x == x && @hero.y == y
          '@'
        else
          @level.dungeon_char(x, y)
        end
      end.join + "R\n"
    end.join
  end
end

system('stty cbreak')
at_exit { system('stty sane') }
Game.new.main

