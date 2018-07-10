require_relative 'level' # Hero
require 'curses'
require_relative 'curses_ext'

module ResultScreen
  module_function

  def format_time(seconds)
    h = seconds / 3600
    m = (seconds % 3600) / 60
    s = seconds % 60
    "%2d時間%02d分%02d秒" % [h, m, s]
  end

  def to_data(hero)
    {
      "hero_name"    => hero.name,
      "hero_lv"      => hero.lv,
      "max_hp"       => hero.max_hp,
      "max_fullness" => hero.max_fullness,
      "strength"     => hero.strength,
      "max_strength" => hero.max_strength,
      "exp"          => hero.exp,
      "weapon"       => hero.weapon&.to_s,
      "shield"       => hero.shield&.to_s,
      "ring"         => hero.ring&.to_s,
    }
  end

  def run(data)
    tm = 1
    win = Curses::Window.new(11 + 5, 34, tm, (Curses.cols - 34)/2)
    win.rounded_box
    win.keypad(true)

    begin
      win.setpos(1,1)
      win.addstr("#{data['hero_name']}")
      win.setpos(1, 1 + 12 + 3)
      win.addstr("Lv#{data['hero_lv']}")

      win.setpos(2, 19)
      win.addstr(format_time(data["time"]))

      win.setpos(3, 1)
      win.addstr(data["message"])

      win.setpos(5, 1)
      win.addstr("最大HP    %3d  最大満腹度 %3d％" % [data['max_hp'], data['max_fullness']])

      win.setpos(6, 1)
      win.addstr("ちから %6s  経験値    %6d" % ["#{data['strength']}/#{data['max_strength']}", data['exp']])

      win.setpos(7, 1)
      if data['weapon']
        win.addstr("%s%s" % ['􄀬􄀭', data['weapon']])
      end

      win.setpos(8, 1)
      if data['shield']
        win.addstr("%s%s" % ['􄀮􄀯', data['shield']])
      end

      win.setpos(9, 1)
      if data['ring']
        win.addstr("%s%s" % ['􄀸􄀹', data['ring']])
      end

      data["screen_shot"].each.with_index(10) do |row, y|
        win.setpos(y, 2)
        win.addstr(row)
      end

      Curses.flushinp
      win.getch
    ensure
      win.close
    end
  end
end

if __FILE__ == $0
  Curses.init_screen
  Curses.noecho
  Curses.crmode
  Curses.stdscr.keypad(true)
  at_exit {
    Curses.close_screen
  }
  hero = Hero.new(0, 0, 15, 15, 8, 8, 0, 0, 100.0, 100.0, 1)
  ss = ["􄀼􄀽􄀪􄀫􄀪􄀫􄀪􄀫􄀪􄀫",
        "􄀼􄀽􄀪􄀫􄁊􄁋􄀪􄀫􄀪􄀫",
        "􄀼􄀽􄀺􄀻􄅂􄅃􄀪􄀫􄀪􄀫",
        "􄀼􄀽􄀴􄀵􄀪􄀫􄀪􄀫􄀪􄀫",
        "􄀼􄀽􄀢􄀣􄀤􄀥􄀢􄀣􄀢􄀣",
       ]
  w = Item.make_item("ドラゴンキラー")
  sh = Item.make_item("ドラゴンシールド")
  r = Item.make_item("ハラヘラズの指輪")
  hero.add_to_inventory(w)
  hero.weapon = w
  hero.add_to_inventory(sh)
  hero.shield = sh
  hero.add_to_inventory(r)
  hero.ring = r
  w.number = 4
  sh.number = 10
  data = ResultScreen.to_data(hero).merge({"screen_shot" => ss, "time" => 3661, "message" => "押し入れの1Fでちから尽きた。", "level" => 1})
# require 'json'
#   File.open("ranking.json", "w") do |f|
#     f.write JSON.dump(data)
#   end
  ResultScreen.run(data)
  Curses.close_screen
end
