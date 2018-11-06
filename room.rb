class Room < Struct.new(:top, :bottom, :left, :right)
  def initialize(*args)
    super
  end

  # 座標は部屋の中？
  def in?(x, y)
    return x >= left && x <= right  &&
           y >= top  && y <= bottom
  end

  # 座標は部屋の中？ 境界に当たる、入口や壁は含まない
  def properly_in?(x, y)
    return x > left && x < right  &&
           y > top  && y < bottom
  end

  # 部屋を小さくする。
  def distort!(opts = {})
    fail "degenerate room cannot be distorted" if degenerate?
    min_height = opts[:min_height] || 5
    min_width = opts[:min_width] || 5

    t = (height - min_height).fdiv(2).ceil
    b = (height - min_height).fdiv(2).floor
    l = (width - min_width).fdiv(2).ceil
    r = (width - min_width).fdiv(2).floor

    self.top    = rand(top .. (top+t))
    self.bottom = rand((bottom-b) .. bottom)
    self.left   = rand(left .. (left+l))
    self.right  = rand((right-r) .. right)
  end

  def make_degenerate!
    self.top, self.left = [*(top+1 .. bottom-1)].sample, [*(left+1 .. right-1)].sample
    # self.top, self.left = (top + bottom)/2, (left + right)/2
    self.bottom, self.right = [self.top, self.left]
  end

  def width
    right - left + 1
  end

  def height
    bottom - top + 1
  end

  def degenerate?
    width == 1
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
      y1 = choose_passage_y(room1)
      y2 = choose_passage_y(room2)
      midway = (room1.right + room2.left).div(2)
      (room1.right .. midway).each do |x|
        dungeon[y1][x] = Cell.new :PASSAGE
      end
      (y1 > y2 ? (y2 .. y1) : (y1 .. y2)).each do |y|
        dungeon[y][midway] = Cell.new :PASSAGE
      end
      (midway .. room2.left).each do |x|
        dungeon[y2][x] = Cell.new :PASSAGE
      end
    when :vertical
      x1 = choose_passage_x(room1)
      x2 = choose_passage_x(room2)
      midway = (room1.bottom + room2.top).div(2)
      (room1.bottom .. midway).each do |y|
        dungeon[y][x1] = Cell.new :PASSAGE
      end
      (x1 > x2 ? (x2 .. x1) : (x1 .. x2)).each do |x|
        dungeon[midway][x] = Cell.new :PASSAGE
      end
      (midway .. room2.top).each do |y|
        dungeon[y][x2] = Cell.new :PASSAGE
      end
    else
      fail
    end
  end

  def choose_passage_x(room)
    if room.width == 1
      room.left
    else
      ((room.left+1) .. (room.right-1)).select { |x| (x - room.left).odd? }.sample
    end
  end

  def choose_passage_y(room)
    if room.height == 1
      room.top
    else
      ((room.top+1) .. (room.bottom-1)).select { |y| (y - room.top).odd? }.sample
    end
  end

end
