TABLE = [
  [ 15, 5, 5, 25],
  [ 18, 6, 5, 29],
  [ 21, 7, 5, 33],
  [ 24, 8, 5, 37],
  [ 27, 9, 6, 42],
  [ 30, 10, 6, 46],
  [ 33, 11, 6, 50],
  [ 36, 12, 6, 54],
  [ 39, 13, 6, 58],
  [ 42, 14, 7, 63],
  [ 45, 15, 7, 134],
  [ 48, 16, 7, 142],
  [ 51, 17, 7, 150],
  [ 54, 18, 7, 158],
  [ 57, 19, 8, 168],
  [ 60, 20, 8, 176],
  [ 63, 21, 8, 184],
  [ 66, 22, 8, 192],
  [ 69, 23, 8, 200],
  [ 72, 24, 9, 210],
  [ 75, 25, 9, 218],
  [ 78, 26, 9, 226],
  [ 81, 27, 9, 234],
  [ 84, 28, 9, 242],
  [ 87, 29, 10, 252],
  [ 90, 30, 10, 260],
  [ 93, 31, 10, 268],
  [ 96, 32, 10, 276],
  [ 99, 33, 10, 284],
  [102, 34, 11, 294],
  [105, 35, 11, 604],
  [108, 36, 11, 620],
  [111, 37, 11, 636],
  [114, 38, 11, 652],
  [117, 39, 12, 672],
  [120, 40, 12, 688],
  [123, 41, 12, 704],
  [126, 42, 12, 720],
  [129, 43, 12, 736],
  [132, 44, 13, 756],
  [135, 45, 13, 772],
  [138, 46, 13, 788],
  [141, 47, 13, 804],
  [144, 48, 13, 820],
  [147, 49, 14, 840],
  [150, 50, 14, 856],
  [153, 51, 14, 872],
  [156, 52, 14, 888],
  [159, 53, 14, 904],
  [162, 54, 15, 1848],
  [165, 55, 15, 1880],
  [168, 56, 15, 1912],
  [171, 57, 15, 1944],
  [174, 58, 15, 1976],
  [177, 59, 16, 2016],
  [180, 60, 16, 2048],
  [183, 61, 16, 2080],
  [186, 62, 16, 2112],
  [189, 63, 16, 2144],
  [192, 64, 17, 2184],
  [195, 65, 17, 2216],
  [198, 66, 17, 2248],
  [201, 67, 17, 2280],
  [204, 68, 17, 2312],
  [207, 69, 18, 2352],
  [210, 70, 18, 2384],
  [213, 71, 18, 2416],
  [216, 72, 18, 2448],
  [219, 73, 18, 2480],
  [222, 74, 15, 2512],
  [215, 72, 14, 2408],
  [210, 70, 14, 2352],
  [205, 68, 13, 2288],
  [200, 66, 13, 2232],
  [195, 64, 12, 2168],
  [190, 62, 12, 2112],
  [185, 60, 11, 2048],
  [180, 58, 11, 1992],
  [175, 56, 10, 1928],
  [170, 54, 10, 936],
  [165, 52, 9, 904],
  [160, 50, 9, 876],
  [155, 48, 8, 844],
  [150, 46, 8, 816],
  [145, 44, 7, 784],
  [140, 42, 7, 756],
  [135, 40, 6, 724],
  [130, 38, 6, 696],
  [125, 36, 5, 664],
  [120, 34, 5, 318],
  [115, 32, 4, 302],
  [110, 30, 4, 288],
  [105, 28, 3, 272],
  [100, 26, 3, 258],
  [ 90, 24, 2, 232],
  [ 80, 22, 2, 208],
  [ 70, 20, 1, 182],
  [ 60, 18, 1, 158],
  [ 50, 16, 0, 132]
]

def name(lv)
  if lv == 1
    "ミミック"
  else
    "ミミック#{lv}歳"
  end
end

def aprr(lv)
  case lv
  when 60..76
    4
  when 99
    1
  else
    2
  end
end

def char(lv)
  case lv
  when 60..69
    "\u{10427c}\u{10427d}"
  when 70..76
    "\u{10427e}\u{10427f}"
  when 99
    "\u{104356}\u{104357}"
  else
    "􄁴􄁵"
  end
end

arr = []
TABLE.each.with_index(+1) do |row, lv|
  hp, strength, defense, exp = row
  h = { char: char(lv),
        name: name(lv),
        max_hp: hp,
        exp: exp,
        strength: strength,
        defense: defense,
        action_point_recovery_rate: aprr(lv),
      }
  arr.push(h)
end

require 'pp'
pp arr
