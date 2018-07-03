require 'curses'
require_relative 'room'
require_relative 'level'
require_relative 'dungeon'
require_relative 'menu'
require_relative 'vec'
require_relative 'charlevel'
require_relative 'curses_ext'

class MessageLog
  attr_reader :message, :updated_at

  def initialize
    @lines = []
    @updated_at = Time.now
  end

  def add(msg)
    @lines << msg
    while @lines.size > 10
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

  DIRECTIONS = [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]]

  def initialize
    @debug = ARGV.include?("-d")

    Curses.init_screen
    Curses.noecho
    Curses.crmode
    Curses.stdscr.keypad(true)
    at_exit {
      Curses.close_screen
    }
    @hero = Hero.new(0, 0, 15, 15, 8, 8, 0, 0, 100.0, 100.0, 1)
    @hero.inventory << Item.make_item("大きなパン")
    if debug?
      @hero.inventory << Item.make_item("エクスカリバー")
      @hero.inventory << Item.make_item("メタルヨテイチの盾")
      @hero.inventory << Item.make_item("目薬草")
      @hero.inventory << Item.make_item("薬草")
      @hero.inventory << Item.make_item("薬草")
      @hero.inventory << Item.make_item("高級薬草")
      @hero.inventory << Item.make_item("高級薬草")
      @hero.inventory << Item.make_item("毒けし草")
      @hero.inventory << Item.make_item("あかりの巻物")
      @hero.inventory << Item.make_item("あかりの巻物")
      @hero.inventory << Item.make_item("結界の巻物")
    end
    @level_number = 0
    @dungeon = Dungeon.new
    @log = MessageLog.new

    @last_room = nil
  end

  def debug?
    @debug
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

  def get_hero_projectile_attack(projectile_strength)
    basic = lv_to_attack(exp_to_lv(@hero.exp))
    (basic + basic * (projectile_strength - 8)/16.0).round
  end

  def get_monster_attack(m)
    m.strength
  end

  def get_hero_defense
    @hero.shield ? @hero.shield.number : 0
  end

  def monster_take_damage(monster, damage, cell)
    monster.hp -= damage
    @log.add("#{monster.name}に #{damage} のダメージを与えた。")
    if monster.hp >= 1.0 && # 生きている
       monster.divide? &&
       rand() < 0.5
      x, y = @level.coordinates_of(monster)
      monster_split(monster, cell, x, y)
    end
    check_monster_dead(cell, monster)
  end

  def hero_attack(cell, monster)
    on_monster_attacked(monster)
    if rand() < 0.125
      @log.add("#{@hero.name}の 攻撃は外れた。")
    else
      attack = get_hero_attack
      damage = ( ( attack * (15.0/16.0)**monster.defense ) * (112 + rand(32))/128.0 ).to_i
      if monster.name == "メタルヨテイチ"
        damage = [damage, 1].min
      elsif monster.name == "竜" && @hero.weapon&.name == "ドラゴンキラー"
        damage *= 2
      end
      monster_take_damage(monster, damage, cell)
    end
  end

  def check_monster_dead(cell, monster)
    if monster.hp < 1.0
      monster.invisible = false

      cell.remove_object(monster)

      if monster.item
        thing = monster.item
      elsif rand() < monster.drop_rate && cell.can_place?
        thing = @dungeon.make_random_item_or_gold(@level_number)
      else
        thing = nil
      end

      if thing
        x, y = @level.coordinates_of_cell(cell)
        item_land(thing, x, y)
      end

      @hero.exp += monster.exp
      @log.add("#{monster.name}を たおして #{monster.exp} ポイントの経験値を得た。")
      check_level_up

      @hero.status_effects.reject! { |e|
        if e.caster.equal?(monster)
          on_status_effect_expire(@hero, e)
          true
        else
          false
        end
      }
    end
  end

  KEY_TO_DIRVEC = {
    'h' => [-1,  0],
    'j' => [ 0, +1],
    'k' => [ 0, -1],
    'l' => [+1,  0],
    'y' => [-1, -1],
    'u' => [+1, -1],
    'b' => [-1, +1],
    'n' => [+1, +1],

    'H' => [-1,  0],
    'J' => [ 0, +1],
    'K' => [ 0, -1],
    'L' => [+1,  0],
    'Y' => [-1, -1],
    'U' => [+1, -1],
    'B' => [-1, +1],
    'N' => [+1, +1],

    Curses::KEY_LEFT => [-1, 0],
    Curses::KEY_RIGHT => [+1, 0],
    Curses::KEY_UP => [0, -1],
    Curses::KEY_DOWN => [0, +1],
  }

  # String → :move
  def hero_move(c)
    vec = KEY_TO_DIRVEC[c]
    fail ArgumentError unless vec

    picking = !%w[H J K L Y U B N].include?(c)

    if @hero.confused?
      vec = DIRECTIONS.sample
    end

    dx, dy = vec
    if dx * dy != 0
      allowed = @level.passable?(@hero, @hero.x + dx, @hero.y + dy) &&
                @level.uncornered?(@hero, @hero.x + dx, @hero.y) &&
                @level.uncornered?(@hero, @hero.x, @hero.y + dy)
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
      if @hero.held?
        @log.add("その場に とらえられて 動けない！")
        return :action
      end

      @hero.x = x1
      @hero.y = y1

      gold = cell.gold
      if gold
        if picking
          cell.remove_object(gold)
          @hero.gold += gold.amount
          @log.add("#{gold.amount}G を拾った。")
        else
          @log.add("#{gold.amount}G の上に乗った。")
        end
      end

      item = cell.item
      if item
        if picking
          pick(cell, item)
        else
          @log.add("#{item.name}の上に乗った。")
        end
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
    if @hero.inventory.any? { |x| x.name == "転ばぬ先の杖" }
      @log.add("しかし 対したことはなかった。")
      return
    end

    count = 0
    candidates = @hero.inventory.reject { |x| @hero.equipped?(x) }
    candidates.shuffle!
    [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]].each do |dx, dy|
      break if candidates.empty?
      x, y = @hero.x + dx, @hero.y + dy
      if @level.in_dungeon?(x, y) &&
         @level.cell(x, y).can_place?
        item = candidates.shift
        @level.put_object(item, x, y)
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
      unless @hero.held?
        @hero.status_effects << StatusEffect.new(:held, 10)
      end
    when "眠りガス"
      @log.add("足元から 霧が出ている！")
      hero_fall_asleep()
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
      mine_activate(trap)
    when "落とし穴"
      @log.add("落とし穴だ！")
      new_level(+1)
      return # ワナ破損処理をスキップする
    else fail
    end

    tx, ty = @level.coordinates_of(trap)
    if rand() < 0.5
      @level.remove_object(trap, tx, ty)
    end
  end

  def mine_activate(mine)
    take_damage((@hero.hp / 2.0).ceil)

    tx, ty = @level.coordinates_of(mine)
    rect = @level.surroundings(tx, ty)
    rect.each_coords do |x, y|
      if @level.in_dungeon?(x, y)
        cell = @level.cell(x, y)
        if cell.monster
          cell.remove_object(cell.monster)
        end
        if cell.item
          cell.remove_object(cell.item)
        end
      end
    end
  end

  def need_inventory_slot?(item)
    @hero.inventory.none? { |x| item.type == x.type && item.name == x.name }
  end

  # ヒーロー @hero が配列 objects の要素 item を拾おうとする。
  def pick(cell, item)
    if need_inventory_slot?(item) && @hero.inventory.size >= 20
      @log.add("持ち物が いっぱいで #{item.name}が 拾えない。")
    end

    if item.stuck
      @log.add("#{item.name}は 床にはりついて 拾えない。")
    else
      cell.remove_object(item)
      @hero.add_to_inventory(item)
      update_stairs_direction
      @log.add("#{@hero.name}は #{item.to_s}を 拾った。")
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
      return go_downstairs()
    elsif cell.item
      pick(cell, cell.item)
      return :action
    elsif cell.trap
      trap_activate(cell.trap)
      return :action
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
    when '!'
      if debug?
        require 'pry'
        Curses.close_screen
        self.pry
        Curses.refresh
      end
      :nothing
    when '\\'
      if debug?
        hero_levels_up
      end
      :nothing
    when ']'
      if debug?
        cheat_go_downstairs
      else
        :nothing
      end
    when '['
      if debug?
        cheat_go_upstairs
      else
        :nothing
      end
    when '?'
      help
    when 'h','j','k','l','y','u','b','n',
         'H','J','K','L','Y','U','B','N',
         Curses::KEY_LEFT, Curses::KEY_RIGHT, Curses::KEY_UP, Curses::KEY_DOWN
      hero_move(c)
    when 'i'
      open_inventory
    when '>'
      activate_underfoot
    when 'q'
      @log.add("ゲームを終了するには大文字の Q を押してね。")
      :nothing
    when 'Q'
      set_quitting
    when 's'
      status_window
      :nothing
    when 't'
      if @hero.projectile
        throw_item(@hero.projectile)
        :action
      else
        @log.add("投げ物を装備していない。")
        :nothing
      end
    when '.'
      search
    else
      @log.add("[#{c}]なんて 知らない。[?]でヘルプ。")
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
     [Shift] 移動時にアイテムを拾わない。
     i       道具一覧を開く。
     >       階段を降りる。
             足元のワナを踏む。
             足元のアイテムを拾う。
     ,       足元を調べる。
     .       周りを調べる。
     ?       このヘルプを表示。
     q       キャンセル。
     Q       ゲームを終了する。
EOD

    win = Curses::Window.new(21, 50, 2, 4) # lines, cols, y, x
    win.clear
    win.rounded_box
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
    win.rounded_box
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
      if item.name == "結界の巻物"
        item.stuck = true
      end
      @level.put_object(item, @hero.x, @hero.y)
      update_stairs_direction
      @log.add("#{item}を 置いた。")
    else
      @log.add("ここには 置けない。")
    end
  end

  # () → :action | :nothing
  def open_inventory
    dispfunc = proc { |item|
      prefix = if @hero.weapon.equal?(item) ||
                @hero.shield.equal?(item) ||
                @hero.ring.equal?(item) ||
                @hero.projectile.equal?(item)
               "E"
             else
               " "
             end
      "#{prefix}#{item.char}#{item.to_s}"
    }

    menu = nil
    item = c = nil

    loop do
      item = c = nil
      menu = Menu.new(@hero.inventory,
                      y: 1, x: 0, cols: 27,
                      dispfunc: dispfunc,
                      title: "持ち物 [s]ソート",
                      sortable: true)
      command, *args = menu.choose

      case command
      when :cancel
        #Curses.beep
        return :nothing
      when :chosen
        item, = args

        action_menu = Menu.new(actions_for_item(item), y: 1, x: 27, cols: 9)
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
      when :sort
        @hero.inventory = @hero.inventory.map.with_index.sort { |(a, i),(b, j)|
          [a.sort_priority, i] <=> [b.sort_priority, j]
        }.map(&:first)
      end

      break if item and c
    end

    case c
    when "置く"
      try_place_item(item)
    when "投げる"
      throw_item(item)
    when "食べる"
      eat_food(item)
    when "飲む"
      take_herb(item)
    when "装備"
      equip(item)
    when "読む"
      read_scroll(item)
    when "ふる"
      zap_staff(item)
    else
      @log.add("case not covered: #{item}を#{c}。")
    end
    return :action
  ensure
    menu.close
  end

  # アイテム落下則
  # 20 18 16 17 19
  # 13  6  4  5 12
  # 11  3  1  2 10
  # 15  9  7  8 14
  # 25 23 21 22 24

  LAND_POSITIONS = [
    [0,0], [1,0], [-1,0],
    [0,-1], [1,-1], [-1,-1],
    [0,1], [1,1], [-1,1],
    [2,0], [-2,0],
    [2,-1], [-2,-1],
    [2,1], [-2,1],
    [0,-2], [1,-2], [-1,-2], [2,-2], [-2,-2],
    [0,2], [1,2], [-1,2], [2,2], [-2,2]
  ]

  # 以下の位置(10~25)に落ちるためには、
  # 別の位置(2~9のいずれか)が床でなければならない。
  LAND_DEPENDENT_POSITION = {
    [2,0]   => [1,0],
    [-2,0]  => [-1,0],
    [2,-1]  => [1,-1],
    [-2,-1] => [-1,-1],
    [2,1]   => [1,1],
    [-2,1]  => [-1,1],
    [0,-2]  => [0,-1],
    [1,-2]  => [1,-1],
    [-1,-2] => [-1,-1],
    [2,-2]  => [1,-1],
    [-2,-2] => [-1,-1],
    [0,2]   => [0,1],
    [1,2]   => [1,1],
    [-1,2]  => [-1,1],
    [2,2]   => [1,1],
    [-2,2]  => [-1,1]
  }


  # 投げられたアイテムが着地する。
  def item_land(item, x, y)
    cell = @level.cell(x, y)

    if cell.trap && !cell.trap.visible
      cell.trap.visible = true
    end

    LAND_POSITIONS.each do |dx, dy|
      if LAND_DEPENDENT_POSITION[[dx,dy]]
        dx2, dy2 = LAND_DEPENDENT_POSITION[[dx,dy]]
        unless (@level.in_dungeon?(x+dx2, y+dy2) &&
                (@level.cell(x+dx2, y+dy2).type == :FLOOR || 
                 @level.cell(x+dx2, y+dy2).type == :PASSAGE))
          next
        end
      end
      if (@level.in_dungeon?(x+dx, y+dy) &&
          @level.cell(x+dx, y+dy).can_place?)

        @level.cell(x+dx, y+dy).put_object(item)
        if item.name == "結界の巻物"
          item.stuck = true
        end
        @log.add("#{item}は 床に落ちた。")
        return
      end
    end
    @log.add("#{item}は消えてしまった。")
  end

  def herb_hits_monster(item, monster, cell)
    on_monster_attacked(monster)

    case item.name
    when "火炎草"
      monster_take_damage(monster, rand(30...40), cell)
    when "睡眠草"
      monster_fall_asleep(monster)
    when "ワープ草"
      monster_teleport(monster, cell)
    when "薬草"
      if monster.undead?
        monster_take_damage(monster, 25, cell)
      else
        @log.add("しかし 何も 起こらなかった。")
      end
    when "高級薬草"
      if monster.undead?
        monster_take_damage(monster, 100, cell)
      else
        @log.add("しかし 何も 起こらなかった。")
      end
    when "毒けし草"
      if monster.poisonous?
        monster_take_damage(monster, 50, cell)
      else
        @log.add("しかし 何も 起こらなかった。")
      end
    else
      @log.add("しかし 何も 起こらなかった。")
    end
  end

  def staff_hits_monster(item, monster, cell)
    mx, my = [nil, nil]
    @level.all_monsters_with_position.each do |m, x, y|
      if m.equal?(monster)
        mx, my = x, y
      end
    end

    fail if mx.nil?
    magic_bullet_hits_monster(item, monster, cell, mx, my)
  end

  def shield_hits_monster(item, monster, cell)
    on_monster_attacked(monster)
    damage = item.number
    monster.hp -= damage
    @log.add("#{monster.name}に #{damage} のダメージを与えた。")
    check_monster_dead(cell, monster)
  end

  def weapon_hits_monster(item, monster, cell)
    on_monster_attacked(monster)
    damage = item.number
    monster.hp -= damage
    @log.add("#{monster.name}に #{damage} のダメージを与えた。")
    check_monster_dead(cell, monster)
  end

  def projectile_hits_monster(item, monster, cell)
    on_monster_attacked(monster)
    attack = get_hero_projectile_attack(item.projectile_strength)
    damage = ( (attack * (15.0/16.0)**monster.defense) * (112 + rand(32))/128.0 ).to_i
    monster.hp -= damage
    @log.add("#{monster.name}に #{damage} のダメージを与えた。")
    check_monster_dead(cell, monster)
  end

  def item_hits_monster(item, monster, cell)
    @log.add("#{item}は #{monster.name}に当たった。")
    case item.type
    when :box, :food, :scroll, :ring
      on_monster_attacked(monster)
      damage = 1 + rand(1)
      monster.hp -= damage
      @log.add("#{monster.name}に #{damage} のダメージを与えた。")
      check_monster_dead(cell, monster)
    when :herb
      herb_hits_monster(item, monster, cell)
    when :staff
      staff_hits_monster(item, monster, cell)
    when :shield 
      shield_hits_monster(item, monster, cell)
    when :weapon
      weapon_hits_monster(item, monster, cell)
    when :projectile
      projectile_hits_monster(item, monster, cell)
    else
      fail "case not covered"
    end
  end

  def item_hits_hero(item, monster)
    @log.add("#{item.name}が #{@hero.name}に当たった。")
    if item.type == :projectile
      take_damage(attack_to_hero_damage(item.projectile_strength))
    elsif item.type == :weapon || item.type == :shield
      take_damage(attack_to_hero_damage(item.number))
    else
      take_damage(attack_to_hero_damage(1))
    end
  end

  def monster_throw_item(monster, item, mx, my, dir)
    dx, dy = dir
    x, y = mx, my

    while true
      fail unless @level.in_dungeon?(x+dx, y+dy)

      cell = @level.cell(x+dx, y+dy)
      case cell.type
      when :WALL, :HORIZONTAL_WALL, :VERTICAL_WALL, :STATUE
        item_land(item, x, y)
        break
      when :FLOOR, :PASSAGE
        if [x+dx, y+dy] == [@hero.x, @hero.y]
          if rand() < 0.125
            item_land(item, x+dx, y+dy)
          else
            item_hits_hero(item, monster)
          end
          break
        elsif cell.monster
          # FIXME: これだと主人公に経験値が入ってしまうな
          if rand() < 0.125
            item_land(item, x+dx, y+dy)
          else
            item_hits_monster(item, cell.monster, cell)
          end
          break
        end
      else
        fail "case not covered"
      end
      x, y = x+dx, y+dy
    end
  end

  def breath_of_fire(monster, mx, my, dir)
    dx, dy = dir
    x, y = mx, my

    while true
      fail unless @level.in_dungeon?(x+dx, y+dy)

      cell = @level.cell(x+dx, y+dy)
      case cell.type
      when :WALL, :HORIZONTAL_WALL, :VERTICAL_WALL, :STATUE
        break
      when :FLOOR, :PASSAGE
        if [x+dx, y+dy] == [@hero.x, @hero.y]
          take_damage(rand(17..23))
          break
        elsif cell.monster
          # FIXME: これだと主人公に経験値が入ってしまうな
          monster_take_damage(cell.monster, rand(17..23), cell)
          break
        end
      else
        fail "case not covered"
      end
      x, y = x+dx, y+dy
    end
  end

  # (Item, Array)
  def do_throw_item(item, dir)
    dx, dy = dir
    x, y = @hero.x, @hero.y

    while true
      fail unless @level.in_dungeon?(x+dx, y+dy)

      cell = @level.cell(x+dx, y+dy)
      case cell.type
      when :WALL, :HORIZONTAL_WALL, :VERTICAL_WALL, :STATUE
        item_land(item, x, y)
        break
      when :FLOOR, :PASSAGE
        if cell.monster
          if rand() < 0.125
            item_land(item, x+dx, y+dy)
          else
            item_hits_monster(item, cell.monster, cell)
          end
          break
        end
      else
        fail "case not covered"
      end
      x, y = x+dx, y+dy
    end
  end

  def ask_direction
    text = <<EOD
y k u
h   l
b j n
EOD
    win = Curses::Window.new(5, 7, 5, 33) # lines, cols, y, x
    win.clear
    win.rounded_box
    win.setpos(0, 1)
    win.addstr("方向")
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    win.setpos(2, 3)
    while true
      c = win.getch
      if KEY_TO_DIRVEC[c]
        return KEY_TO_DIRVEC[c]
      end
    end
    
  ensure
    win&.close
  end
  
  def throw_item(item)
    dir = ask_direction()
    if item.type == :projectile && item.number > 1
      one = Item.make_item(item.name)
      one.number = 1
      item.number -= 1
      do_throw_item(one, dir)
    else
      @hero.remove_from_inventory(item)
      do_throw_item(item, dir)
    end
  end

  def zap_staff(item)
    fail if item.type != :staff

    dir = ask_direction()
    if item.number == 0
      @log.add("しかしなにも起こらなかった。")
    elsif item.number > 0
      item.number -= 1
      do_zap_staff(item, dir)
    else
      fail "negative staff number"
    end
  end

  def monster_fall_asleep(monster)
    unless monster.asleep?
      monster.status_effects.push(StatusEffect.new(:sleep, 5))
      @log.add("#{monster.name}は 眠りに落ちた。")
    end
  end

  def monster_teleport(monster, cell)
    x, y = @level.get_random_place(:FLOOR)
    until !@level.cell(x, y).monster && !(x==@hero.x && y==@hero.y)
      x, y = @level.get_random_place(:FLOOR)
    end
    cell.remove_object(monster)
    @level.put_object(monster, x, y)
  end

  def monster_metamorphose(monster, cell, x, y)
    m = Monster.make_monster(Monster::SPECIES.sample[1])
    m.state = :awake
    cell.remove_object(monster)
    @level.put_object(m, x, y)
  end

  def monster_split(monster, cell, x, y)
    m = Monster.make_monster(monster.name)
    m.state = :awake
    rect = @level.surroundings(x, y)
    placed = false
    rect.each_coords do |x, y|
      cell = @level.cell(x, y)
      if (cell.type == :PASSAGE || cell.type == :FLOOR) &&
         !cell.monster &&
         !(x==@hero.x && y==@hero.y)
        @level.put_object(m, x, y)
        placed = true
        break
      end
    end
    if placed
      @log.add("#{monster.name}は 分裂した！")
    else
      @log.add("しかし 何も 起こらなかった。")
    end
  end

  def magic_bullet_hits_monster(staff, monster, cell, x, y)
    on_monster_attacked(monster)
    case staff.name
    when "いかずちの杖"
      monster_take_damage(monster, rand(18...22), cell)
    when "睡眠の杖"
      monster_fall_asleep(monster)
    when "ワープの杖"
      monster_teleport(monster, cell)
    when "変化の杖"
      monster_metamorphose(monster, cell, x, y)
    when "転ばぬ先の杖"
      @log.add("しかし 何も起こらなかった。")
    when "分裂の杖"
      monster_split(monster, cell, x, y)
    when "もろ刃の杖"
      monster.hp = 1
      @hero.hp = @hero.hp - (@hero.hp / 2.0).ceil
      @log.add("#{monster.name}の HP が 1 になった。")
    else
      fail "case not covered"
    end
  end

  def do_zap_staff(staff, dir)
    dx, dy = dir
    x, y = @hero.x, @hero.y

    while true
      fail unless @level.in_dungeon?(x+dx, y+dy)

      cell = @level.cell(x+dx, y+dy)
      case cell.type
      when :WALL, :HORIZONTAL_WALL, :VERTICAL_WALL
        @log.add("魔法弾は壁に当たって消えた。")
        break
      when :FLOOR, :PASSAGE
        if cell.monster
          magic_bullet_hits_monster(staff, cell.monster, cell, x+dx, y+dy)
          break
        end
      else
        fail "case not covered"
      end
      x, y = x+dx, y+dy
    end
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
    when "あかりの巻物"
      @level.whole_level_lit = true
      @log.add("ダンジョンが あかるくなった。")
    when "武器強化の巻物"
      if @hero.weapon
        @hero.weapon.number += 1
        @log.add("#{@hero.weapon.name}が 少し強くなった。")
      else
        @log.add("しかし 何も起こらなかった。")
      end
    when "盾強化の巻物"
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
    when "結界の巻物"
      @log.add("何も起こらなかった。足元に置いて使うようだ。")
    when "やりなおしの巻物"
      if @dungeon.on_return_trip?(@hero)
        @log.add("帰り道では 使えない。")
      elsif @level_number <= 1
        @log.add("しかし何も起こらなかった。")
      else
        @log.add("不思議なちからで 1階 に引き戻された！")
        new_level(1 - @level_number)
      end
    when "爆発の巻物"
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
    when "高級薬草"
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
      hero_levels_up
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
    when "睡眠草"
      unless @hero.asleep?
        hero_fall_asleep
      end
    when "ワープ草"
      hero_teleport
      @log.add("#{@hero.name}は ワープした。")
    when "火炎草"
      @log.add("こいつは HOT だ！")
    else
      fail "uncoverd case: #{item}"
    end
  end

  def hero_levels_up
    required_exp = lv_to_exp(@hero.lv + 1)
    if required_exp
      @hero.exp = required_exp
      check_level_up
    else
      @log.add("しかし 何も起こらなかった。")
    end
  end

  def hero_levels_down
    if @hero.lv == 1
      @log.add("しかし 何も起こらなかった。")
    else
      exp = lv_to_exp(@hero.lv) - 1
      @hero.lv = @hero.lv - 1
      @hero.exp = exp
      @hero.max_hp = [@hero.max_hp - 5, 1].max
      @hero.hp = [@hero.hp, @hero.max_hp].min
      @log.add("#{@hero.name}の レベルが下がった。")
    end
  end

  def hero_fall_asleep
    if @hero.sleep_resistent?
      @log.add("しかし なんともなかった。")
    else
      @hero.status_effects.push(StatusEffect.new(:sleep, 5))
      @log.add("#{@hero.name}は 眠りに落ちた。")
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
    when :projectile
      equip_projectile(item)
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

  def equip_projectile(item)
    if @hero.projectile.equal?(item)
      @hero.projectile = nil
      @log.add("#{item.name}を 外した。")
    else
      @hero.projectile = item
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
    return if @hero.poison_resistent?

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

      # 状態異常のクリア
      @hero.status_effects.clear

      # 主人公を配置する。
      @hero.x, @hero.y = @level.get_random_character_placeable_place

      x, y = [@hero.x, @hero.y]
      if @level.has_type_at?(Item, x, y) ||
         @level.has_type_at?(StairCase, x, y) ||
         @level.has_type_at?(Trap, x, y)
        @log.add("足元になにかある。")
      end

      update_stairs_direction
    end
  end

  def flushinp
    Curses.timeout = 0
    nil until Curses.getch == nil
  end

  def read_command
    flushinp
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
    line = "%dF  Lv %d  HP %d/%d  %dG  満腹度 %d%% %s [%04d]" %
           [@level_number,
            @hero.lv,
            @hero.hp, @hero.max_hp,
            @hero.gold,
            @hero.fullness.ceil,
            @hero.status_effects.map(&:name).join(' '),
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
    win.rounded_box
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    flushinp
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
           "  武器 %s\n" % [@hero.weapon || "なし"] +
           "    盾 %s\n" % [@hero.shield || "なし"] +
           "  指輪 %s\n" % [@hero.ring || "なし"] +
           "ちから %d/%d\n" % [@hero.strength, @hero.max_strength] +
           "経験値 %d\n" % [@hero.exp] +
           "つぎのLvまで %d\n" % [exp_until_next_lv || "∞"] +
           "満腹度 %d%%/%d%%\n" % [@hero.fullness.ceil, @hero.max_fullness]

    win = Curses::Window.new(9+2, 30, 1, 0) # lines, cols, y, x
    win.clear
    win.rounded_box
    win.setpos(0, 1)
    win.addstr(@hero.name)
    text.each_line.with_index(1) do |line, y|
      win.setpos(y, 1)
      win.addstr(line.chomp)
    end
    win.getch
    win.close
  end

  def aligned?(v1, v2)
    diff = Vec.minus(v1, v2)
    return diff[0].zero? ||
           diff[1].zero? ||
           diff[0].abs == diff[1].abs
  end

  def trick_in_range?(m, mx, my)
    case m.trick_range
    when :none
      return false
    when :sight
      return @level.fov(mx, my).include?(@hero.x, @hero.y)
    when :line
      return @level.fov(mx, my).include?(@hero.x, @hero.y) &&
        aligned?([mx, my], [@hero.x, @hero.y])
    when :reach
      return @level.can_attack?(m, mx, my, @hero.x, @hero.y)
    else
      fail
    end
  end

  def trick_applicable?(m)
    mx, my = @level.coordinates_of(m)
    return trick_in_range?(m, mx, my) &&
           case m.name
           when "目玉"
             !@hero.confused?
           when "白い手"
             !@hero.held?
           when "どろぼう猫"
             m.item.nil?
           else
             true
           end
  end

  # (Monster, Integer, Integer) → Action
  def monster_move_action(m, mx, my)
    # 動けない。
    if m.held?
      return Action.new(:rest, nil)
    end

    # * モンスターの視界内にヒーローが居れば目的地を再設定。
    if !m.hallucinating? && @level.fov(mx, my).include?(@hero.x, @hero.y)
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
      i = DIRECTIONS.index(dir)
      [i, *[i - 1, i + 1].shuffle, *[i - 2, i + 2].shuffle].map { |j|
        DIRECTIONS[j % 8]
      }.each do |dx, dy|
        if @level.can_move_to?(m, mx, my, mx+dx, my+dy) &&
           @level.cell(mx+dx, my+dy).item&.name != "結界の巻物"
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
        if @level.can_move_to?(m, mx, my, tx, ty) &&
           @level.cell(tx, ty).item&.name != "結界の巻物"
          return Action.new(:move, m.facing)
        else
          # * 進めなければ反対以外の方向に進もうとする。
          #   通路を曲がるには ±90度で十分か。
          dirs = [
            Vec.rotate_clockwise_45(m.facing, +2),
            Vec.rotate_clockwise_45(m.facing, -2),
            Vec.rotate_clockwise_45(m.facing, +1),
            Vec.rotate_clockwise_45(m.facing, -1),
          ].shuffle
          dirs.each do |dx, dy|
            if @level.can_move_to?(m, mx, my, mx+dx, my+dy) &&
               @level.cell(mx+dx, my+dy).item&.name != "結界の巻物"
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

  # (Monster, Integer, Integer) → Action
  def monster_tipsy_move_action(m, mx, my)
    candidates = []
    rect = @level.surroundings(mx, my)
    rect.each_coords do |x, y|
      next unless @level.in_dungeon?(x, y) &&
                  (@level.cell(x, y).type == :FLOOR ||
                   @level.cell(x, y).type == :PASSAGE)
      if [x,y] != [@hero.x,@hero.y] &&
         @level.can_move_to?(m, mx, my, x, y) &&
         @level.cell(x, y).item&.name != "結界の巻物"
        candidates << [x, y]
      end
    end
    if candidates.any?
      x, y = candidates.sample
      return Action.new(:move, [x - mx, y - my])
    else
      return Action.new(:rest, nil)
    end
  end

  def adjacent?(v1, v2)
    return Vec.chess_distance(v1, v2) == 1
  end

  # (Monster, Integer, Integer) → Action
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

        # ちどり足。
        if m.tipsy? && rand() < 0.5
          return monster_tipsy_move_action(m, mx, my)
        elsif adjacent?([mx, my], [@hero.x, @hero.y]) &&
              @level.cell(@hero.x, @hero.y).item&.name == "結界の巻物"
          return monster_move_action(m, mx, my) # Action.new(:rest, nil)
        elsif trick_applicable?(m) && rand() < m.trick_rate
          return Action.new(:trick, nil)
        elsif @level.can_attack?(m, mx, my, @hero.x, @hero.y)
          # * ヒーローに隣接していればヒーローに攻撃。
          if m.name == "動くモアイ像"
            m.status_effects.reject! { |x| x.type == :held }
          end
          return Action.new(:attack, Vec.minus([@hero.x, @hero.y], [mx, my]))
        else
          return monster_move_action(m, mx, my)
        end
      else
        fail
      end
    end
  end

  def attack_to_hero_damage(attack)
    return ( ( attack * (15.0/16.0)**get_hero_defense ) * (112 + rand(32))/128.0 ).to_i
  end

  def monster_attack(m, dir)
    attack = get_monster_attack(m)

    if attack == 0
      @log.add("#{m.name}は 様子を見ている。")
    else
      @log.add("#{m.name}の こうげき！")
      if rand() < 0.125
        @log.add("#{@hero.name}は ひらりと身をかわした。")
      else
        damage = attack_to_hero_damage(attack)
        take_damage(damage)
      end
    end
  end

  def monster_trick(m)
    case m.name
    when '催眠術師'
      @log.add("#{m.name}は 手に持っている物を 揺り動かした。")
      monster_fall_asleep(@hero)
    when 'ファンガス'
      @log.add("#{m.name}は 毒のこなを 撒き散らした。")
      take_damage_strength(1)
    when 'ノーム'
      potential = rand(250..1500)
      actual = [potential, @hero.gold].min
      if actual == 0
        @log.add("#{@hero.name}は お金を持っていない！")
      else
        @log.add("#{m.name}は #{actual}ゴールドを盗んでワープした！")
        @hero.gold -= actual
        m.item = Gold.new(m.item.amount + actual)

        unless m.hallucinating?
          m.status_effects << StatusEffect.new(:hallucination, Float::INFINITY)
        end

        mx, my = @level.coordinates_of(m)
        @level.remove_object(m, mx, my)
        x,y = @level.get_random_character_placeable_place
        @level.put_object(m, x, y)
      end
    when "白い手"
      if !@hero.held?
        @log.add("#{m.name}は #{@hero.name}の足をつかんだ！")
        effect = StatusEffect.new(:held, 10)
        effect.caster = m
        @hero.status_effects << effect
      end

    when "ピューシャン"
      mx, my = @level.coordinates_of(m)
      dir = Vec.normalize(Vec.minus([@hero.x, @hero.y], [mx, my]))
      arrow = Item.make_item("木の矢")
      arrow.number = 1
      monster_throw_item(m, arrow, mx, my, dir)

    when "アクアター"
      @log.add("#{m.name}は 酸を浴せた。")
      if @hero.shield
        take_damage_shield
      end

    when "パペット"
      hero_levels_down

    when "土偶"
      if rand() < 0.5
        take_damage_max_strength(1)
      else
        take_damage_max_hp(5)
      end

    when "目玉"
      unless @hero.confused?
        @hero.status_effects.push(StatusEffect.new(:confused, 10))
        @log.add("#{@hero.name}は 混乱した。")
      end

    when "どろぼう猫"
      candidates = @hero.inventory.reject { |x| @hero.equipped?(x) }
      item = candidates.sample
      @hero.remove_from_inventory(item)
      m.item = item
      @log.add("#{m.name}は #{item.name}を盗んでワープした。")

      unless m.hallucinating?
        m.status_effects << StatusEffect.new(:hallucination, Float::INFINITY)
      end

      mx, my = @level.coordinates_of(m)
      @level.remove_object(m, mx, my)
      x,y = @level.get_random_character_placeable_place
      @level.put_object(m, x, y)

    when "竜"
      mx, my = @level.coordinates_of(m)
      dir = Vec.normalize(Vec.minus([@hero.x, @hero.y], [mx, my]))
      @log.add("#{m.name}は 火を吐いた。")
      breath_of_fire(m, mx, my, dir)

    when "ソーサラー"
      @log.add("#{m.name}は ワープの杖を振った。")
      hero_teleport

    else
      fail
    end
  end

  def take_damage_max_strength(amount)
    fail unless amount == 1
    if @hero.max_strength <= 1
      @log.add("#{@hero.name}の ちからは これ以上さがらない。")
    else
      @hero.max_strength -= 1
      @hero.strength = [@hero.strength, @hero.max_strength].min
      @log.add("#{@hero.name}の ちからの最大値が 下がった。")
    end
  end

  def take_damage_max_hp(amount)
    @hero.max_hp = [@hero.max_hp - amount, 1].max
    @hero.hp = [@hero.hp, @hero.max_hp].min
    @log.add("#{@hero.name}の 最大HPが 減った。")
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
      next if m.asleep?

      action = monster_action(m, mx, my)
      if action.type == :move
        # その場で動かす。
        monster_move(m, mx, my, action.direction)
      else
        doers << [m, action]
      end
    end

    doers.each do |m, action|
      dispatch_action(m, action)
    end

    # 2倍速モンスター行動
    doers2 = []
    @level.all_monsters_with_position.each do |m, mx, my|
      next unless m.double_speed?
      next if m.paralyzed?
      next if m.asleep?

      action = monster_action(m, mx, my)
      if action.type == :move
        # その場で動かす。
        monster_move(m, mx, my, action.direction)
      else
        doers2 << [m, action]
      end
    end

    doers2.each do |m, action|
      next if m.single_attack? && doers.any? { |n, _action| m.equal?(n) }

      dispatch_action(m, action)
    end
  end

  # :move 以外のアクションを実行。
  def dispatch_action(m, action)
    case action.type
    when :attack
      monster_attack(m, action.direction)
    when :trick
      monster_trick(m)
    when :rest
    # 何もしない。
    else fail
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
      @hero.hp = [@hero.hp + @hero.hp/150.0, @hero.max_hp].min
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
    when :held
      @log.add("#{character.name}の 足が抜けた。")
    when :confused
      @log.add("#{character.name}の 混乱がとけた。")
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

  def naming_screen
    require_relative 'naming_screen'

    # 背景画面をクリア
    Curses.stdscr.clear
    Curses.stdscr.refresh

    name = NamingScreen.run
    @hero.name = name
    main
  end

  def initial_menu
    menu = Menu.new([
                      "冒険に出る",
                      # "番付"
                    ], y: 0, x: 0, cols: 14)
    cmd, *args = menu.choose
    case cmd
    when :cancel
      return
    when :chosen
      item, = args
      case item
      when "冒険に出る"
        naming_screen
      when "番付"
        # naiyo
      else
        fail item
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

Program.new.initial_menu
