require 'curses'
require_relative 'room'
require_relative 'level'
require_relative 'dungeon'
require_relative 'menu'

class Program

  def initialize
    Curses.init_screen
    Curses.noecho
    Curses.crmode
    at_exit {
      Curses.close_screen
    }
    @message = ""
    @message_updated_at = Time.now
    @hero = Hero.new(0, 0, 15, 15, 8, 8, 0, 0)
    @level_number = 0
    @dungeon = Dungeon.new
  end

  # String → :move
  def hero_move(c)
    vec = { 'h' => [-1,  0],
            'j' => [ 0, +1],
            'k' => [ 0, -1],
            'l' => [+1,  0],
            'y' => [-1, -1],
            'u' => [+1, -1],
            'b' => [-1, +1],
            'n' => [+1, +1] }[c]
    fail ArgumentError unless vec
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
      return :nothing
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
        add_message("#{@hero.name}は #{gold.amount}G を拾った。")
      end

      item = cell.objects.find(&Item.method(:===))
      if item
        pick(cell.objects, item)
      end
    end

    return :move
  end

  # ヒーロー @hero が配列 objects の要素 item を拾おうとする。
  def pick(objects, item)
    if @hero.inventory.size < 20
      objects.delete(item)
      @hero.inventory << item
      add_message("#{@hero.name}は #{item.name}を 拾った。")
    else
      add_message("持ち物が いっぱいで #{item.name}が 拾えない。")
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

  # String → :action | :move | :nothing
  def dispatch_command(c)
    case c
    when '?'
      help
    when 'h','j','k','l','y','u','b','n'
      hero_move(c)
    when 'i'
      open_inventory
    when '>'
      go_downstairs
    when 'q'
      set_quitting
    else
      add_message("#{c.inspect} なんて 知らない。")
      :nothing
    end
  end

  # () → :nothing
  def set_quitting
    @quitting = true
    :nothing
  end

  # () → :nothing
  def help
    text = <<EOD
★ キャラクターの移動

  y k u
  h @ l
  b j n

★ コマンドキー

     [Enter] 決定。
     [Esc]   キャンセル。
     i       道具一覧を開く。
     >       階段を降りる。
     ?       このヘルプを表示。
     q       ゲームを終了する。
EOD

    win = Curses::Window.new(20, 50, 2, 4) # lines, cols, y, x
    win.clear
    win.box("|", "-", "-")
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    win.getch
    win.close

    return :nothing
  end

  # () → :action | :nothing
  def open_inventory
    menu = Menu.new(@hero.inventory, y: 2, x: 3, cols: 25)
    item = c = nil

    loop do
      item = c = nil
      command, *args = menu.choose

      case command
      when :cancel
        #Curses.beep
        return :nothing
      when :chosen
        item, = args

        action_menu = Menu.new(["食べる", "投げる", "置く"], y: 2, x: 3+25, cols: 9)
        c, *args = action_menu.choose
        case c
        when :cancel
          #Curses.beep
          action_menu.close
          next
        when :chosen
          c, = args
        else fail
        end
        action_menu.close
      end

      break if item and c
    end
    add_message("#{item}を#{c}。")
    return :action
  ensure
    menu.close
  end

  # () -> :nothing
  def go_downstairs
    if @level.cell(@hero.x, @hero.y).objects.any? { |elt| elt.is_a?(StairCase) }
      new_level
    else
      add_message("ここに 階段は ない。")
    end
    return :nothing
  end

  def new_level
    @level_number += 1
    @level = @dungeon.make_level(@level_number, @hero)
    # 主人公を配置する。
    x, y = @level.get_random_place(:FLOOR)
    @hero.x, @hero.y = x, y
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
    (0 ... (Curses.lines)).each do |y|
      (0 ... (Curses.cols/2)).each do |x|
        Curses.setpos(y, x*2)
        # 画面座標から、レベル座標に変換する。
        y1 = y + @hero.y - Curses.lines/2
        x1 = x + @hero.x - Curses.cols/4
        if y1 >= 0 && y1 < @level.height &&
           x1 >= 0 && x1 < @level.width
          if @hero.x == x1 && @hero.y == y1
            Curses.addstr('＠')
          else
            Curses.addstr(@level.dungeon_char(x1, y1))
          end
        else
          Curses.addstr('　')
        end
      end
    end

    # キャラクターステータスの表示
    Curses.setpos(0, 0)
    Curses.addstr("#{@level_number}F" \
                  "  HP #{@hero.curr_hp}/#{@hero.max_hp}" \
                  "  Str #{@hero.curr_strength}/#{@hero.max_strength}" \
                  "  Exp #{@hero.exp}  #{@hero.gold} G")

    # メッセージの表示。
    # Curses.setpos(Curses.lines - 1, 0)
    Curses.setpos(1, 0)
    Curses.addstr(@message)

    # カーソルをキャラクター位置に移動。
    Curses.setpos(Curses.lines/2, Curses.cols/2)

    Curses.refresh
  end

  def monsters_move
  end

  def monsters_action
  end

  def main
    new_level

    @quitting = false

    # メインループ
    until @quitting
      # 視界
      rect = @level.fov(@hero)
      @level.mark_explored(rect)
      @level.light_up(rect)

      render

      c = read_command
      @level.darken(@level.fov(@hero))
      sym = dispatch_command(c)
      #STDERR.puts sym.inspect
      case sym
      when :action, :move
        monsters_move
        monsters_action
      when :nothing
      else fail
      end
    end
  end
end

Program.new.main
