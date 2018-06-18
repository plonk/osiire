require 'curses'
require_relative 'room'
require_relative 'level'
require_relative 'dungeon'
require_relative 'menu'

class MessageLog
  attr_reader :message, :updated_at

  def initialize
    @message = ""
    @updated_at = Time.now
  end

  def add(msg)
    if @message == msg
      @message += msg
    else
      @message = msg
    end
    @updated_at = Time.now
  end

  def clear
    @message = ""
    @updated_at = Time.now
  end

end

class Program

  def initialize
    Curses.init_screen
    Curses.noecho
    Curses.crmode
    Curses.stdscr.keypad(true)
    at_exit {
      Curses.close_screen
    }
    @hero = Hero.new(0, 0, 15, 15, 8, 8, 0, 0)
    @level_number = 0
    @dungeon = Dungeon.new
    @log = MessageLog.new
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
            'n' => [+1, +1],
            Curses::KEY_LEFT => [-1, 0],
            Curses::KEY_RIGHT => [+1, 0],
            Curses::KEY_UP => [0, -1],
            Curses::KEY_DOWN => [0, +1],
          }[c]
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
      #@log.add("その方向へは進めない。")
      return :nothing
    end

    x1 = @hero.x + dx
    y1 = @hero.y + dy

    cell = @level.cell(x1, y1)
    monster = cell.objects.find { |obj| obj.is_a? Monster }
    if monster
      cell.remove_object(monster)
      @hero.exp += monster.exp
      @log.add("#{@hero.name}は #{monster.name}を たおした。")
    else
      @hero.x = x1
      @hero.y = y1

      gold = cell.objects.find { |obj| obj.is_a? Gold }
      if gold
        cell.remove_object(gold)
        @hero.gold += gold.amount
        @log.add("#{@hero.name}は #{gold.amount}G を拾った。")
      end

      item = cell.objects.find(&Item.method(:===))
      if item
        pick(cell, item)
      end
    end

    return :move
  end

  # ヒーロー @hero が配列 objects の要素 item を拾おうとする。
  def pick(cell, item)
    if @hero.inventory.size < 20
      cell.remove_object(item)
      @hero.inventory << item
      @log.add("#{@hero.name}は #{item.name}を 拾った。")
    else
      @log.add("持ち物が いっぱいで #{item.name}が 拾えない。")
    end
  end


  # String → :action | :move | :nothing
  def dispatch_command(c)
    case c
    when ']'
      cheat_go_downstairs
    when '['
      cheat_go_upstairs
    when '?'
      help
    when 'h','j','k','l','y','u','b','n',
         Curses::KEY_LEFT, Curses::KEY_RIGHT, Curses::KEY_UP, Curses::KEY_DOWN
      hero_move(c)
    when 'i'
      open_inventory
    when '>'
      go_downstairs
    when 'q'
      set_quitting
    else
      @log.add("#{c.inspect} なんて 知らない。")
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

  # アイテムに適用可能な行動
  def actions_for_item(item)
    item.actions
  end

  def try_place_item(item)
    if @level.cell(@hero.x, @hero.y).can_place?
      @hero.remove_from_inventory(item)
      @level.put_object(@hero.x, @hero.y, item)
      @log.add("#{item}を 置いた。")
    else
      @log.add("ここには 置けない。")
    end
  end

  # () → :action | :nothing
  def open_inventory
    menu = Menu.new(@hero.inventory, y: 1, x: 0, cols: 25)
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

        action_menu = Menu.new(actions_for_item(item), y: 1, x: 25, cols: 9)
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

    case c
    when "置く"
      try_place_item(item)
    else
      @log.add("case not covered: #{item}を#{c}。")
    end
    return :action
  ensure
    menu.close
  end

  def cheat_go_downstairs
    if @level_number < 99
      new_level(+1)
    end
    return :nothing
  end

  def cheat_go_upstairs
    if @level_number > 1
      new_level(-1)
    end
    return :nothing
  end

  # () -> :nothing
  def go_downstairs
    if @level.cell(@hero.x, @hero.y).objects.any? { |elt| elt.is_a?(StairCase) }
      new_level
    else
      @log.add("ここに 階段は ない。")
    end
    return :nothing
  end

  def new_level(dir = +1)
    @level_number += dir
    @level = @dungeon.make_level(@level_number, @hero)
    # 主人公を配置する。
    x, y = @level.get_random_place(:FLOOR)
    @hero.x, @hero.y = x, y
  end

  def read_command
    Curses.timeout = 100 # milliseconds
    until c = Curses.getch
      if Time.now - @log.updated_at >= 1.5
        @log.clear
        render
      end
    end
    return c
  end

  def render_map
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
            Curses.addstr(@hero.char)
          else
            Curses.addstr(@level.dungeon_char(x1, y1))
          end
        else
          Curses.addstr('　')
        end
      end
    end
  end

  def move_cursor_to_hero
    # カーソルをキャラクター位置に移動。
    Curses.setpos(Curses.lines/2, Curses.cols/2)
  end

  def render
    render_map()

    render_status()

    render_message()

    move_cursor_to_hero()

    Curses.refresh
  end

  def render_status
    # キャラクターステータスの表示
    Curses.setpos(0, 0)
    Curses.clrtoeol
    line = "#{@level_number}F" \
           "  HP #{@hero.curr_hp}/#{@hero.max_hp}" \
           "  Str #{@hero.curr_strength}/#{@hero.max_strength}" \
           "  Exp #{@hero.exp}  #{@hero.gold} G"
    Curses.addstr(line)
  end

  # メッセージの表示。
  def render_message
    Curses.setpos(1, 0)
    Curses.addstr(@log.message)
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
