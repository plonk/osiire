require 'curses'
require_relative 'room'
require_relative 'level'

class Program
  def initialize
    Curses.init_screen
    Curses.crmode
    at_exit {
      Curses.close_screen
    }
    @message = ""
    @message_updated_at = Time.now
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
    dx, dy = vec
    if dx * dy != 0
      allowed = @level.passable?(@hero, @hero.x + dx, @hero.y + dy) &&
                @level.passable?(@hero, @hero.x + dx, @hero.y) &&
                @level.passable?(@hero, @hero.x, @hero.y + dy)
    else
      allowed = @level.passable?(@hero, @hero.x + dx, @hero.y + dy)
    end

    unless allowed
      #add_message("その方向へは進めない。")
      return
    end

    x1 = @hero.x + dx
    y1 = @hero.y + dy

    cell = @level.cell(x1, y1)
    monster = cell.objects.find { |obj| obj.is_a? Monster }
    if monster
      cell.objects.delete(monster)
      @hero.exp += monster.exp
      add_message("#{@hero.name}は #{monster.name}を たおした。")
    else
      @hero.x = x1
      @hero.y = y1

      gold = cell.objects.find { |obj| obj.is_a? Gold }
      if gold
        cell.objects.delete(gold)
        @hero.gold += gold.amount
        add_message("#{@hero.name}は #{gold.amount}Gを拾った。")
      end
    end
  end

  def add_message(msg)
    if @message == msg
      @message += msg
    else
      @message = msg
    end
    @message_updated_at = Time.now
  end

  def dispatch_command(c)
    case c
    when 'h','j','k','l','y','u','b','n'
      hero_move(c)
    when '>'
      go_downstairs
    when 'q'
      @quitting = true
    end
  end

  def go_downstairs
    if @level.cell(@hero.x, @hero.y).objects.any? { |elt| elt.is_a?(StairCase) }
      new_level
    end
  end

  def new_level
    @level = Level.new

    x, y = @level.get_random_place(:FLOOR)
    @hero.x, @hero.y = x, y

    x, y = @level.get_random_place(:FLOOR)
    @level.put_object(x, y, StairCase.new)

    # 金を置く。
    5.times do
      x, y = @level.get_random_place(:FLOOR)
      cell = @level.cell(x, y)
      if cell.objects.empty?
        cell.objects << Gold.new(rand(100..1000))
      end
    end

    # モンスターを配置する。
    5.times do
      x, y = @level.get_random_place(:FLOOR)
      cell = @level.cell(x, y)
      if cell.objects.none? { |obj| obj.is_a? Monster }
        cell.objects << Monster.make_monster('まんまる')
      end
    end
  end

  def play_level
    @quitting = false

    # メインループ
    until @quitting
      # 視界
      fov = @level.fov(@hero)
      @level.mark_explored(fov)
      @level.light_up(fov)

      render

      c = read_command
      @level.darken(@level.fov(@hero))
      dispatch_command(c)
    end
  end

  def read_command
    Curses.timeout = 100 # milliseconds
    until c = Curses.getch
      if Time.now - @message_updated_at >= 1.5
        @message = ""
        render
      end
    end
    return c
  end

  def render
    # マップの描画
    (0 ... Curses.lines).each do |y|
      (0 ... Curses.cols).each do |x|
        Curses.setpos(y, x)
        # 画面座標から、レベル座標に変換する。
        y1 = y + @hero.y - Curses.lines/2
        x1 = x + @hero.x - Curses.cols/2
        if y1 >= 0 && y1 < @level.height &&
           x1 >= 0 && x1 < @level.width
          if @hero.x == x1 && @hero.y == y1
            Curses.addch('@')
          else
            Curses.addch(@level.dungeon_char(x1, y1))
          end
        else
          Curses.addch(' ')
        end
      end
    end

    # キャラクターステータスの表示
    Curses.setpos(0, 0)
    Curses.addstr("#{1}F  HP #{@hero.curr_hp}/#{@hero.max_hp}  Str #{@hero.curr_strength}/#{@hero.max_strength}  Exp #{@hero.exp}  #{@hero.gold} G")

    # メッセージの表示。
    # Curses.setpos(Curses.lines - 1, 0)
    Curses.setpos(1, 0)
    Curses.addstr(@message)

    # カーソルをキャラクター位置に移動。
    Curses.setpos(Curses.lines/2, Curses.cols/2)

    Curses.refresh
  end

  def main
    @hero = Hero.new(0, 0, 15, 15, 8, 8, 0, 0)
    new_level
    play_level
  end
end

Program.new.main
