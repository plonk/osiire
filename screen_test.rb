require 'curses'
require_relative 'room'
require_relative 'level'
require_relative 'dungeon'
require_relative 'menu'
require_relative 'vec'
require_relative 'charlevel'

class MessageLog
  attr_reader :message, :updated_at

  def initialize
    @lines = []
    @updated_at = Time.now
  end

  def add(msg)
    @lines << msg
    while @lines.size > 4
      @lines.shift
    end
    @updated_at = Time.now
  end

  def message
    return @lines.join("\n")
  end

  def clear
    @lines.clear
    @updated_at = Time.now
  end

end

class Action < Struct.new(:type, :direction)
end

class Program
  include CharacterLevel

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
    @hero.inventory << Item.make_item("皮の盾")
    @hero.inventory << Item.make_item("盗賊の指輪")
    @hero.inventory << Item.make_item("ワナ抜けの指輪")
    @hero.inventory << Item.make_item("火炎草")
    @hero.inventory << Item.make_item("ルーラ草")
    @hero.inventory << Item.make_item("ラリホー草")
    @hero.inventory << Item.make_item("目薬草")
    @hero.inventory << Item.make_item("幸せの種")
    @hero.inventory << Item.make_item("パン")
    @hero.inventory << Item.make_item("大きなパン")
    @hero.inventory << Item.make_item("くさったパン")
    @hero.inventory << Item.make_item("薬草")
    @hero.inventory << Item.make_item("弟切草")
    @hero.inventory << Item.make_item("毒けし草")
    @hero.inventory << Item.make_item("ちからの種")
    @hero.inventory << Item.make_item("かなしばりの巻物")
    @hero.inventory << Item.make_item("聖域の巻物")
    @hero.inventory << Item.make_item("リレミトの巻物")
    @hero.inventory << Item.make_item("イオの巻物")
    @hero.inventory << Item.make_item("レミーラの巻物")
    @level_number = 0
    @dungeon = Dungeon.new
    @log = MessageLog.new

    @last_room = nil
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

  def get_monster_attack(m)
    m.strength
  end

  def get_hero_defense
    @hero.shield ? @hero.shield.number : 0
  end

  def hero_attack(cell, monster)
    on_monster_attacked(monster)
    if rand() < 0.125
      @log.add("#{@hero.name}の 攻撃は外れた。")
    else
      attack = get_hero_attack
      damage = ( ( attack * (15.0/16.0)**monster.defense ) * (112 + rand(32))/128.0 ).to_i
      monster.hp -= damage
      @log.add("#{monster.name}に #{damage} のダメージを与えた。")
      check_monster_dead(cell, monster)
    end
  end

  def check_monster_dead(cell, monster)
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
    monster = cell.monster
    if monster
      hero_attack(cell, monster)
    else
      @hero.x = x1
      @hero.y = y1

      gold = cell.gold
      if gold
        cell.remove_object(gold)
        @hero.gold += gold.amount
        @log.add("#{@hero.name}は #{gold.amount}G を拾った。")
      end

      item = cell.item
      if item
        pick(cell, item)
      end

      trap = cell.trap
      if trap
        activation_rate = trap.visible ? (1/4.0) : (3/4.0)
        trap.visible = true
        if @hero.ring&.name != "ワナ抜けの指輪" && rand() < activation_rate
          trap_activate(trap)
        else
          trap_not_activate(trap)
        end
      end
    end

    return :move
  end

  def trap_not_activate(trap)
    @log.add("#{trap.name}は 発動しなかった。")
  end

  def take_damage_shield
    if @hero.shield
      if @hero.shield.rustproof?
        @log.add("しかし #{@hero.shield}は錆びなかった。")
      else
        if @hero.shield.number > 0
          @hero.shield.number -= 1
          @log.add("盾が錆びてしまった！")
        else
          @log.add("しかし 何も起こらなかった。")
        end
      end
    else
      @log.add("しかし なんともなかった。")
    end
  end

  # アイテムをばらまく。
  def strew_items
    count = 0
    candidates = @hero.inventory.reject { |x| x.equal?(@hero.weapon) || x.equal?(@hero.shield) }
    candidates.shuffle!
    [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]].each do |dx, dy|
      break if candidates.empty?
      x, y = @hero.x + dx, @hero.y + dy
      if @level.in_dungeon?(x, y) &&
         @level.cell(x, y).can_place?
        item = candidates.shift
        @level.put_object(x, y, item)
        @hero.remove_from_inventory(item)
        count += 1
      end
    end

    if count > 0
      @log.add("アイテムを #{count}個 ばらまいてしまった！")
    end
  end

  def hero_teleport
    x, y = @level.get_random_place(:FLOOR)
    until !@level.cell(x, y).monster
      x, y = @level.get_random_place(:FLOOR)
    end
    @hero.x, @hero.y = x, y
  end


  def trap_activate(trap)
    case trap.name
    when "ワープゾーン"
      hero_teleport
      @log.add("ワープゾーンだ！")
    when "硫酸"
      @log.add("足元から酸がわき出ている！")
      take_damage_shield
    when "トラばさみ"
      @log.add("トラばさみに かかってしまった！")
    when "眠りガス"
      @log.add("突然眠気が襲ってきた。")
    when "石ころ"
      @log.add("石にけつまずいて 転んだ！")
      strew_items
    when "矢"
      @log.add("矢が飛んできた！")
      take_damage(5)
    when "毒矢"
      @log.add("矢が飛んできた！")
      take_damage(5)
      take_damage_strength(1)
    when "地雷"
      @log.add("足元で爆発が起こった！")
      take_damage((@hero.hp / 2.0).ceil)
    when "落とし穴"
      @log.add("落とし穴だ！")
      new_level(+1)
    else fail
    end
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

  def reveal_trap(x, y)
    cell = @level.cell(x, y)
    trap = cell.trap
    if trap && !trap.visible
      trap.visible = true
      @log.add("#{trap.name}を 見つけた。")
    end
  end

  # 周り8マスをワナチェックする
  def search
    x, y = @hero.x, @hero.y
    [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]].each do |xoff, yoff|
      if @level.in_dungeon?(x, y)
        reveal_trap(x + xoff, y + yoff)
      end
    end
    return :action
  end

  def get_current_cell
    @level.cell(@hero.x, @hero.y)
  end

  def activate_underfoot
    cell = get_current_cell
    if cell.stair_case
      go_downstairs
    elsif cell.item
      pick(cell, cell.item)
      return :action
    elsif cell.trap
      trap_activate(cell.trap)
      return :nothing # nothing でいいの？
    else
      @log.add("足元には何もない。")
      return :nothing
    end
  end

  # -> :nothing | ...
  def underfoot_menu
    # 足元にワナがある場合、階段がある場合、アイテムがある場合、なにもない場合。
    cell = @level.cell(@hero.x, @hero.y)
    if cell.trap
      @log.add("足元には #{cell.trap.name}がある。「>」でわざとかかる。")
      return :nothing
    elsif cell.stair_case
      @log.add("足元には 階段がある。「>」で昇降。")
      return :nothing
    elsif cell.item
      @log.add("足元には #{cell.item}が ある。")
      return :nothing
    else
      @log.add("足元には なにもない。")
      return :nothing
    end
  end

  # String → :action | :move | :nothing
  def dispatch_command(c)
    case c
    when ','
      underfoot_menu
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
      activate_underfoot
    when 'q'
      set_quitting
    when 's'
      status_window
      :nothing
    when '.'
      search
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
     >       階段を降りる、足元のアイテムを拾う等。
     ,       足元を調べる。
     .       周りを調べる。
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
         @hero.shield.equal?(item) ||
         @hero.ring.equal?(item)
        "E" + item.to_s
      else
        item.to_s
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
    when "読む"
      read_scroll(item)
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
    @log.add("HPが #{increment.floor}ポイント 回復した。")
  end

  def recover_strength
    @hero.strength = @hero.max_strength
    @log.add("ちからが 回復した。")
  end

  def read_scroll(item)
    fail "not a scroll" unless item.type == :scroll

    @hero.remove_from_inventory(item)
    @log.add("#{item}を 読んだ。")

    case item.name
    when "レミーラの巻物"
      @level.whole_level_lit = true
      @log.add("ダンジョンが あかるくなった。")
    when "バイキルトの巻物"
      if @hero.weapon
        @hero.weapon.number += 1
        @log.add("#{@hero.weapon.name}が 少し強くなった。")
      else
        @log.add("しかし 何も起こらなかった。")
      end
    when "スカラの巻物"
      if @hero.shield
        @hero.shield.number += 1
        @log.add("#{@hero.shield.name}が 少し強くなった。")
      else
        @log.add("しかし 何も起こらなかった。")
      end
    when "メッキの巻物"
      if @hero.shield && !@hero.shield.rustproof?
        @log.add("#{@hero.shield}に メッキがほどこされた！")
        @hero.shield.gold_plated = true
      else
        @log.add("しかし 何も起こらなかった。")
      end
    when "シャナクの巻物"
      @log.add("呪いなんて信じてるの？")
    when "かなしばりの巻物"
      monsters = []
      rect = @level.surroundings(@hero.x, @hero.y)
      rect.each_coords do |x, y|
        if @level.in_dungeon?(x, y)
          m = @level.cell(x, y).monster
          monsters << m if m
        end
      end
      if monsters.any?
        monsters.each do |m|
          unless m.paralyzed?
            m.status_effects.push(StatusEffect.new(:paralysis, 50))
          end
        end
        @log.add("まわりの モンスターの動きが 止まった。")
      else
        @log.add("しかし 何も起こらなかった。")
      end
    when "聖域の巻物"
      @log.add("何も起こらなかった。足元に置いて使うようだ。")
    when "リレミトの巻物"
      if @dungeon.on_return_trip?(@hero)
        @log.add("帰り道では 使えない。")
      elsif @level_number <= 1
        @log.add("しかし何も起こらなかった。")
      else
        @log.add("不思議なちからで 1階 に引き戻された！")
        new_level(1 - @level_number)
      end
    when "イオの巻物"
      @log.add("空中で 爆発が 起こった！")
      attack_monsters_in_room(5..35)
    else
      @log.add("実装してないよ。")
    end
  end

  def on_monster_attacked(monster)
    wake_monster(monster)
    # かなしばり状態も解ける。
    monster.status_effects.reject! { |e|
      e.type == :paralysis
    }
  end

  def wake_monster(monster)
    if monster.state == :asleep
      monster.state = :awake
    end
  end

  def attack_monsters_in_room(range)
    total_damage = 0
    monster_count = 0
    rect = @level.fov(@hero.x, @hero.y)
    rect.each_coords do |x, y|
      if @level.in_dungeon?(x, y)
        cell = @level.cell(x, y)
        monster = cell.monster
        if monster
          wake_monster(monster)
          monster_count += 1
          r = rand(range)
          total_damage += r
          monster.hp -= r
          check_monster_dead(cell, monster)
        end
      end
    end
    if monster_count > 0
      @log.add("#{monster_count}匹の モンスターに 合計 #{total_damage}ポイントのダメージ！")
    end
  end
 
  def take_herb(item)
    fail "not a herb" unless item.type == :herb

    # 副作用として満腹度5%回復。
    @hero.increase_fullness(5.0)

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
      required_exp = lv_to_exp(@hero.lv + 1)
      if required_exp
        @hero.exp = required_exp
        check_level_up
      else
        @log.add("しかし 何も起こらなかった。")
      end
    when "すばやさの種"
      @log.add("実装してないよ。")
    when "目薬草"
      @level.each_coords do |x, y|
        trap = @level.cell(x, y).trap
        if trap
          trap.visible = true
        end
      end
      @log.add("ワナが見えるようになった。")
    when "毒草"
      @log.add("実装してないよ。")
    when "目つぶし草"
      @log.add("実装してないよ。")
    when "まどわし草"
      @log.add("実装してないよ。")
    when "メダパニ草"
      @log.add("実装してないよ。")
    when "ラリホー草"
      unless @hero.asleep?
        @hero.status_effects.push(StatusEffect.new(:sleep, 5))
        @log.add("#{@hero.name}は 眠りに落ちた。")
      end
    when "ルーラ草"
      hero_teleport
      @log.add("#{@hero.name}は ワープした。")
    when "火炎草"
      @log.add("こいつは HOT だ！")
    else
      fail "uncoverd case: #{item}"
    end
  end

  def equip(item)
    fail "not in inventory" unless @hero.inventory.find(item)
    case item.type
    when :weapon
      equip_weapon(item)
    when :shield
      equip_shield(item)
    when :ring
      equip_ring(item)
    else
      fail "equip"
    end
  end

  def equip_weapon(item)
    if @hero.weapon.equal?(item) # coreferential?
      @hero.weapon = nil
      @log.add("武器を 外した。")
    else
      @hero.weapon = item
      @log.add("#{item}を 装備した。")
    end
  end

  def equip_shield(item)
    if @hero.shield.equal?(item)
      @hero.shield = nil
      @log.add("盾を 外した。")
    else
      @hero.shield = item
      @log.add("#{item}を 装備した。")
    end
  end

  def equip_ring(item)
    if @hero.ring.equal?(item)
      @hero.ring = nil
      @log.add("#{item.name}を 外した。")
    else
      @hero.ring = item
      @log.add("#{item.name}を 装備した。")
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
    st = @level.cell(@hero.x, @hero.y).stair_case
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
      if Time.now - @log.updated_at >= 2.0
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
    line = "%dF  Lv %d  HP %d/%d  %dG  満腹度 %d%% [%04d]" %
           [@level_number,
            @hero.lv,
            @hero.hp, @hero.max_hp,
            @hero.gold,
            @hero.fullness.ceil,
            @level.turn]
    Curses.addstr(line)
  end

  # メッセージの表示。
  def render_message
    Curses.setpos(1, 0)
    Curses.addstr(@log.message)
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
           "指輪 %s\n" % [@hero.ring || "なし"] +
           "ちから %d/%d\n" % [@hero.strength, @hero.max_strength] +
           "経験値 %d\n" % [@hero.exp] +
           "つぎのLvまで %d\n" % [exp_until_next_lv || "∞"] +
           "満腹度 %d/%d\n" % [@hero.fullness.ceil, @hero.max_fullness]

    win = Curses::Window.new(9+2, 23, 1, 0) # lines, cols, y, x
    win.clear
    win.box("\0", "\0")
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    win.getch
    win.close
  end

  # Monster → Action
  def monster_action(m, mx, my)
    case m.name
    # 特殊な行動パターンを持つモンスターはここに when 節を追加。
    when nil
    else
      case m.state
      when :asleep
        # ヒーローがに周囲8マスに居れば1/2の確率で起きる。
        if @hero.ring&.name != "盗賊の指輪" &&
           @level.surroundings(mx, my).include?(@hero.x, @hero.y)
          if rand() < 0.5
            m.state = :awake
          end
        end
        return Action.new(:rest, nil)
      when :awake
        # ジェネリックな行動パターン。

        # * ヒーローに隣接していればヒーローに攻撃。
        if @level.can_attack?(m, mx, my, @hero.x, @hero.y) # カド越しには攻撃できない。
          return Action.new(:attack, Vec.minus([mx, my], [@hero.x, @hero.y]))
        else
          # * モンスターの視界内にヒーローが居れば目的地を再設定。
          if @level.fov(mx, my).include?(@hero.x, @hero.y)
            m.goal = [@hero.x, @hero.y]
          end

          # * 目的地がある場合...
          if m.goal
            # * 目的地に到着していれば目的地をリセット。
            if m.goal == [mx, my]
              m.goal = nil
            end
          end

          if m.goal
            # * 目的地があれば目的地へ向かう。(方向のpreferenceが複雑)
            dir = Vec.normalize(Vec.minus(m.goal, [mx, my]))
            [dir,
             *[[dir[0], 0],
               [0, dir[1]]].shuffle].each do |dx, dy|
              if @level.can_move_to?(m, mx, my, mx+dx, my+dy)
                return Action.new(:move, [dx, dy])
              end
            end

            # 目的地に行けそうもないのであきらめる。(はやっ!)
            m.goal = nil
            return Action.new(:rest, nil)
          else
            # * 目的地が無ければ...

            # * 部屋の中に居れば、出口の1つを目的地に設定する。
            room = @level.room_at(mx, my)
            if room
              exit_points = @level.room_exits(room)
              preferred = exit_points.reject { |x,y|
                [x,y] == [mx - m.facing[0], my - m.facing[1]] # 今入ってきた出入口は除外する。
              }
              if preferred.any?
                m.goal = preferred.sample
                return monster_action(m, mx, my)
              elsif exit_points.any?
                # 今入ってきた出入口でも選択する。
                m.goal = exit_points.sample
                return monster_action(m, mx, my)
              else
                return Action.new(:rest, nil) # どうすりゃいいんだい
              end
            else
              # * 部屋の外に居れば、向いている方向へ進もうとする。

              tx, ty = [mx + m.facing[0], my + m.facing[1]]
              if @level.can_move_to?(m, mx, my, tx, ty)
                return Action.new(:move, m.facing)
              else
                # * 進めなければ反対以外の方向に進もうとする。
                #   通路を曲がるには ±90度で十分か。
                dirs = [Vec.rotate_clockwise_45(m.facing, +2),
                        Vec.rotate_clockwise_45(m.facing, -2)].shuffle
                dirs.each do |dx, dy|
                  if @level.can_move_to?(m, mx, my, mx+dx, my+dy)
                    return Action.new(:move, [dx,dy])
                  end
                end

                # * 進めなければその場で足踏み。反対を向く。
                m.facing = Vec.negate(m.facing)
                return Action.new(:rest, nil)
              end
            end
          end
        end
      else
        fail
      end
    end
  end

  def monster_attack(m, dir)
    @log.add("#{m.name}の こうげき！")
    if rand() < 0.125
      @log.add("#{@hero.name}は ひらりと身をかわした。")
    else
      attack = get_monster_attack(m)
      damage = ( ( attack * (15.0/16.0)**get_hero_defense ) * (112 + rand(32))/128.0 ).to_i
      take_damage(damage)
    end
  end

  def monster_move(m, mx, my, dir)
    #@log.add([m.name, m.object_id,  [mx, my], dir].inspect)
    @level.cell(mx, my).remove_object(m)
    @level.cell(mx + dir[0], my + dir[1]).put_object(m)
    m.facing = dir
  end

  def monster_phase
    doers = []
    @level.all_monsters_with_position.each do |m, mx, my|
      next if m.paralyzed?

      action = monster_action(m, mx, my)
      if action.type == :move
        # その場で動かす。
        monster_move(m, mx, my, action.direction)
      else
        doers << [m, action]
      end
    end

    doers.each do |m, action|
      case action.type
      when :attack
        monster_attack(m, action.direction)
      when :rest
        # 何もしない。
      else fail
      end
    end
  end

  def hero_fullness_decrease
    old = @hero.fullness
    if @hero.fullness > 0.0
      @hero.fullness -= @hero.hunger_per_turn
      if old >= 20.0 && @hero.fullness <= 20.0
        @log.add("おなかが 減ってきた。")
      elsif old >= 10.0 && @hero.fullness <= 10.0
        @log.add("空腹で ふらふらしてきた。")
      elsif @hero.fullness <= 0.0
        @log.add("早く何か食べないと死んでしまう！")
      end

      # 自然回復
      @hero.hp = [@hero.hp + @hero.hp/200.0, @hero.max_hp].min
    else
      @hero.hp -= 1
    end
  end

  # 64ターンに1回の敵湧き。
  def spawn_monster
    @dungeon.place_monster(@level, @level_number, @level.fov(@hero.x, @hero.y))
  end

  def current_room
    @level.room_at(@hero.x, @hero.y)
  end

  def wake_monsters_in_room(room, probability)
    if @hero.ring&.name == "盗賊の指輪"
      probability = 0.0
    end

    ((room.top+1)..(room.bottom-1)).each do |y|
      ((room.left+1)..(room.right-1)).each do |x|
        monster = @level.cell(x, y).monster
        if monster
          if monster.state == :asleep
            if rand() < probability
              monster.state = :awake
            end
          end
        end
      end
    end
  end

  def on_status_effect_expire(character, effect)
    case effect.type
    when :paralysis
      @log.add("#{character.name}の かなしばりがとけた。")
    when :sleep
      @log.add("#{character.name}は 目をさました。")
    else
      @log.add("#{character.name}の #{effect.type}状態がとけた。")
    end
  end

  def status_effects_wear_out
    monsters = @level.all_monsters_with_position.map { |m, x, y| m }

    (monsters + [@hero]).each  do |m|
      m.status_effects.each do |e|
        e.remaining_duration -= 1
      end
      m.status_effects.reject! do |e|
        (e.remaining_duration <= 0).tap do |expired|
          if expired
            on_status_effect_expire(m, e)
          end
        end
      end
    end

  end

  def main
    new_level

    @quitting = false

    # メインループ
    until @quitting
      # 視界
      rect = @level.fov(@hero.x, @hero.y)
      @level.mark_explored(rect)
      @level.light_up(rect)

      if @hero.hp < 1.0
        @log.add("#{@hero.name}は ちからつきた。")
        render
        sleep 1.5
        gameover_message
        break
      end

      #@log.add("#{@last_room.object_id} -> #{current_room.object_id}")
      if @last_room != current_room
        if @last_room
          wake_monsters_in_room(@last_room, 0.5)
        end
        if current_room
          if current_room == @level.party_room
            @log.add("魔物の巣窟だ！")
            wake_monsters_in_room(current_room, 1.0)
            @level.party_room = nil
          else
            wake_monsters_in_room(current_room, 0.5)
          end
        end
      end
      @last_room = current_room

      # 画面更新
      render

      if @hero.asleep?
        sleep 1
        @log.add("眠くて何もできない。")
        sym = :action
      else
        c = read_command
        @level.darken(@level.fov(@hero.x, @hero.y))
        sym = dispatch_command(c)
      end

      case sym
      when :action, :move
        monster_phase
        if @hero.hp >= 1.0 # 死んでなかった場合だけ？
          hero_fullness_decrease
        end

        status_effects_wear_out()

        @level.turn += 1

        if @level.turn % 64 == 0
          spawn_monster
        end
      when :nothing
      else fail
      end
    end
  end
end

Program.new.main
