module Vec
  module_function

  def chess_distance((x, y), (ox, oy))
    [x - ox, y - oy].map(&:abs).max
  end

  def minus(v, ov)
    [v[0] - ov[0], v[1] - ov[1]]
  end

  def negate(v)
    [-v[0], -v[1]]
  end

  def sign(n)
    if n == 0
      0
    elsif n < 0
      -1
    else
      1
    end
  end

  def normalize(v)
    [sign(v[0]), sign(v[1])]
  end

  DIRS_CLOCKWISE = [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]]
  def rotate_clockwise_45(dir, times)
    i = DIRS_CLOCKWISE.index(dir)
    fail "out of range" unless i
    j = (i + times) % 8
    return DIRS_CLOCKWISE[j]
  end
end

if __FILE__ == $0
  #p Vec.rotate_clockwise_45([0,-1], 7)
end
