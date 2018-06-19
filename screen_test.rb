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
    @message += "#{msg}\n"
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
    @hero = Hero.new(0, 0, 15, 15, 8, 8, 0, 0, 100.0, 100.0, 1)
    # @hero.inventory << Item.make_item("しあわせの箱")
    @hero.inventory << Item.make_item("ドラゴンキラー")
    @hero.inventory << Item.make_item("みかがみの盾")
    @hero.inventory << Item.make_item("パン")
    @hero.inventory << Item.make_item("大きなパン")
    @hero.inventory << Item.make_item("くさったパン")
    @hero.inventory << Item.make_item("薬草")
    @hero.inventory << Item.make_item("弟切草")
    @hero.inventory << Item.make_item("毒けし草")
    @hero.inventory << Item.make_item("ちからの種")
    @level_number = 0
    @dungeon = Dungeon.new
    @log = MessageLog.new
  end

  def check_level_up
    while @hero.lv < exp_to_lv(@hero.exp)
      @log.add("#{@hero.name}の レベルが 上がった。")
      @hero.lv += 1
      hp_increase = 5
      @hero.max_hp = [@hero.max_hp + 5, 999].min
      @hero.hp = [@hero.max_hp, @hero.hp + 5].min
    end
  end

  def get_hero_attack
    basic = lv_to_attack(exp_to_lv(@hero.exp))
    weapon_score = @hero.weapon ? @hero.weapon.number : 0
    (basic + basic * (weapon_score + @hero.strength - 8)/16.0).round
  end

  def get_hero_defense
    @hero.shield ? @hero.shield.number : 0
  end

  def hero_attack(cell, monster)
    attack = get_hero_attack
    damage = ( ( attack * (15.0/16.0)**monster.defense ) * (112 + rand(32))/128.0 ).to_i
    monster.hp -= damage
    @log.add("#{monster.name}に #{damage} のダメージを与えた。")
    if monster.hp < 1.0
      cell.remove_object(monster)
      @hero.exp += monster.exp
      @log.add("#{monster.name}を たおして #{monster.exp} ポイントの経験値を得た。")
      check_level_up
    end
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
      hero_attack(cell, monster)
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
      update_stairs_direction
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
    when 's'
      status_window
      :nothing
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

  def clear_message
    text = <<EOD
クリア
EOD

    win = Curses::Window.new(3, 10, 5, 15) # lines, cols, y, x
    win.clear
    win.box("\0", "\0")
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    win.getch
    win.close
  end

  # アイテムに適用可能な行動
  def actions_for_item(item)
    item.actions
  end

  def try_place_item(item)
    if @level.cell(@hero.x, @hero.y).can_place?
      @hero.remove_from_inventory(item)
      @level.put_object(@hero.x, @hero.y, item)
      update_stairs_direction
      @log.add("#{item}を 置いた。")
    else
      @log.add("ここには 置けない。")
    end
  end

  # () → :action | :nothing
  def open_inventory
    dispfunc = proc { |item|
      if @hero.weapon.equal?(item) ||
         @hero.shield.equal?(item)
        "E" + item.name
      else
        item.name
      end
    }

    menu = Menu.new(@hero.inventory, y: 1, x: 0, cols: 25, dispfunc: dispfunc)
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
    when "食べる"
      eat_food(item)
    when "飲む"
      take_herb(item)
    when "装備"
      equip(item)
    else
      @log.add("case not covered: #{item}を#{c}。")
    end
    return :action
  ensure
    menu.close
  end

  def increase_max_hp(amount)
    if @hero.max_hp >= 999
      @log.add("これ以上 HP は増えない！")
    else
      increment = [amount, 999 - @hero.max_hp].min
      @hero.max_hp += amount
      @hero.hp = @hero.max_hp
      @log.add("最大HPが #{increment}ポイント 増えた。")
    end
  end

  def increase_hp(amount)
    increment = [@hero.max_hp - @hero.hp, amount].min
    @hero.hp += increment
    @log.add("HPが #{increment}ポイント 回復した。")
  end

  def recover_strength
    @hero.strength = @hero.max_strength
    @log.add("ちからが 回復した。")
  end

  def take_herb(item)
    fail "not a herb" unless item.type == :herb

    @hero.remove_from_inventory(item)
    @log.add("#{item}を 薬にして 飲んだ。")
    case item.name
    when "薬草"
      if @hero.hp_maxed?
        increase_max_hp(2)
      else
        increase_hp(25)
      end
    when "弟切草"
      if @hero.hp_maxed?
        increase_max_hp(4)
      else
        increase_hp(100)
      end
    when "毒けし草"
      unless @hero.strength_maxed?
        recover_strength()
      end
    when "ちからの種"
      if @hero.strength_maxed?
        @hero.max_strength += 1
        @hero.strength = @hero.max_strength
        @log.add("ちからの最大値が 1 ポイント ふえた。")
      else
        @hero.strength += 1
        @log.add("ちからが 1 ポイント 回復した。")
      end
    when "幸せの種"
      @log.add("実装してないよ。")
    when "すばやさの種"
      @log.add("実装してないよ。")
    when "目薬草"
      @log.add("実装してないよ。")
    when "毒草"
      @log.add("実装してないよ。")
    when "目つぶし草"
      @log.add("実装してないよ。")
    when "まどわし草"
      @log.add("実装してないよ。")
    when "メダパニ草"
      @log.add("実装してないよ。")
    when "ラリホー草"
      @log.add("実装してないよ。")
    when "ルーラ草"
      @log.add("実装してないよ。")
    when "火炎草"
      @log.add("実装してないよ。")
    else
      fail "uncoverd case: #{item}"
    end
  end

  def equip(item)
    fail "not a weapon or a shield" unless item.type == :weapon || item.type == :shield
    fail "not in inventory" unless @hero.inventory.find(item)

    if @hero.weapon.equal?(item) # coreferential?
      @hero.weapon = nil
      @log.add("武器を 外した。")
    elsif @hero.shield.equal?(item)
      @hero.shield = nil
      @log.add("盾を 外した。")
    else
      case item.type
      when :weapon
        @hero.weapon = item
      when :shield
        @hero.shield = item
      end
      @log.add("#{item}を 装備した。")
    end
  end

  def increase_max_fullness(amount)
    old = @hero.max_fullness
    unless @hero.max_fullness >= 200.0
      @hero.increase_max_fullness(amount)
      @hero.fullness = @hero.max_fullness
      @log.add("最大満腹度が %.0f%% 増えた。" % [@hero.max_fullness - old])
    end
  end

  def increase_fullness(amount)
    @hero.increase_fullness(amount)
    if @hero.full?
      @log.add("おなかが いっぱいに なった。")
    else
      @log.add("少し おなかが ふくれた。")
    end
  end

  def take_damage(amount)
    @log.add("%.0f ポイントの ダメージを受けた。" % [amount])
    @hero.hp -= amount
    if @hero.hp < 0
      @hero.hp = 0.0
    end
  end

  # ちからの現在値にダメージを受ける。
  def take_damage_strength(amount)
    decrement = [amount, @hero.strength].min
    if @hero.strength > 0
      @log.add("ちからが %d ポイント下がった。" %
               [decrement])
      @hero.strength -= decrement
    else
      # ちから 0 だから平気だもん。
    end
  end

  def eat_food(food)
    fail "not a food" unless food.type == :food

    @hero.remove_from_inventory(food)
    @log.add("#{@hero.name}は #{food.name}を 食べた。")
    case food.name
    when "パン"
      if @hero.full?
        increase_max_fullness(5.0)
      else
        increase_fullness(50.0)
      end
    when "くさったパン"
      if @hero.full?
        increase_max_fullness(10.0)
      else
        increase_fullness(100.0)
      end
      take_damage(10)
      take_damage_strength(3)
    when "大きなパン"
      if @hero.full?
        increase_max_fullness(10.0)
      else
        increase_fullness(100.0)
      end
    else
      fail "food? #{food}"
    end
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
    st = @level.cell(@hero.x, @hero.y).objects.find { |elt| elt.is_a?(StairCase) }
    if st
      new_level(st.upwards ? -1 : +1)
    else
      @log.add("ここに 階段は ない。")
    end
    return :nothing
  end

  def update_stairs_direction
    @level.stairs_going_up = @dungeon.on_return_trip?(@hero)
  end

  def new_level(dir = +1)
    @level_number += dir
    if @level_number == 0
      clear_message
      @quitting = true
    else
      @level = @dungeon.make_level(@level_number, @hero)
      # 主人公を配置する。
      loop do
        x, y = @level.get_random_place(:FLOOR)
        unless @level.has_type_at?(Monster, x, y)
          @hero.x, @hero.y = x, y
          break
        end
      end

      x, y = [@hero.x, @hero.y]
      if @level.has_type_at?(Item, x, y) ||
         @level.has_type_at?(StairCase, x, y) ||
         @level.has_type_at?(Trap, x, y)
        @log.add("足元になにかある。")
      end

      update_stairs_direction
    end
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
    line = "%dF  Lv %d  HP %d/%d  %dG" %
           [@level_number,
            @hero.lv,
            @hero.hp, @hero.max_hp,
            @hero.gold]
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

  def gameover_message
    text = <<EOD
ゲームオーバー
EOD

    win = Curses::Window.new(3, 16, 5, 13) # lines, cols, y, x
    win.clear
    win.box("\0", "\0")
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    win.getch
    win.close
  end

  def exp_until_next_lv
    if @hero.lv == 37
      return nil
    else
      return lv_to_exp(@hero.lv + 1) - @hero.exp
    end
  end

  def status_window
    text = "攻撃力 %d\n" % [get_hero_attack] +
           "防御力 %d\n" % [get_hero_defense] +
           "武器 %s\n" % [@hero.weapon || "なし"] +
           "盾 %s\n" % [@hero.shield || "なし"] +
           "ちから %d/%d\n" % [@hero.strength, @hero.max_strength] +
           "経験値 %d\n" % [@hero.exp] +
           "つぎのLvまで %d\n" % [exp_until_next_lv || "∞"] +
           "満腹度 %d/%d\n" % [@hero.fullness, @hero.max_fullness]

    win = Curses::Window.new(8+2, 23, 1, 0) # lines, cols, y, x
    win.clear
    win.box("\0", "\0")
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    win.getch
    win.close
  end

  EXP_LV_TABLE = [[0, 1],
                  [10, 2],
                  [30, 3],
                  [60, 4],
                  [100, 5],
                  [150, 6],
                  [230, 7],
                  [350, 8],
                  [500, 9],
                  [700, 10],
                  [950, 11],
                  [1200, 12],
                  [1500, 13],
                  [1800, 14],
                  [2300, 15],
                  [3000, 16],
                  [4000, 17],
                  [6000, 18],
                  [9000, 19],
                  [15000, 20],
                  [23000, 21],
                  [33000, 22],
                  [45000, 23],
                  [60000, 24],
                  [80000, 25],
                  [100000, 26],
                  [130000, 27],
                  [180000, 28],
                  [240000, 29],
                  [300000, 30],
                  [400000, 31],
                  [500000, 32],
                  [600000, 33],
                  [700000, 34],
                  [800000, 35],
                  [900000, 36],
                  [999999, 37]]

  def lv_to_exp(level)
    EXP_LV_TABLE.each do |e, lv|
      if level == lv
        return e
      end
    end
    return nil
  end

  def exp_to_lv(exp)
    last_lv = nil
    EXP_LV_TABLE.each do |e, lv|
      if exp < e
        return last_lv
      end
      last_lv = lv
    end
    return last_lv # 37
  end

  def lv_to_attack(lv)
    fail TypeError unless lv.is_a? Numeric
    if lv >= 37
      lv = 37
    end
    pair = [[1, 5],
            [2, 7],
            [3, 9],
            [4, 11],
            [5, 13],
            [6, 16],
            [7, 19],
            [8, 22],
            [9, 25],
            [10, 29],
            [11, 33],
            [12, 37],
            [13, 41],
            [14, 46],
            [15, 51],
            [16, 56],
            [17, 61],
            [18, 65],
            [19, 71],
            [20, 74],
            [21, 77],
            [22, 80],
            [23, 83],
            [24, 86],
            [25, 89],
            [26, 90],
            [27, 91],
            [28, 92],
            [29, 93],
            [30, 94],
            [31, 95],
            [32, 96],
            [33, 97],
            [34, 98],
            [35, 99],
            [36, 100],
            [37, 100]].assoc(lv)
    fail unless pair
    return pair[1]
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

      if @hero.hp < 1.0
        @log.add("#{@hero.name}は ちからつきた。")
        render
        sleep 3
        gameover_message
        break
      end

      # 画面更新
      render

      c = read_command
      @level.darken(@level.fov(@hero))
      sym = dispatch_command(c)
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
