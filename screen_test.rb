require 'json'
require 'curses'
require_relative 'room'
require_relative 'level'
require_relative 'dungeon'
require_relative 'menu'
require_relative 'vec'
require_relative 'charlevel'
require_relative 'curses_ext'
require_relative 'result_screen'
require_relative 'naming_screen'
require_relative 'shop'
require_relative 'history_window'
require_relative 'naming_table'
require_relative 'sound'

class HeroDied < Exception
end

class MessageLog
  attr_reader :lines
  attr_reader :history

  HISTORY_SIZE = 2000

  def initialize
    @lines = []
    @history = []
  end

  def add(msg)
    @lines << msg
    until @history.size < 2000
      @history.shift
    end
    @history << msg
  end

  def clear
    @lines.clear
  end

end

class Action
  attr :type, :direction
  def initialize(type, direction)
    @type = type
    @direction = direction
  end
end

class Program
  include CharacterLevel

  DIRECTIONS = [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]]
  SCORE_RANKING_FILE_NAME = "ranking-score.json"
  TIME_RANKING_FILE_NAME = "ranking-time.json"
  RECENT_GAMES_FILE_NAME = "ranking-recent.json"

  HEALTH_BAR_COLOR_PAIR = 1
  UNIDENTIFIED_ITEM_COLOR_PAIR = 2
  NICKNAMED_ITEM_COLOR_PAIR = 3
  CURSED_ITEM_COLOR_PAIR = 4
  SPECIAL_DUNGEON_COLOR_PAIR = 5

  def initialize
    @debug = ARGV.include?("-d")
    @hard_mode = false
    @default_name = nil

    load_softfonts

    Curses.init_screen
    Curses.start_color

    Curses.init_pair(HEALTH_BAR_COLOR_PAIR, Curses::COLOR_GREEN, Curses::COLOR_RED)
    Curses.init_pair(UNIDENTIFIED_ITEM_COLOR_PAIR, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(NICKNAMED_ITEM_COLOR_PAIR, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(CURSED_ITEM_COLOR_PAIR, Curses::COLOR_WHITE, Curses::COLOR_BLUE)
    Curses.init_pair(SPECIAL_DUNGEON_COLOR_PAIR, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)

    Curses.noecho
    Curses.crmode
    Curses.stdscr.keypad(true)
    at_exit {
      Curses.close_screen
    }

    reset()
  end

  def load_softfonts
    pattern = File.join(File.dirname(__FILE__), "font*.txt")
    Dir.glob(pattern).each do |font|
      STDOUT.write(File.read(font))
    end
  end

  # ゲームの状態をリセット。
  def reset
    @hero = Hero.new(nil, nil, 15, 15, 8, 8, 0, 0, 100.0, 100.0, 1)
    @hero.inventory << Item.make_item("大きなパン")
    if debug?
      @hero.inventory << Item.make_item("エンドゲーム")
      @hero.inventory << Item.make_item("メタルヨテイチの盾")
      @hero.inventory << Item.make_item("人形よけの指輪")
      @hero.inventory << Item.make_item("目薬草")
      @hero.inventory << Item.make_item("薬草")
      @hero.inventory << Item.make_item("薬草")
      @hero.inventory << Item.make_item("高級薬草")
      @hero.inventory << Item.make_item("高級薬草")
      @hero.inventory << Item.make_item("毒けし草")
      @hero.inventory << Item.make_item("あかりの巻物")
      @hero.inventory << Item.make_item("あかりの巻物")
      @hero.inventory << Item.make_item("結界の巻物")
      @hero.inventory << Item.make_item("解呪の巻物")
      @hero.inventory << Item.make_item("同定の巻物")
    end
    @level_number = 0
    @dungeon = Dungeon.new
    @log = MessageLog.new

    @last_room = nil

    @start_time = nil

    @beat = false

    @dash_direction = nil

    @last_rendered_at = Time.at(0)

    @last_message = ""
    @last_message_shown_at = Time.at(0)

    @naming_table = create_naming_table()
  end

  def addstr_ml(win = Curses, ml)
    case ml
    when String
      win.addstr(ml)
    when []
      fail
    when Array
      # ml.size >= 1
      tag, *rest = ml
      if rest.first.is_a?(Hash)
        attrs, rest = rest.first, rest.drop(1)
      else
        attrs, rest = {}, rest
      end
      tag_start(win, tag)
      rest.each do |child|
        addstr_ml(win, child)
      end
      tag_end(win, tag)
    else
      addstr_ml(win, ml.to_s)
    end
  end

  def tag_start(win, tag)
    case tag.downcase
    when "span"
    when "b"
      win.attron(Curses::A_BOLD)
    when "unidentified"
      win.attron(Curses::color_pair(UNIDENTIFIED_ITEM_COLOR_PAIR))
    when "nicknamed"
      win.attron(Curses::color_pair(NICKNAMED_ITEM_COLOR_PAIR))
    when "cursed"
      win.attron(Curses::color_pair(CURSED_ITEM_COLOR_PAIR))
    when "special"
      win.attron(Curses::color_pair(SPECIAL_DUNGEON_COLOR_PAIR))
    end
  end

  def tag_end(win, tag)
    case tag.downcase
    when "span"
    when "b"
      win.attroff(Curses::A_BOLD)
    when "unidentified"
      win.attroff(Curses::color_pair(UNIDENTIFIED_ITEM_COLOR_PAIR))
    when "nicknamed"
      win.attroff(Curses::color_pair(NICKNAMED_ITEM_COLOR_PAIR))
    when "cursed"
      win.attroff(Curses::color_pair(CURSED_ITEM_COLOR_PAIR))
    when "special"
      win.attroff(Curses::color_pair(SPECIAL_DUNGEON_COLOR_PAIR))
    end
  end

  def create_naming_table
    if @hard_mode
      create_naming_table_hard_mode
    else
      create_naming_table_easy_mode
    end
  end

  def create_naming_table_easy_mode
    table = create_naming_table_hard_mode
    table.true_names.each do |name|
      table.identify!(name)
    end
    return table
  end

  def create_naming_table_hard_mode
    get_item_names_by_kind = proc { |specified|
      Item::ITEMS.select { |kind, name, number, desc| kind == specified }.map { |_, name, _, _| name }
    }
    take_strict = proc { |n, arr|
      fail "list too short" if arr.size < n
      arr.take(n)
    }
    herbs_false = ["黒い草", "白い草", "赤い草", "青い草", "黄色い草", "緑色の草",
                   "まだらの草", "スベスベの草", "チクチクの草", "空色の草", "しおれた草",
                   "くさい草", "茶色い草", "ピンクの草"]
    scrolls_false = ["αの巻物", "βの巻物", "γの巻物", "δの巻物", "εの巻物", "ζの巻物", "ηの巻物", "θの巻物",
                     "ιの巻物", "κの巻物", "λの巻物", "μの巻物", "νの巻物", "ξの巻物", "οの巻物", "πの巻物",
                     "ρの巻物", "σの巻物", "τの巻物", "υの巻物", "φの巻物", "χの巻物", "ψの巻物", "ωの巻物"]
    staves_false = ["鉄の杖", "銅の杖", "鉛の杖", "銀の杖", "金の杖", "アルミの杖", "真鍮の杖",
                    "ヒノキの杖", "杉の杖", "桜の杖", "松の杖", "キリの杖", "ナラの杖", "ビワの杖"]
    rings_false = ["金剛石の指輪", "翡翠の指輪", "猫目石の指輪", "水晶の指輪", # "タイガーアイの指輪",
                   "瑪瑙の指輪", "天河石の指輪","琥珀の指輪","孔雀石の指輪","珊瑚の指輪","電気石の指輪",
                   "真珠の指輪","葡萄石の指輪","蛍石の指輪","紅玉の指輪","フォーダイトの指輪", "黒曜石の指輪"]

    herbs_true = get_item_names_by_kind.(:herb)
    scrolls_true = get_item_names_by_kind.(:scroll)
    staves_true = get_item_names_by_kind.(:staff)
    rings_true = get_item_names_by_kind.(:ring)

    herbs_false   = take_strict.(herbs_true.size, herbs_false.shuffle)
    scrolls_false = take_strict.(scrolls_true.size, scrolls_false.shuffle)
    staves_false  = take_strict.(staves_true.size, staves_false.shuffle)
    rings_false   = take_strict.(rings_true.size, rings_false.shuffle)

    NamingTable.new(herbs_false + scrolls_false + staves_false + rings_false,
                    herbs_true + scrolls_true + staves_true + rings_true)
  end

  # デバッグモードで動作中？
  def debug?
    @debug
  end

  def log(*args)
    @log.add(["span", *args])
    stop_dashing
    render
  end

  # 経験値が溜まっていればヒーローのレベルアップをする。
  def check_level_up(silent = false)
    while @hero.lv < exp_to_lv(@hero.exp)
      log("#{@hero.name}の レベルが 上がった。")
      unless silent
        SoundEffects.fanfare
        render
      end
      @hero.lv += 1
      hp_increase = 5
      @hero.max_hp = [@hero.max_hp + 5, 999].min
      @hero.hp = [@hero.max_hp, @hero.hp + 5].min
    end
  end

  # ヒーローの攻撃力。(Lvと武器)
  def get_hero_attack
    basic = lv_to_attack(exp_to_lv(@hero.exp))
    weapon_score = @hero.weapon ? @hero.weapon.number : 0
    (basic + basic * (weapon_score + @hero.strength - 8)/16.0).round
  end

  # ヒーローの投擲攻撃力。
  def get_hero_projectile_attack(projectile_strength)
    basic = lv_to_attack(exp_to_lv(@hero.exp))
    (basic + basic * (projectile_strength - 8)/16.0).round
  end

  # ヒーローの防御力。
  def get_hero_defense
    @hero.shield ? @hero.shield.number : 0
  end

  # モンスターの攻撃力。
  def get_monster_attack(m)
    m.strength
  end

  def on_monster_taking_damage(monster, cell)
    unless monster.nullified?
      if monster.divide? && rand() < 0.5
        x, y = @level.coordinates_of(monster)
        monster_split(monster, cell, x, y)
      elsif monster.teleport_on_attack?
        log("#{display_character(monster)}は ワープした。")
        monster_teleport(monster, cell)
      end
    end
  end

  def monster_explode(monster, ground_zero_cell)
    log("#{display_character(monster)}は 爆発した！")

    mx, my = @level.coordinates_of(monster)

    if Vec.chess_distance([mx,my], @hero.pos) <= 1
      take_damage((@hero.hp / 2.0).ceil)
    end

    rect = @level.surroundings(mx, my)
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

  # モンスターにダメージを与える。
  def monster_take_damage(monster, damage, cell)
    if monster.damage_capped?
      damage = [damage, 1].min
    end
    set_to_explode = !monster.nullified? && monster.bomb? && monster.hp < monster.max_hp/2

    monster.hp -= damage
    log("#{display_character(monster)}に #{damage} のダメージを与えた。")
    if monster.hp >= 1.0 # 生きている
      if set_to_explode
        monster_explode(monster, cell)
        return
      end

      on_monster_taking_damage(monster, cell)
    end
    check_monster_dead(cell, monster)
  end

  # ヒーローがモンスターを攻撃する。
  def hero_attack(cell, monster)
    log("#{@hero.name}の攻撃！ ")
    on_monster_attacked(monster)
    if !@hero.no_miss? && rand() < 0.125
      SoundEffects.miss
      log("#{@hero.name}の攻撃は 外れた。")
    else
      SoundEffects.hit
      attack = get_hero_attack
      damage = ( ( attack * (15.0/16.0)**monster.defense ) * (112 + rand(32))/128.0 ).to_i
      if monster.name == "竜" && @hero.weapon&.name == "ドラゴンキラー"
        damage *= 2
      end
      if @hero.critical? && rand() < 0.25
        log("会心の一撃！")
        damage *= 2
      end
      monster_take_damage(monster, damage, cell)
    end
  end

  # モンスターが死んでいたら、その場合の処理を行う。
  def check_monster_dead(cell, monster)
    if monster.hp < 1.0
      if monster.invisible && !@level.whole_level_lit
        old = display_character(monster)
        monster.invisible = false
        monster.hp = 1
        log("#{old}は #{display_character(monster)}だった!")
        render
        monster.hp = 0
        render
      end
      monster.reveal_self! # 化けの皮を剥ぐ。

      cell.remove_object(monster)

      if monster.item
        thing = monster.item
      elsif rand() < monster.drop_rate
        thing = @dungeon.make_random_item_or_gold(@level_number)
      else
        thing = nil
      end

      if thing
        x, y = @level.coordinates_of_cell(cell)
        item_land(thing, x, y)
      end

      @hero.exp += monster.exp
      log("#{display_character(monster)}を たおして #{monster.exp} ポイントの経験値を得た。")
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

  def remove_status_effect(character, type)
    character.status_effects.reject! { |e|
      if type == e.type
        on_status_effect_expire(character, e)
        true
      else
        false
      end
    }
  end

  # 移動キー定義。
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

    # テンキー。
    Curses::KEY_LEFT => [-1, 0],
    Curses::KEY_RIGHT => [+1, 0],
    Curses::KEY_UP => [0, -1],
    Curses::KEY_DOWN => [0, +1],

    Curses::KEY_HOME  => [-1, -1],
    Curses::KEY_END   => [-1, +1],
    Curses::KEY_PPAGE => [+1, -1],
    Curses::KEY_NPAGE => [+1, +1],

    '7' => [-1, -1],
    '8' => [ 0, -1],
    '9' => [+1, -1],
    '4' => [-1,  0],
    '6' => [+1,  0],
    '1' => [-1, +1],
    '2' => [ 0, +1],
    '3' => [+1, +1],

    # nav cluster のカーソルキーをシフトすると以下になる。
    Curses::KEY_SLEFT => [-1, 0],
    Curses::KEY_SRIGHT => [+1, 0],
    Curses::KEY_SR => [0, -1], # scroll back
    Curses::KEY_SF => [0, +1], # scroll forward
  }

  def hero_can_move_to?(target)
    return false unless Vec.chess_distance(@hero.pos, target) == 1

    dx, dy = Vec.minus(target, @hero.pos)
    if dx * dy != 0
      return @level.passable?(@hero.x + dx, @hero.y + dy) &&
        @level.uncornered?(@hero.x + dx, @hero.y) &&
        @level.uncornered?(@hero.x, @hero.y + dy)
    else
      return @level.passable?(@hero.x + dx, @hero.y + dy)
    end
  end

  # ヒーローの移動・攻撃。
  # String → :move | :action
  def hero_move(c)
    vec = KEY_TO_DIRVEC[c]
    unless vec
      fail ArgumentError, "unknown movement key #{c.inspect}"
    end

    shifted = (%w[H J K L Y U B N 7 8 9 4 6 1 2 3] + [Curses::KEY_SLEFT, Curses::KEY_SRIGHT, Curses::KEY_SR, Curses::KEY_SF]).include?(c)

    if @hero.confused?
      vec = DIRECTIONS.sample
    end

    target = Vec.plus(@hero.pos, vec)
    unless hero_can_move_to?(target)
      return :nothing
    end

    cell = @level.cell(*target)
    if cell.monster
      hero_attack(cell, cell.monster)
      return :action
    else
      if @hero.held?
        log("その場に とらえられて 動けない！ ")
        return :action
      end

      if shifted
        @dash_direction = vec
      end
      hero_walk(*target, !shifted)
      return :move
    end
  end

  def hero_walk(x1, y1, picking)
    if @level.cell(x1, y1).item&.mimic
      item = @level.cell(x1, y1).item
      log(display_item(item), "は ミミックだった!")
      m = Monster.make_monster("ミミック")
      m.state = :awake
      m.action_point = m.action_point_recovery_rate # このターンに攻撃させる
      @level.cell(x1, y1).remove_object(item)
      @level.cell(x1, y1).put_object(m)
      stop_dashing
      return
    end

    #SoundEffects.footstep

    hero_change_position(x1, y1)
    cell = @level.cell(x1, y1)

    gold = cell.gold
    if gold
      if picking
        cell.remove_object(gold)
        @hero.gold += gold.amount
        log("#{gold.amount}G を拾った。")
      else
        log("#{gold.amount}G の上に乗った。")
        stop_dashing
      end
    end

    item = cell.item
    if item
      if picking
        pick(cell, item)
      else
        log(display_item(item), "の上に乗った。")
        stop_dashing
      end
    end

    trap = cell.trap
    if trap
      activation_rate = trap.visible ? (1/4.0) : (3/4.0)
      trap.visible = true
      stop_dashing
      unless @hero.ring&.name == "ワナ抜けの指輪"
        if rand() < activation_rate
          trap_activate(trap)
        else
          log("#{trap.name}は 発動しなかった。")
        end
      end
    end

    if cell.staircase
      stop_dashing
    end

    if @hero.ring&.name == "ワープの指輪"
      if rand() < 1.0/16
        log(@hero.name, "は ワープした！")
        stop_dashing # 駄目押し
        hero_teleport
      end
    end
  end

  def stop_dashing
    @dash_direction = nil
  end

  def hero_change_position(x1, y1)
    @hero.x, @hero.y = x1, y1
    @hero.status_effects.reject! { |e| e.type == :held }
    @level.update_lighting(x1, y1)
    if @last_room != current_room
      walk_in_or_out_of_room
      @last_room = current_room
    end
  end

  # 盾が錆びる。
  def take_damage_shield
    if @hero.shield
      if @hero.shield.rustproof?
        log("しかし #{@hero.shield}は錆びなかった。")
      else
        if @hero.shield.number > 0
          @hero.shield.number -= 1
          log("盾が錆びてしまった！ ")
        else
          log("しかし 何も起こらなかった。")
        end
      end
    else
      log("しかし なんともなかった。")
    end
  end

  # アイテムをばらまく。
  def strew_items
    if @hero.inventory.any? { |x| x.name == "転ばぬ先の杖" }
      log("しかし #{@hero.name}は 転ばなかった。")
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
        if item.name == "結界の巻物"
          item.stuck = true
        end
        @level.put_object(item, x, y)
        @hero.remove_from_inventory(item)
        count += 1
      end
    end

    if count > 0
      log("アイテムを #{count}個 ばらまいてしまった！ ")
    end
  end

  # ヒーローがワープする。
  def hero_teleport
    SoundEffects.teleport

    fov = @level.fov(@hero.x, @hero.y)
    x, y = @level.find_random_place { |cell, x, y|
      cell.type == :FLOOR && !cell.monster && !fov.include?(x, y)
    }
    if x.nil?
      # 視界内でも良い条件でもう一度検索。
      x, y = @level.find_random_place { |cell, x, y|
        cell.type == :FLOOR && !cell.monster
      }
    end

    hero_change_position(x, y)
  end


  # ヒーローに踏まれた罠が発動する。
  def trap_activate(trap)
    case trap.name
    when "ワープゾーン"
      log("ワープゾーンだ！ ")
      wait_delay
      hero_teleport
    when "硫酸"
      log("足元から酸がわき出ている！ ")
      take_damage_shield
    when "トラばさみ"
      log("トラばさみに かかってしまった！ ")
      unless @hero.held?
        @hero.status_effects << StatusEffect.new(:held, 10)
      end
    when "眠りガス"
      log("足元から 霧が出ている！ ")
      hero_fall_asleep()
    when "石ころ"
      log("石にけつまずいた！ ")
      strew_items
    when "矢"
      log("矢が飛んできた！ ")
      take_damage(5)
    when "毒矢"
      log("矢が飛んできた！ ")
      take_damage(5)
      take_damage_strength(1)
    when "地雷"
      log("足元で爆発が起こった！ ")
      mine_activate(trap)
    when "落とし穴"
      log("落とし穴だ！ ")
      SoundEffects.trapdoor
      wait_delay
      new_level(+1, false)
      return # ワナ破損処理をスキップする
    else fail
    end

    tx, ty = @level.coordinates_of(trap)
    if rand() < 0.5
      @level.remove_object(trap, tx, ty)
    end
  end

  # 地雷が発動する。
  def mine_activate(mine)
    take_damage([(@hero.hp / 2.0).floor, 1.0].max)

    tx, ty = @level.coordinates_of(mine)
    rect = @level.surroundings(tx, ty)
    rect.each_coords do |x, y|
      if @level.in_dungeon?(x, y)
        cell = @level.cell(x, y)
        if cell.item
          log(display_item(cell.item), "は 消し飛んだ。")
          cell.remove_object(cell.item)
          render
        end
      end
    end
    rect.each_coords do |x, y|
      if @level.in_dungeon?(x, y)
        cell = @level.cell(x, y)
        if cell.monster
          cell.monster.hp = 0
          render
          check_monster_dead(cell, cell.monster)
        end
      end
    end
  end

  # ヒーロー @hero が配列 objects の要素 item を拾おうとする。
  def pick(cell, item)
    if item.stuck
      log(display_item(item), "は 床にはりついて 拾えない。")
    else
      if @hero.add_to_inventory(item)
        cell.remove_object(item)
        update_stairs_direction
        log(@hero.name, "は ", display_item(item), "を 拾った。")
      else
        log("持ち物が いっぱいで ", display_item(item), "が 拾えない。")
      end
    end
  end

  # (x,y) の罠を見つける。
  def reveal_trap(x, y)
    cell = @level.cell(x, y)
    trap = cell.trap
    if trap && !trap.visible
      trap.visible = true
    end
  end

  # 周り8マスをワナチェックする
  def search
    x, y = @hero.x, @hero.y
    [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]].each do |xoff, yoff|
      # 敵の下のワナは発見されない。
      if @level.in_dungeon?(x+xoff, y+yoff) &&
         @level.cell(x+xoff, y+yoff).monster.nil?
        reveal_trap(x + xoff, y + yoff)
      end
    end
    return :action
  end

  # 足元にある物の種類に応じて行動する。
  def activate_underfoot
    cell = @level.cell(@hero.x, @hero.y)
    if cell.staircase
      return go_downstairs()
    elsif cell.item
      pick(cell, cell.item)
      return :action
    elsif cell.gold
      gold = cell.gold
      cell.remove_object(gold)
      @hero.gold += gold.amount
      log("#{gold.amount}G を拾った。")
      return :action
    elsif cell.trap
      trap_activate(cell.trap)
      return :action
    else
      log("足元には何もない。")
      return :nothing
    end
  end

  # -> :nothing | ...
  def underfoot_menu
    # 足元にワナがある場合、階段がある場合、アイテムがある場合、なにもない場合。
    cell = @level.cell(@hero.x, @hero.y)
    if cell.trap
      log("足元には #{cell.trap.name}がある。「>」でわざとかかる。")
      return :nothing
    elsif cell.staircase
      log("足元には 階段がある。「>」で昇降。")
      return :nothing
    elsif cell.item
      log("足元には ", display_item(cell.item), "が ある。")
      return :nothing
    else
      log("足元には なにもない。")
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
        hero_levels_up(true)
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
    when 'p'
      if debug?
        cheat_get_item()
      end
      :nothing
    when '`'
      if debug?
        shop_interaction
      end
      :nothing
    when '?'
      help
    when 'h','j','k','l','y','u','b','n',
         'H','J','K','L','Y','U','B','N',
         Curses::KEY_LEFT, Curses::KEY_RIGHT, Curses::KEY_UP, Curses::KEY_DOWN,
         Curses::KEY_HOME, Curses::KEY_END, Curses::KEY_PPAGE, Curses::KEY_NPAGE,
         '7', '8', '9', '4', '6', '1', '2', '3',
         Curses::KEY_SLEFT, Curses::KEY_SRIGHT, Curses::KEY_SR, Curses::KEY_SF
      hero_move(c)
    when 16 # ^P
      open_history_window
      :nothing
    when 12 # ^L
      if debug?
        Curses.close_screen
        load(File.dirname(__FILE__) + "/screen_test.rb")
        load(File.dirname(__FILE__) + "/dungeon.rb")
        load(File.dirname(__FILE__) + "/monster.rb")
        load(File.dirname(__FILE__) + "/item.rb")
        load(File.dirname(__FILE__) + "/level.rb")
        load(File.dirname(__FILE__) + "/shop.rb")
      end
      render
      :nothing
    when 'i'
      open_inventory
    when '>'
      activate_underfoot
    when 'q'
      log("冒険をあきらめるには大文字の Q を押してね。")
      :nothing
    when 'Q'
      if confirm_give_up?
        give_up_message
        @quitting = true
        :nothing
      else
        :nothing
      end
    when 's'
      main_menu
    when 't'
      if @hero.projectile
        return throw_item(@hero.projectile)
      else
        log("投げ物を装備していない。")
        :nothing
      end
    when '.', 10 # Enter
      search
    else
      log("[#{c}]なんて 知らない。[?]でヘルプ。")
      :nothing
    end
  end

  def open_history_window
    win = HistoryWindow.new(@log.history, proc { |win, msg| addstr_ml(win, msg) })
    win.run
  end

  def cheat_get_item
    item_kinds = {
      "武器" => :weapon,
      "投げ物" => :projectile,
      "盾" => :shield,
      "草" => :herb,
      "巻物" => :scroll,
      "杖" => :staff,
      "指輪" => :ring,
      "食べ物" => :food,
      "箱" => :box,
    }

    menu = Menu.new(item_kinds.keys)
    begin
      c, arg = menu.choose
      case c
      when :chosen
        kind = item_kinds[arg]
        names = Item::ITEMS.select { |k,| k == kind }.map { |_,name,| name }
        menu2 = Menu.new(names)
        begin
          c2, arg2 = menu2.choose
          case c2
          when :chosen
            item = Item::make_item(arg2)
            if @hero.add_to_inventory(item)
              log(display_item(item), "を 手に入れた。")
              return
            else
              item_land(item, @hero.x, @hero.y)
            end
          else
            return
          end
        ensure
          menu2.close
        end
      else
        return
      end
    ensure
      menu.close
    end
  end

  # 取扱説明。
  # () → :nothing
  def help
    text = <<EOD
★ キャラクターの移動

     y k u
     h @ l
     b j n

★ コマンドキー

     [Enter] 決定。周りを調べる。
     [Shift] ダッシュ。アイテムの上に乗る。
     s       メニューを開く。
     i       道具一覧を開く。
     >       階段を降りる。足元のワナを踏む、
             アイテムを拾う。
     ,       足元を調べる。
     .       周りを調べる。
     ?       このヘルプを表示。
     Ctrl+P  メッセージ履歴。
     t       装備している投げ物を使う。
     q       キャンセル。
     Q       冒険をあきらめる。
EOD

    win = Curses::Window.new(23, 50, 1, 4) # lines, cols, y, x
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

  # ダンジョンをクリアしたリザルト画面。
  def clear_message
    SoundEffects.fanfare3

    item = @hero.inventory.find { |item| item.name == Dungeon::OBJECTIVE_NAME }
    message = "#{item&.number || '??'}階から魔除けを持って無事帰る！"
    data = ResultScreen.to_data(@hero)
           .merge({"screen_shot" => take_screen_shot(),
                   "time" => (Time.now - @start_time).to_i,
                   "message" => message,
                   "level" => @level_number,
                   "return_trip" => @dungeon.on_return_trip?(@hero),
                   "timestamp" => Time.now.to_i,
                   "objective_number" => item&.number || -1,
                  })

    ResultScreen.run(data)

    add_to_rankings(data)
  end

  def cleared?(data)
    data["return_trip"] && data["level"] == 0
  end

  def add_to_rankings(data)
    if add_to_ranking(data, SCORE_RANKING_FILE_NAME, method(:sort_ranking_by_score))
      message_window("スコア番付に載りました。")
    end

    if cleared?(data) && add_to_ranking(data, TIME_RANKING_FILE_NAME, method(:sort_ranking_by_time))
      message_window("タイム番付に載りました。")
    end

    add_to_ranking(data, RECENT_GAMES_FILE_NAME, method(:sort_ranking_by_timestamp))
  end

  # ランキングに追加。
  def add_to_ranking(data, ranking_file_name, sort_ranking)
    begin
      f = File.open(ranking_file_name, "r+")
      f.flock(File::LOCK_EX)

      ranking = sort_ranking.call(JSON.parse(f.read) + [data])
      ranking = ranking[0...20]
      ranked_in = ranking.any? { |item| item.equal?(data) }
      if ranked_in
        f.rewind
        f.write(JSON.dump(ranking))
        f.truncate(f.pos)
        return true
      else
        return false
      end
    rescue Errno::ENOENT
      # この間に別のプロセスによってファイルが作成されないことを祈りま
      # しょう。
      File.open(ranking_file_name, "w") do |g|
        g.flock(File::LOCK_EX)
        g.write("[]")
      end
      return add_to_ranking(data, ranking_file_name, sort_ranking)
    ensure
      f&.close
    end
  end

  # アイテムに適用可能な行動
  def actions_for_item(item)
    actions = item.actions
    if !@naming_table.include?(item.name) || @naming_table.identified?(item.name)
    else
      actions += ["名前"]
    end
    actions += ["説明"]
  end

  # 足元にアイテムを置く。
  def try_place_item(item)
    if @level.cell(@hero.x, @hero.y).can_place?
      if (@hero.weapon.equal?(item) || @hero.shield.equal?(item) || @hero.ring.equal?(item)) &&
         item.cursed
        log(display_item(item), "は 呪われていて 外れない！")
        return
      end

      @hero.remove_from_inventory(item)
      if item.name == "結界の巻物"
        item.stuck = true
      end
      @level.put_object(item, @hero.x, @hero.y)
      update_stairs_direction
      log(display_item(item), "を 置いた。")
    else
      log("ここには 置けない。")
    end
  end

  def display_item(item)
    if item.is_a?(Gold)
      return item.to_s
    end

    case item.type
    when :weapon, :shield
      if item.inspected
        display_inspected_item(item)
      else
        ["unidentified", item.name]
      end
    when :ring
      if item.inspected
        display_inspected_item(item)
      else
        display_uninspected_item(item)
      end
    when :staff
      if item.inspected
        display_inspected_item(item)
      else
        display_uninspected_item(item)
      end
    else
      display_uninspected_item(item)
    end
  end

  def display_inspected_item(item)
    if item.cursed
      ["cursed", item.to_s]
    else
      item.to_s
    end
  end

  def display_uninspected_item(item)
    if @naming_table.include?(item.name)
      case @naming_table.state(item.name)
      when :identified
        if item.type == :staff # 杖の種類は判別しているが回数がわからない状態。
          ["unidentified", item.name]
        elsif item.type == :ring
          ["unidentified", item.name]
        else
          item.to_s
        end
      when :nicknamed
        display_item_by_nickname(item)
      when :unidentified
        ["unidentified", @naming_table.false_name(item.name)]
      else fail
      end
    else
      item.to_s
    end
  end

  def display_item_by_nickname(item)
    kind_label = case item.type
                 when :herb then "草"
                 when :scroll then "巻物"
                 when :ring then "指輪"
                 when :staff then "杖"
                 else "？"
                 end
    ["nicknamed", kind_label, ":", @naming_table.nickname(item.name)]
  end

  # 持ち物メニューを開く。
  # () → :action | :nothing
  def open_inventory
    dispfunc = proc { |win, item|
      prefix = if @hero.weapon.equal?(item) ||
                @hero.shield.equal?(item) ||
                @hero.ring.equal?(item) ||
                @hero.projectile.equal?(item)
               "E"
             else
               " "
             end
      addstr_ml(win, ["span", prefix, item.char, display_item(item)])
    }

    menu = nil
    item = c = nil

    loop do
      item = c = nil
      menu = Menu.new(@hero.inventory,
                      y: 1, x: 0, cols: 28,
                      dispfunc: dispfunc,
                      title: "持ち物 [s]ソート",
                      sortable: true)
      render
      command, *args = menu.choose

      case command
      when :cancel
        #Curses.beep
        return :nothing
      when :chosen
        item, = args

        c = item_action_menu(item)
        if c.nil?
          next
        end
      when :sort
        @hero.sort_inventory!
      end

      break if item and c
    end

    case c
    when "置く"
      try_place_item(item)
    when "投げる"
      return throw_item(item)
    when "食べる"
      eat_food(item)
    when "飲む"
      return take_herb(item)
    when "装備"
      equip(item)
    when "読む"
      return read_scroll(item)
    when "ふる"
      return zap_staff(item)
    else
      log("case not covered: #{item}を#{c}。")
    end
    return :action
  ensure
    menu&.close
  end

  def item_action_menu(item)
    action_menu = Menu.new(actions_for_item(item), y: 1, x: 27, cols: 9)
    begin
      c, *args = action_menu.choose
      case c
      when :cancel
        return nil
      when :chosen
        c, = args
        if c == "説明"
          describe_item(item)
          return nil
        elsif c == "名前"
          render
          if @naming_table.state(item.name) == :nicknamed
            nickname = @naming_table.nickname(item.name)
          else
            nickname = nil
          end
          nickname = NamingScreen.run(nickname)
          @naming_table.set_nickname(item.name, nickname)
          return nil
        else
          return c
        end
      else fail
      end
    ensure
      action_menu.close
    end
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


  def describe_item(item)
    if @naming_table.include?(item.name) && !@naming_table.identified?(item.name)
      desc = "識別されていないので、よくわからない。"
    else
      desc = item.desc
    end
    message_window(desc, y: 1, x: 27)
  end

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
        log(display_item(item), "は 床に落ちた。")
        return
      end
    end
    log(display_item(item), "は消えてしまった。")
  end

  def use_health_item(character, amount, amount_maxhp)
    SoundEffects.heal
    if character.hp_maxed?
      increase_max_hp(character, amount_maxhp)
    else
      increase_hp(character, amount)
    end
  end

  # 草がモンスターに当たった時の効果。
  def herb_hits_monster(item, monster, cell)
    on_monster_attacked(monster)

    case item.name
    when "薬草"
      if monster.undead?
        monster_take_damage(monster, 25, cell)
      else
        use_health_item(monster, 25, 2)
      end
    when "高級薬草"
      if monster.undead?
        monster_take_damage(monster, 100, cell)
      else
        use_health_item(monster, 100, 4)
      end
    when "毒けし草"
      if monster.poisonous?
        monster_take_damage(monster, 50, cell)
      else
        log("しかし 何も 起こらなかった。")
      end
    when "ちからの種"
      monster.strength += 1
      log("#{display_character(monster)}の ちからが 1 上がった。")
    # when "幸せの種"
    when "すばやさの種"
      case  monster.action_point_recovery_rate
      when 1
        monster.action_point_recovery_rate = 2
        monster.action_point = 2
        log("#{display_character(monster)}の 足はもう遅くない。")
      when 2
        monster.action_point_recovery_rate = 4
        monster.action_point = 4
        log("#{display_character(monster)}の 足が速くなった。")
      when 4
        log("しかし 何も起こらなかった。")
      else fail
      end
    when "毒草"
      if monster.strength > 0
        monster.strength -= 1
        log("#{display_character(monster)}の ちからが 1 下がった。")
      else
        # log("しかし 何も起こらなかった。")
      end

      case  monster.action_point_recovery_rate
      when 1
        # log("しかし 何も起こらなかった。")
      when 2
        monster.action_point_recovery_rate = 1
        monster.action_point = 1
        log("#{display_character(monster)}の 足が遅くなった。")
      when 4
        monster.action_point_recovery_rate = 2
        monster.action_point = 2
        log("#{display_character(monster)}の 足はもう速くない。")
      else fail
      end
    when "目つぶし草"
      unless monster.blind?
        log("#{display_character(monster)}は 目が見えなくなった。")
        monster.status_effects << StatusEffect.new(:blindness, 50)
      end
    when "まどわし草"
      unless monster.hallucinating?
        log("#{display_character(monster)}は おびえだした。")
        monster.status_effects << StatusEffect.new(:hallucination, 50)
      end
    when "混乱草"
      unless monster.confused?
        log("#{display_character(monster)}は 混乱した。")
        monster.status_effects << StatusEffect.new(:confused, 10)
      end
    when "睡眠草"
      monster_fall_asleep(monster)
    when "ワープ草"
      monster_teleport(monster, cell)
    when "火炎草"
      monster_take_damage(monster, rand(30...40), cell)
    else
      log("しかし 何も 起こらなかった。")
    end
  end

  # 杖がモンスターに当たった時の効果。
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

  # 盾がモンスターに当たる。
  def shield_hits_monster(item, monster, cell)
    on_monster_attacked(monster)
    damage = item.number
    monster_take_damage(monster, damage, cell)
  end

  # 武器がモンスターに当たる。
  def weapon_hits_monster(item, monster, cell)
    on_monster_attacked(monster)
    damage = item.number
    monster_take_damage(monster, damage, cell)
  end

  # 魔法弾がモンスターに当たる。
  def projectile_hits_monster(item, monster, cell)
    on_monster_attacked(monster)
    attack = get_hero_projectile_attack(item.projectile_strength)
    damage = ( (attack * (15.0/16.0)**monster.defense) * (112 + rand(32))/128.0 ).to_i
    monster_take_damage(monster, damage, cell)
  end

  # アイテムがモンスターに当たる。
  def item_hits_monster(item, monster, cell)
    log(display_item(item), "は ", monster.name, "に当たった。")
    case item.type
    when :box, :food, :scroll, :ring
      on_monster_attacked(monster)
      damage = 1 + rand(1)
      monster_take_damage(monster, damage, cell)
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

  # アイテムがヒーローに当たる。(今のところ矢しか当たらない？)
  def item_hits_hero(item, monster)
    log(display_item(item), "が #{@hero.name}に当たった。")
    if item.type == :projectile
      take_damage(attack_to_hero_damage(item.projectile_strength))
    elsif item.type == :weapon || item.type == :shield
      take_damage(attack_to_hero_damage(item.number))
    else
      take_damage(attack_to_hero_damage(1))
    end
  end

  # モンスターがアイテムを投げる。矢を撃つ敵の行動。
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
            SoundEffects.miss
            item_land(item, x+dx, y+dy)
          else
            SoundEffects.hit
            item_hits_hero(item, monster)
          end
          break
        elsif cell.monster
          # FIXME: これだと主人公に経験値が入ってしまうな
          if rand() < 0.125
            SoundEffects.miss
            item_land(item, x+dx, y+dy)
          else
            SoundEffects.hit
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

  # ドラゴンの炎。
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
          damage = rand(17..23)
          if @hero.shield&.name == "ドラゴンシールド"
            damage /= 2
          end
          take_damage(damage)
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

  # ヒーローがアイテムを投げる。
  # (Item, Array)
  def do_throw_item(item, dir, penetrating, momentum)
    dx, dy = dir
    x, y = @hero.x, @hero.y

    while true
      if momentum == 0
        item_land(item, x, y)
        break
      end
      unless @level.in_dungeon?(x+dx, y+dy)
        log(display_item(item), "は どこかに消えてしまった…。")
        break
      end

      cell = @level.cell(x+dx, y+dy)
      case cell.type
      when :WALL, :HORIZONTAL_WALL, :VERTICAL_WALL, :STATUE
        unless penetrating
          item_land(item, x, y)
          break
        end
      when :FLOOR, :PASSAGE
        if cell.monster
          if rand() < 0.125
            SoundEffects.miss
            if penetrating
              log(display_item(item), "は外れた。")
            else
              item_land(item, x+dx, y+dy)
              break
            end
          else
            SoundEffects.hit
            item_hits_monster(item, cell.monster, cell)
            break unless penetrating
          end
        end
      else
        fail "case not covered"
      end
      x, y = x+dx, y+dy
      momentum -= 1
    end
  end

  # 方向を入力させて、その方向のベクトルを返す。
  def ask_direction
    text = <<EOD
y k u
h   l
b j n
EOD
    win = Curses::Window.new(5, 7, 5, 33) # lines, cols, y, x
    win.keypad(true)
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
      elsif c == 'q' # キャンセル
        return nil
      end
    end
  ensure
    win&.close
  end

  # アイテムを投げるコマンド。
  # Item -> :action | :nothing
  def throw_item(item)
    if (@hero.weapon.equal?(item) || @hero.shield.equal?(item) || @hero.ring.equal?(item)) &&
       item.cursed
      log(display_item(item), "は 呪われていて 外れない！")
      return :action
    end

    dir = ask_direction()
    if dir.nil?
      return :nothing
    end

    penetrating = (item.name == "銀の矢")
    momentum = (item.name == "銀の矢") ? Float::INFINITY : 10
    if item.type == :projectile && item.number > 1
      one = Item.make_item(item.name)
      one.number = 1
      item.number -= 1
      do_throw_item(one, dir, penetrating, momentum)
    else
      @hero.remove_from_inventory(item)
      do_throw_item(item, dir, penetrating, momentum)
    end
    return :action
  end

  # 杖を振るコマンド。
  # Item -> :nothing | :action
  def zap_staff(item)
    fail if item.type != :staff

    dir = ask_direction()
    if dir.nil?
      return :nothing
    else
      if item.number == 0
        log("しかしなにも起こらなかった。")
      elsif item.number > 0
        item.number -= 1
        do_zap_staff(item, dir)
      else
        fail "negative staff number"
      end
      return :action
    end
  end

  # モンスターが睡眠状態になる。
  def monster_fall_asleep(monster)
    unless monster.asleep?
      monster.status_effects.push(StatusEffect.new(:sleep, 5))
      log("#{display_character(monster)}は 眠りに落ちた。")
    end
  end

  # モンスターがワープする。
  def monster_teleport(monster, cell)
    SoundEffects.teleport

    fov = @level.fov(@hero.x, @hero.y)
    x, y = @level.find_random_place { |cell, x, y|
      cell.type == :FLOOR && !cell.monster && !(x==@hero.x && y==@hero.y) && !fov.include?(x, y)
    }
    if x.nil?
      # 視界内でも良い条件でもう一度検索。
      x, y = @level.find_random_place { |cell, x, y|
        cell.type == :FLOOR && !cell.monster && !(x==@hero.x && y==@hero.y)
      }
    end
    cell.remove_object(monster)
    @level.put_object(monster, x, y)
    monster.goal = nil
  end

  # モンスターが変化す。
  def monster_metamorphose(monster, cell, x, y)
    while true
      m = @dungeon.make_monster_from_dungeon
      break if m.name != monster.name
      # 病的なケースで無限ループになる。
    end
    m.state = :awake
    cell.remove_object(monster)
    @level.put_object(m, x, y)
    m.action_point = m.action_point_recovery_rate
    log("#{display_character(monster)}は #{m.name}に変わった！ ")
  end

  # モンスターが分裂する。
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
      log("#{display_character(monster)}は 分裂した！ ")
    else
      log("#{display_character(monster)}は 分裂できなかった。")
    end
  end

  def monster_fall_over(monster, cell, x, y)
    item = monster.item || (if monster.drop_rate > 0 then @dungeon.make_item(@level_number) else nil end)

    monster.item = nil
    monster.drop_rate = 0

    if item
      item_land(item, x, y)
    end

    monster_take_damage(monster, 5, cell)
  end

  # 魔法弾がモンスターに当たる。
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
      monster_fall_over(monster, cell, x, y)
    when "分裂の杖"
      monster_split(monster, cell, x, y)
    when "もろ刃の杖"
      monster.hp = 1
      @hero.hp = @hero.hp - (@hero.hp / 2.0).ceil
      log("#{display_character(monster)}の HP が 1 になった。")
    when "鈍足の杖"
      case  monster.action_point_recovery_rate
      when 1
        log("しかし 何も起こらなかった。")
      when 2
        monster.action_point_recovery_rate = 1
        monster.action_point = 1
        log("#{display_character(monster)}の 足が遅くなった。")
      when 4
        monster.action_point_recovery_rate = 2
        monster.action_point = 2
        log("#{display_character(monster)}の 足はもう速くない。")
      else fail
      end
    when "封印の杖"
      unless monster.nullified?
        monster.reveal_self!
        monster.status_effects.push(StatusEffect.new(:nullification, Float::INFINITY))

        # 通常速度に変更する。
        monster.action_point = 2
        monster.action_point_recovery_rate = 2

        log("#{display_character(monster)}の特技は 封印された。")
      end
    when "即死の杖"
      monster.hp = 0
      check_monster_dead(cell, monster)
    when "とうめいの杖"
      unless monster.invisible
        monster.invisible = true
      end
    when "混乱の杖"
      unless monster.confused?
        monster.status_effects.push(StatusEffect.new(:confused, 10))
        log("#{display_character(monster)}は 混乱した。")
      end
    else
      fail "case not covered"
    end
  end

  # 杖を振る。
  def do_zap_staff(staff, dir)
    dx, dy = dir
    x, y = @hero.x, @hero.y

    while true
      fail unless @level.in_dungeon?(x+dx, y+dy)

      cell = @level.cell(x+dx, y+dy)
      case cell.type
      when :WALL, :HORIZONTAL_WALL, :VERTICAL_WALL
        log("魔法弾は壁に当たって消えた。")
        break
      when :STATUE
        log("魔法弾は石像に当たって消えた。")
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

  # 最大HPが増える。
  def increase_max_hp(character, amount)
    if character.max_hp >= 999
      log("これ以上 HP は増えない！ ")
    else
      increment = [amount, 999 - character.max_hp].min
      character.max_hp += amount
      character.hp = character.max_hp
      log("最大HPが #{increment}ポイント 増えた。")
    end
  end

  # HPが回復する。
  def increase_hp(character, amount)
    increment = [character.max_hp - character.hp, amount].min
    character.hp += increment
    log("HPが #{increment.ceil}ポイント 回復した。")
  end

  # ヒーローのちからが回復する。
  def recover_strength
    @hero.raw_strength = @hero.raw_max_strength
    log("ちからが 回復した。")
  end

  # 巻物を読む。
  # Item -> :nothing | :action
  def read_scroll(item)
    fail "not a scroll" unless item.type == :scroll

    if @hero.nullified?
      log(@hero.name, "の 口は封じられていて使えない!")
      return :action
    end

    if item.targeted_scroll?
      return read_targeted_scroll(item)
    else
      return read_nontargeted_scroll(item)
    end
  end

  def read_targeted_scroll(scroll)
    target = choose_target
    return :nothing unless target

    @hero.remove_from_inventory(scroll)
    log(display_item(scroll), "を 読んだ。")
    SoundEffects.magic

    unless @naming_table.identified?(scroll.name)
      @naming_table.identify!(scroll.name)
      log("なんと！ #{scroll.name}だった！")
    end

    case scroll.name
    when "同定の巻物"
      prevdesc = display_item(target)

      if @naming_table.include?(target.name) && !@naming_table.identified?(target.name)
        @naming_table.identify!(target.name)
        did_identify = true
      else
        did_identify = false
      end

      if [:ring, :weapon, :shield, :staff].include?(target.type) && !target.inspected
        target.inspected = true
        did_inspect = true
      else
        did_inspect = false
      end

      if did_identify || did_inspect
        log(prevdesc, "は ", display_item(target), "だった。")
      else
        log("これは ", display_item(target), "に 間違いない！")
      end
    when "パンの巻物"
      # 装備中のアイテムだったら装備状態を解除する。
      if @hero.weapon.equal?(target)
        @hero.weapon = nil
      end
      if @hero.shield.equal?(target)
        @hero.shield = nil
      end
      if @hero.ring.equal?(target)
        @hero.ring = nil
      end

      index = @hero.inventory.index { |i| target.equal?(i) }
      if index
        @hero.inventory[index] = Item.make_item("大きなパン")
        log(display_item(target), "は ", display_item(@hero.inventory[index]), "に変わってしまった！")
      else # パンの巻物にパンの巻物を読んだ。
        log("しかし 何も起こらなかった。")
      end
    when "祈りの巻物"
      if target.type == :staff
        old = display_item(target)
        r = rand(1..5)
        target.number += r
        log(old, "の回数が#{r}増えた。")
      else
        log("しかし 何も起こらなかった。")
      end
    else
      log("実装してない「どれを」巻物だよ。")
    end
    return :action
  end

  # () -> Item
  def choose_target
    dispfunc = proc { |win, item|
      prefix = if @hero.weapon.equal?(item) ||
                @hero.shield.equal?(item) ||
                @hero.ring.equal?(item) ||
                @hero.projectile.equal?(item)
               "E"
             else
               " "
             end
      addstr_ml(win, ["span", prefix, item.char, display_item(item)])
    }

    menu = nil

    loop do
      menu = Menu.new(@hero.inventory,
                      y: 1, x: 0, cols: 28,
                      dispfunc: dispfunc,
                      title: "どれを？",
                      sortable: false)
      render
      command, *args = menu.choose

      case command
      when :cancel
        return nil
      when :chosen
        item, = args
        return item
      end
    end
  ensure
    menu&.close
  end

  def read_nontargeted_scroll(item)
    @hero.remove_from_inventory(item)

    log(display_item(item), "を 読んだ。")
    SoundEffects.magic

    unless @naming_table.identified?(item.name)
      @naming_table.identify!(item.name)
      log("なんと！ #{item.name}だった！")
    end

    case item.name
    when "あかりの巻物"
      @level.whole_level_lit = true
      log("ダンジョンが あかるくなった。")
    when "武器強化の巻物"
      if @hero.weapon
        @hero.weapon.number += 1
        log("#{@hero.weapon.name}が 少し強くなった。")
        if @hero.weapon.cursed
          @hero.weapon.cursed = false
          log("剣の呪いが 解けた。")
        end
      else
        log("しかし 何も起こらなかった。")
      end
    when "盾強化の巻物"
      if @hero.shield
        @hero.shield.number += 1
        log("#{@hero.shield.name}が 少し強くなった。")
        if @hero.shield.cursed
          @hero.shield.cursed = false
          log("盾の呪いが 解けた。")
        end
      else
        log("しかし 何も起こらなかった。")
      end
    when "メッキの巻物"
      if @hero.shield && !@hero.shield.gold_plated
        log("#{@hero.shield}に メッキがほどこされた！ ")
        @hero.shield.gold_plated = true
      else
        log("しかし 盾はすでにメッキされている。")
      end
      if @hero.shield&.cursed
        @hero.shield.cursed = false
        log("盾の呪いが 解けた。")
      end
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
        log("まわりの モンスターの動きが 止まった。")
      else
        log("しかし 何も起こらなかった。")
      end
    when "結界の巻物"
      log("何も起こらなかった。足元に置いて使うようだ。")
    when "やりなおしの巻物"
      if @dungeon.on_return_trip?(@hero)
        log("帰り道では 使えない。")
      elsif @level_number <= 1
        log("しかし何も起こらなかった。")
      else
        log("不思議なちからで 1階 に引き戻された！ ")
        new_level(1 - @level_number, false)
      end
    when "爆発の巻物"
      log("空中で 爆発が 起こった！ ")
      attack_monsters_in_room(5..35)
    when "ワナの巻物"
      log("実装してないよ。")
    when "ワナけしの巻物"
      @level.all_cells_and_positions.each do |cell, x, y|
        if cell.trap
          cell.remove_object(cell.trap)
        end
      end
      log("このフロアから ワナが消えた。")
    when "大部屋の巻物"
      @level.all_cells_and_positions.each do |cell, x, y|
        if x == 0 || x == 79
          cell.type = :VERTICAL_WALL
        elsif  y == 0 || y == 23
          cell.type = :HORIZONTAL_WALL
        else
          cell.type = :FLOOR
        end
      end
      @level.rooms.replace([Room.new(0, 23, 0, 79)])
      @level.update_lighting(@hero.x, @hero.y)
      log("ダンジョンの壁がくずれた！ ")
    when "解呪の巻物"
      cursed_items = @hero.inventory.select(&:cursed)
      if cursed_items.any?
        cursed_items.each do |item|
          item.cursed = false
        end
        log("アイテムの呪いが 解けた。")
      else
        log("しかし呪われたアイテムは なかった。")
      end
    when "兎耳の巻物"
      if @hero.audition_enhanced?
        log("しかし 何も起こらなかった。")
      else
        @hero.status_effects << StatusEffect.new(:audition_enhancement)
        log("モンスターの気配を 察知できるようになった。")
      end
    when "豚鼻の巻物"
      if @hero.olfaction_enhanced?
        log("しかし 何も起こらなかった。")
      else
        @hero.status_effects << StatusEffect.new(:olfaction_enhancement)
        log("アイテムを 嗅ぎ付けられるようになった。")
      end
    when "封印の巻物"
      if @hero.nullified?
        log("しかし 何も起こらなかった。")
      else
        @hero.status_effects << StatusEffect.new(:nullification)
      end
    else
      log("実装してないよ。")
    end
    return :action
  end

  # モンスターが攻撃された時の処理。起きる。
  def on_monster_attacked(monster)
    wake_monster(monster)
    # かなしばり状態も解ける。
    monster.status_effects.reject! { |e|
      e.type == :paralysis
    }

    case monster.name
    when "動くモアイ像"
      monster.status_effects.reject! { |e|
        e.type == :held
      }
    when "四人トリオ"
      if monster.group # 単独湧きの場合は無い。
        monster.group.each do |friend|
          next if friend.equal?(monster) # 自分は処理しなくていい。

          wake_monster(friend)
          # かなしばり状態も解ける。
          friend.status_effects.reject! { |e|
            e.type == :paralysis
          }
        end
      end
    end
  end

  # モンスターを起こす。
  def wake_monster(monster)
    if monster.state == :asleep
      monster.state = :awake
    end
  end

  # 爆発の巻物の効果。視界全体に攻撃。
  def attack_monsters_in_room(range)
    rect = @level.fov(@hero.x, @hero.y)
    rect.each_coords do |x, y|
      if @level.in_dungeon?(x, y)
        cell = @level.cell(x, y)
        monster = cell.monster
        if monster
          on_monster_attacked(monster)
          monster_take_damage(monster, rand(range), cell)
        end
      end
    end
  end

  # 草を飲む。
  # Item -> :nothing | :action
  def take_herb(item)
    fail "not a herb" unless item.type == :herb

    if @hero.nullified?
      log(@hero.name, "の 口は封じられていて使えない!")
      return :action
    end

    if item.name == "火炎草"
      vec = ask_direction
      if vec.nil?
        return :nothing
      end
    end

    # 副作用として満腹度5%回復。
    @hero.increase_fullness(5.0)

    @hero.remove_from_inventory(item)
    log(display_item(item), "を 薬にして 飲んだ。")

    unless @naming_table.identified?(item.name)
      @naming_table.identify!(item.name)
      log("なんと！ #{item.name}だった！")
    end

    case item.name
    when "薬草"
      use_health_item(@hero, 25, 2)
      remove_status_effect(@hero, :blindness)
    when "高級薬草"
      use_health_item(@hero, 100, 4)
      remove_status_effect(@hero, :blindness)
      remove_status_effect(@hero, :confused)
      remove_status_effect(@hero, :hallucination)
    when "毒けし草"
      unless @hero.strength_maxed?
        recover_strength()
      end
    when "ちからの種"
      if @hero.strength_maxed?
        @hero.raw_max_strength += 1
        @hero.raw_strength = @hero.raw_max_strength
        log("ちからの最大値が 1 ポイント ふえた。")
      else
        @hero.raw_strength += 1
        log("ちからが 1 ポイント 回復した。")
      end
    when "幸せの種"
      hero_levels_up
    when "すばやさの種"
      case @hero.quick?
      when true
        log("しかし 何も起こらなかった。")
      when false
        @hero.status_effects.push(StatusEffect.new(:quick, 3))
        log("#{@hero.name}の 足が速くなった。")
        @hero.action_point = 2
      end
    when "目薬草"
      unless @hero.trap_detecting?
        @hero.status_effects.push(StatusEffect.new(:trap_detection))
        log("ワナが見えるようになった。")
      end
      remove_status_effect(@hero, :blindness)
    when "毒草"
      take_damage(5)
      take_damage_strength(3)
      remove_status_effect(@hero, :confused)
      remove_status_effect(@hero, :hallucination)
    when "目つぶし草"
      unless @hero.blind?
        @hero.status_effects << StatusEffect.new(:blindness, 50)
        log(@hero.name, "の 目が見えなくなった。")
      end
    when "まどわし草"
      unless @hero.hallucinating?
        @hero.status_effects << StatusEffect.new(:hallucination, 50)
        log("ウェーイ！")
      end
    when "睡眠草"
      hero_fall_asleep
    when "ワープ草"
      log("#{@hero.name}は ワープした。")
      wait_delay
      hero_teleport
    when "火炎草"
      log("#{@hero.name}は 口から火を はいた！ ")

      tx, ty = Vec.plus([@hero.x, @hero.y], vec)
      fail unless @level.in_dungeon?(tx, ty)
      cell = @level.cell(tx, ty)

      thing = cell.item || cell.gold
      if thing
        cell.remove_object(thing)
        log("#{thing}は 燃え尽きた。")
      end

      if cell.monster
        monster_take_damage(cell.monster, rand(65...75), cell)
      end
    when "混乱草"
      unless @hero.confused?
        @hero.status_effects.push(StatusEffect.new(:confused, 10))
        log("#{@hero.name}は 混乱した。")
      end

    else
      fail "uncoverd case: #{item}"
    end
    return :action
  end

  # ヒーローのレベルが上がる効果。
  def hero_levels_up(silent = false)
    required_exp = lv_to_exp(@hero.lv + 1)
    if required_exp
      @hero.exp = required_exp
      check_level_up(silent)
    else
      log("しかし 何も起こらなかった。")
    end
  end

  # ヒーローのレベルが下がる効果。
  def hero_levels_down
    if @hero.lv == 1
      log("しかし 何も起こらなかった。")
    else
      exp = lv_to_exp(@hero.lv) - 1
      @hero.lv = @hero.lv - 1
      @hero.exp = exp
      @hero.max_hp = [@hero.max_hp - 5, 1].max
      @hero.hp = [@hero.hp, @hero.max_hp].min
      log("#{@hero.name}の レベルが下がった。")
      SoundEffects.fanfare2
    end
  end

  # ヒーローが眠る効果。
  def hero_fall_asleep
    if @hero.sleep_resistent?
      log("しかし なんともなかった。")
    else
      unless @hero.asleep?
        @hero.status_effects.push(StatusEffect.new(:sleep, 5))
        log("#{@hero.name}は 眠りに落ちた。")
      end
    end
  end

  # 装備する。
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

  # 武器を装備する。
  def equip_weapon(item)
    if @hero.weapon&.cursed
      log(display_item(@hero.weapon), "は 呪われていて 外れない！")
    elsif @hero.weapon.equal?(item) # coreferential?
      @hero.weapon = nil
      log("武器を 外した。")
    else
      @hero.weapon = item
      unless item.inspected
        item.inspected = true
      end
      log(display_item(item), "を 装備した。")
      SoundEffects.weapon
      if item.cursed
        log("なんと！ ", display_item(item), "は呪われていた！")
      end
    end
  end

  # 盾を装備する。
  def equip_shield(item)
    if @hero.shield&.cursed
      log(display_item(@hero.shield), "は 呪われていて 外れない！")
    elsif @hero.shield.equal?(item)
      @hero.shield = nil
      log("盾を 外した。")
    else
      @hero.shield = item
      unless item.inspected
        item.inspected = true
      end
      log(display_item(item), "を 装備した。")
      SoundEffects.weapon
      if item.cursed
        log("なんと！ ", display_item(item), "は呪われていた！")
      end
    end
  end

  # 指輪を装備する。
  def equip_ring(item)
    if @hero.ring&.cursed
      log(display_item(@hero.ring), "は 呪われていて 外れない！")
    elsif @hero.ring.equal?(item)
      @hero.ring = nil
      log(display_item(item), "を 外した。")
    else
      @hero.ring = item
      unless item.inspected
        item.inspected = true
      end
      log(display_item(item), "を 装備した。")
      SoundEffects.weapon
      if item.cursed
        log("なんと！ ", display_item(item), "は呪われていた！")
      end
    end
  end

  # 矢を装備する。
  def equip_projectile(item)
    if @hero.projectile.equal?(item)
      @hero.projectile = nil
      log(display_item(item), "を 外した。")
    else
      @hero.projectile = item
      log(display_item(item), "を 装備した。")
      SoundEffects.weapon
    end
  end

  def increase_max_fullness(amount)
    old = @hero.max_fullness
    unless @hero.max_fullness >= 200.0
      @hero.increase_max_fullness(amount)
      @hero.fullness = @hero.max_fullness
      log("最大満腹度が %.0f%% 増えた。" % [@hero.max_fullness - old])
    end
  end

  # 満腹度が回復する。
  def increase_fullness(amount)
    @hero.increase_fullness(amount)
    if @hero.full?
      log("おなかが いっぱいに なった。")
    else
      log("少し おなかが ふくれた。")
    end
  end

  # ヒーローがダメージを受ける。
  def take_damage(amount, opts = {})
    if opts[:quiet]
      stop_dashing
    else
      log("%.0f ポイントの ダメージを受けた。" % [amount])
    end
    @hero.hp -= amount
    if @hero.hp < 1.0
      @hero.hp = 0.0
      raise HeroDied
    end
  end

  # ちからの現在値にダメージを受ける。
  def take_damage_strength(amount)
    return if @hero.poison_resistent?

    decrement = [amount, @hero.raw_strength].min
    if @hero.raw_strength > 0
      log("ちからが %d ポイント下がった。" %
               [decrement])
      @hero.raw_strength -= decrement
    else
      # ちから 0 だから平気だもん。
    end
  end

  # パンを食べる。
  def eat_food(food)
    fail "not a food" unless food.type == :food

    if @hero.nullified?
      log(@hero.name, "の 口は封じられていて使えない!")
      return :action
    end

    @hero.remove_from_inventory(food)
    log("#{@hero.name}は #{food.name}を 食べた。")
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

  # 下の階へ移動。
  def cheat_go_downstairs
    if @level_number < 99
      new_level(+1, false)
    end
    return :nothing
  end

  # 上の階へ移動。
  def cheat_go_upstairs
    if @level_number > 1
      new_level(-1, false)
    end
    return :nothing
  end

  # 階段を降りる。
  # () -> :nothing
  def go_downstairs
    st = @level.cell(@hero.x, @hero.y).staircase
    if st
      SoundEffects.staircase
      new_level(st.upwards ? -1 : +1, true)
    else
      log("ここに 階段は ない。")
    end
    return :nothing
  end

  # 階段の方向を更新。
  def update_stairs_direction
    @level.stairs_going_up = @dungeon.on_return_trip?(@hero)
  end

  def shop_interaction
    Curses.stdscr.clear
    Curses.stdscr.refresh
    message_window("階段の途中で行商人に出会った。")
    Curses.stdscr.clear
    Curses.stdscr.refresh
    shop = Shop.new(@hero, method(:display_item), method(:addstr_ml))
    shop.run
  end

  # 新しいフロアに移動する。
  def new_level(dir = +1, shop)
    @level_number += dir
    if @level_number == 0
      @beat = true
      clear_message
      @quitting = true
    else
      if @level_number == 100
        @level_number = 99
      end

      if shop && @level_number != 1 && dir == +1 && rand() < 0.1
        shop_interaction
      end

      @level = @dungeon.make_level(@level_number, @hero)

      # 状態異常のクリア
      @hero.status_effects.clear

      # 主人公を配置する。
      x, y = @level.get_random_character_placeable_place
      hero_change_position(x, y)

      if @level.has_type_at?(Item, x, y) ||
         @level.has_type_at?(StairCase, x, y) ||
         @level.has_type_at?(Trap, x, y)
        log("足元になにかある。")
      end

      # 視界
      @level.update_lighting(@hero.x, @hero.y)

      update_stairs_direction

      # 行動ポイントの回復。上の階で階段を降りる時にあまったポイントに
      # 影響されたくないので下の代入文で当ってる。
      @hero.action_point = @hero.action_point_recovery_rate
      recover_monster_action_point
    end
  end

  # キー入力。
  def read_command(message_status)
    Curses.flushinp
    if message_status == :no_message
      Curses.timeout = -1
    else
      Curses.timeout = 1000 # milliseconds
    end
    Curses.curs_set(0)
    c = Curses.getch
    Curses.curs_set(1)
    return c
  end

  def display_character(character)
    if character.is_a?(Monster) && character.invisible && !@level.whole_level_lit
      "見えない敵"
    else
      character.name
    end
  end

  def trap_visible_to_hero(trap)
    fail TypeError unless trap.is_a?(Trap)

    (@hero.trap_detecting? || @hero.ring&.name == "よくみえの指輪" || trap.visible)
  end

  def visible_to_hero?(obj, lit, globally_lit, explored)
    case obj
    when Trap
      (explored || globally_lit) && trap_visible_to_hero(obj)
    when Monster
      if @hero.audition_enhanced? || lit || globally_lit
        invisible = obj.invisible && !globally_lit && !(@hero.trap_detecting? || @hero.ring&.name == "よくみえの指輪")
        if invisible
          false
        else
          true
        end
      else
        false
      end
    when Gold, Item
      @hero.olfaction_enhanced? || explored || globally_lit
    when StairCase
      explored || globally_lit
    else fail
    end
  end

  def dungeon_char(x, y)
    if @hero.x == x && @hero.y == y
      @hero.char
    elsif @hero.blind?
      "　"
    elsif !(y >= 0 && y < @level.height &&
            x >= 0 && x < @level.width)
      if @level.whole_level_lit
        @level.tileset[:WALL]
      else
        "　"
      end
    else
      obj = @level.first_visible_object(x, y, method(:visible_to_hero?))

      if obj
        if @hero.hallucinating?
          case obj
          when Monster
            "\u{10417e}\u{10417f}" # 色違いの主人公
          when Trap, StairCase, Gold, Item
            "\u{10416a}\u{10416b}" # 花
          else
            '??'
          end
        else
          obj.char
        end
      else
        tile = @level.background_char(x, y) 
        if @hero.hallucinating?
          if tile == '􄄤􄄥'
            "\u{104168}\u{104169}"
          else
            tile
          end
        else
          tile
        end
      end
    end
  end

  # マップを表示。
  def render_map
    # マップの描画
    (0 ... (Curses.lines)).each do |y|
      (0 ... (Curses.cols/2)).each do |x|
        Curses.setpos(y, x*2)
        # 画面座標から、レベル座標に変換する。
        y1 = y + @hero.y - Curses.lines/2
        x1 = x + @hero.x - Curses.cols/4
        Curses.addstr(dungeon_char(x1, y1))
      end
    end
  end

  # 主人公を中心として 5x5 の範囲を撮影する。
  # 返り値は String の Array。要素数は 5。
  # 個々の String の文字数は 10。
  def take_screen_shot
    (-2).upto(2).map do |dy|
      (-7).upto(7).map do |dx|
        y1 = @hero.y + dy
        x1 = @hero.x + dx
        if @level.in_dungeon?(x1, y1)
          dungeon_char(x1, y1)
        else
          '　'
        end
      end.join("")
    end
  end

  # 画面でヒーローの居る位置にカーソルを移動する。
  def move_cursor_to_hero
    # カーソルをキャラクター位置に移動。
    Curses.setpos(Curses.lines/2, Curses.cols/2)
  end

  DELAY_SECONDS = 0.4

  # 画面の表示。
  def render
    wait_delay

    render_map()
    render_status()
    message_status = render_message()
    Curses.refresh

    @last_rendered_at = Time.now
    return message_status
  end

  def wait_delay
    t = Time.now
    if t - @last_rendered_at < DELAY_SECONDS
      sleep (@last_rendered_at + DELAY_SECONDS) - t
    end
  end

  def cancel_delay
    @last_rendered_at = Time.at(0)
  end

  FRACTIONS = {
    1 => "▏",
    2 => "▎",
    3 => "▍",
    4 => "▌",
    5 => "▋",
    6 => "▊",
    7 => "▉",
  }
  # () -> String
  def render_health_bar
    eighths = ((@hero.hp.fdiv(@hero.max_hp)) * 80).round
    ones = eighths / 8
    fraction = eighths % 8
    if fraction == 0
      "█" * ones +  " " * (10-ones)
    else
      "█" * ones + FRACTIONS[fraction] + " " * (10-ones-1)
    end
  end

  # 画面最上部、ステータス行の表示。
  def render_status
    low_hp   = @hero.hp.floor <= (@hero.max_hp / 10.0).ceil
    starving = @hero.fullness <= 0.0
    dungeon = @hard_mode ? "special" : "span"

    Curses.setpos(0, 0)
    Curses.clrtoeol
    addstr_ml(Curses, ["span", "%d" % [@level_number], [dungeon, "F"], "  "])
    addstr_ml(Curses, ["span", [dungeon, "Lv"], " %d  " % [@hero.lv]])
    Curses.attron(Curses::A_BLINK) if low_hp
    addstr_ml(Curses, [dungeon, "HP"])
    Curses.attroff(Curses::A_BLINK) if low_hp
    Curses.addstr(" %3d" % [@hero.hp])
    addstr_ml(Curses, [dungeon, "/"])
    Curses.addstr("%d  " % [@hero.max_hp])
    Curses.attron(Curses::color_pair(HEALTH_BAR_COLOR_PAIR))
    Curses.addstr(render_health_bar)
    Curses.attroff(Curses::color_pair(HEALTH_BAR_COLOR_PAIR))
    Curses.addstr("  %d" % [@hero.gold])
    addstr_ml(["span", [dungeon, "G"], "  "])
    Curses.attron(Curses::A_BLINK) if starving
    addstr_ml(Curses, [dungeon, "満"])
    Curses.attroff(Curses::A_BLINK) if starving
    Curses.addstr(" %d"   % [@hero.fullness.ceil])
    addstr_ml([dungeon, "% "])
    Curses.addstr("%s "     % [@hero.status_effects.map(&:name).join(' ')])
    addstr_ml([dungeon, "["])
    Curses.addstr("%04d"  % [@level.turn])
    addstr_ml([dungeon, "]"])
  end

  # メッセージの表示。
  def render_message
    if @log.lines.any?
      Curses.setpos(Curses.lines-1, 0)
      msg = ["span", *@log.lines]
      addstr_ml(Curses, msg)
      Curses.clrtoeol
      @log.lines.clear
      @last_message = msg
      @last_message_shown_at = Time.now
      :message_displayed
    elsif Time.now - @last_message_shown_at < DELAY_SECONDS
      Curses.setpos(Curses.lines-1, 0)
      addstr_ml(Curses, @last_message)
      Curses.clrtoeol
      :last_message_redisplayed
    else
      :no_message
    end
  end

  # 死んだ時のリザルト画面。
  def gameover_message
    SoundEffects.gameover

    if @dungeon.on_return_trip?(@hero)
      message = "魔除けを持って#{@level_number}階で力尽きる。"
    else
      message = "#{@level_number}階で力尽きる。"
    end
    data = ResultScreen.to_data(@hero)
           .merge({"screen_shot" => take_screen_shot(),
                   "time" => (Time.now - @start_time).to_i,
                   "message" => message,
                   "level" => @level_number,
                   "return_trip" => @dungeon.on_return_trip?(@hero),
                   "timestamp" => Time.now.to_i,
                  })

    ResultScreen.run(data)

    add_to_rankings(data)
  end

  def give_up_message
    if @dungeon.on_return_trip?(@hero)
      message = "魔除けを持って#{@level_number}階であきらめた。"
    else
      message = "#{@level_number}階で冒険をあきらめた。"
    end
    data = ResultScreen.to_data(@hero)
           .merge({"screen_shot" => take_screen_shot(),
                   "time" => (Time.now - @start_time).to_i,
                   "message" => message,
                   "level" => @level_number,
                   "return_trip" => @dungeon.on_return_trip?(@hero),
                   "timestamp" => Time.now.to_i,
                  })

    ResultScreen.run(data)

    add_to_rankings(data)
  end

  # 次のレベルまでに必要な経験値。
  def exp_until_next_lv
    if @hero.lv == 37
      return nil
    else
      return lv_to_exp(@hero.lv + 1) - @hero.exp
    end
  end

  def main_menu
    menu = Menu.new(["道具",
                     "足元",
                     "メッセージ履歴",
                     "あきらめる",
                    ],
                    cols: 18, y: 1, x: 0)
    while true
      render
      status = create_status_window(13, 0)
      status.refresh
      command, arg = menu.choose
      status.close
      status = nil
      case command
      when :chosen
        case arg
        when "道具"
          result = open_inventory
          if result == :nothing
            next
          else
            return result
          end
        when "足元"
          result = activate_underfoot
          # 階段を降りる場合があるので、何もなくてもメニューを閉じる。
          return result
        when "メッセージ履歴"
          open_history_window
          next
        when "あきらめる"
          if confirm_give_up?
            give_up_message
            @quitting = true
            return :nothing
          else
            next
          end
        end
      when :cancel
        return :nothing
      end
    end
  ensure
    status&.close
    menu&.close
  end

  # Returns: Curses::Window
  def create_status_window(winy = 1, winx = 0)
    until_next_lv = exp_until_next_lv ? exp_until_next_lv.to_s : "∞"
    disp = proc { |item| item.nil? ? 'なし' : display_item(item) }
    text =
      [
        ["span", " 攻撃力 %d" % [get_hero_attack]],
        ["span", " 防御力 %d" % [get_hero_defense]],
        ["span", "   武器 ", disp.(@hero.weapon)],
        ["span", "     盾 ", disp.(@hero.shield)],
        ["span", "   指輪 ", disp.(@hero.ring)],
        ["span", " ちから %d/%d" % [@hero.strength, @hero.max_strength]],
        ["span", " 経験値 %d" % [@hero.exp]],
        ["span", " つぎのLvまで %s" % [until_next_lv]],
        ["span", " 満腹度 %d%%/%d%%" % [@hero.fullness.ceil, @hero.max_fullness]]
      ]

    win = Curses::Window.new(text.size + 2, 32, winy, winx) # lines, cols, y, x
    win.clear
    win.rounded_box
    win.setpos(0, 1)
    win.addstr(@hero.name)
    text.each.with_index(1) do |line, y|
      win.setpos(y, 1)
      addstr_ml(win, line)
    end
    return win
  end

  def status_window
    win = create_status_window
    begin
      win.getch
    ensure
      win.close
    end
  end

  # 位置 v1 と v2 は縦・横・ナナメのいずれかの線が通っている。
  def aligned?(v1, v2)
    diff = Vec.minus(v1, v2)
    return diff[0].zero? ||
           diff[1].zero? ||
           diff[0].abs == diff[1].abs
  end

  # モンスターの特技が使える位置にヒーローが居るか？
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

  # 特技を使う条件が満たされているか？
  def trick_applicable?(m)
    mx, my = @level.coordinates_of(m)
    return trick_in_range?(m, mx, my) &&
           case m.name
           when "目玉"
             !@hero.confused?
           when "白い手"
             !@hero.held?
           when "どろぼう猫"
             !m.hallucinating?
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
    if !(!m.nullified? && m.hallucinating?) && @level.fov(mx, my).include?(@hero.x, @hero.y)
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
           [mx+dx, my+dy] != [@hero.x, @hero.y] &&
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
        # * 部屋の外に居れば

        # * 反対以外の方向に進もうとする。
        dirs = [
          Vec.rotate_clockwise_45(m.facing, +2),
          Vec.rotate_clockwise_45(m.facing, -2),
          Vec.rotate_clockwise_45(m.facing, +1),
          Vec.rotate_clockwise_45(m.facing, -1),
          Vec.rotate_clockwise_45(m.facing,  0),
        ].shuffle
        dirs.each do |dx, dy|
          if @level.can_move_to?(m, mx, my, mx+dx, my+dy) &&
             [mx+dx, my+dy] != [@hero.x, @hero.y] &&
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

  def monster_confused_action(m, mx, my)
    candidates = []
    rect = @level.surroundings(mx, my)
    rect.each_coords do |x, y|
      next unless @level.in_dungeon?(x, y) &&
                  (@level.cell(x, y).type == :FLOOR ||
                   @level.cell(x, y).type == :PASSAGE)
      if @level.can_move_to_terrain?(m, mx, my, x, y) &&
         @level.cell(x, y).item&.name != "結界の巻物"
        candidates << [x, y]
      end
    end
    if candidates.any?
      x, y = candidates.sample
      if [x,y] == @hero.pos || @level.cell(x,y).monster
        return Action.new(:attack, [x-mx, y-my])
      else
        return Action.new(:move, [x - mx, y - my])
      end
    else
      return Action.new(:rest, nil)
    end
  end

  def monster_blind_action(m, mx, my)
    target = nil
    dx, dy = m.facing
    applicable_p = lambda { |x, y|
      if @level.in_dungeon?(x,y) &&
         (@level.cell(x,y).type==:FLOOR || @level.cell(x,y).type==:PASSAGE) &&
         @level.can_move_to_terrain?(m, mx, my, x, y) &&
         @level.cell(x,y).item&.name != "結界の巻物"
        true
      else
        false
      end
    }
    attack_or_move = lambda { |x, y|
      if [x,y] == @hero.pos || @level.cell(x,y).monster
        return Action.new(:attack, [x-mx, y-my])
      else
        return Action.new(:move, [x-mx, y-my])
      end
    }

    if applicable_p.(mx+dx, my+dy)
      return attack_or_move.(mx+dx, my+dy)
    else
      candidates = []
      @level.surroundings(mx, my).each_coords do |x, y|
        if applicable_p.(x, y)
          candidates << [x,y]
        end
      end

      if candidates.any?
        x, y = candidates.sample
        m.facing = [x-mx, y-my]
      end
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

        if m.paralyzed?
          return Action.new(:rest, nil)
        elsif m.asleep?
          return Action.new(:rest, nil)
        elsif !m.nullified? && m.bomb? && m.hp <= m.max_hp/2
          return Action.new(:rest, nil)
        elsif m.confused?
          return monster_confused_action(m, mx, my)
        elsif m.blind?
          return monster_blind_action(m, mx, my)
        elsif !m.nullified? && m.hallucinating? # まどわし状態では攻撃しない。
          return monster_move_action(m, mx, my)
        elsif !m.nullified? && m.tipsy? && rand() < 0.5 # ちどり足。
          return monster_tipsy_move_action(m, mx, my)
        elsif adjacent?([mx, my], [@hero.x, @hero.y]) &&
              @level.cell(@hero.x, @hero.y).item&.name == "結界の巻物"
          return monster_move_action(m, mx, my) # Action.new(:rest, nil)
        elsif !m.nullified? && trick_applicable?(m) && rand() < m.trick_rate
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

  # 敵の攻撃力から、実際にヒーローが受けるダメージを計算する。
  def attack_to_hero_damage(attack)
    return ( ( attack * (15.0/16.0)**get_hero_defense ) * (112 + rand(32))/128.0 ).to_i
  end

  def monster_attacks_hero(m)
    attack = get_monster_attack(m)

    if attack == 0
      log("#{display_character(m)}は 様子を見ている。")
    else
      log("#{display_character(m)}の こうげき！ ")
      if rand() < 0.125
        SoundEffects.miss
        log("#{@hero.name}は ひらりと身をかわした。")
      else
        SoundEffects.hit
        damage = attack_to_hero_damage(attack)
        take_damage(damage)
      end
    end
  end

  # モンスターが攻撃する。
  def monster_attack(assailant, dir)
    mx, my = @level.coordinates_of(assailant)
    target = Vec.plus([mx, my], dir)
    defender = @level.cell(*target).monster
    if @hero.pos == target
      monster_attacks_hero(assailant)
    elsif defender
      attack = get_monster_attack(assailant)
      damage = ( ( attack * (15.0/16.0)**defender.defense ) * (112 + rand(32))/128.0 ).to_i

      if attack == 0
        log("#{assailant.name}は 様子を見ている。")
      else
        log("#{assailant.name}の こうげき！ ")
        on_monster_attacked(defender)
        monster_take_damage(defender, damage, @level.cell(*target))
      end
    else
      # 誰もいない
    end
  end

  # モンスターが特技を使用する。
  def monster_trick(m)
    case m.name
    when '催眠術師'
      log("#{m.name}は 手に持っている物を 揺り動かした。")
      SoundEffects.magic
      hero_fall_asleep
    when 'ファンガス'
      log("#{m.name}は 毒のこなを 撒き散らした。")
      take_damage_strength(1)
    when 'ノーム'
      potential = rand(250..1500)
      actual = [potential, @hero.gold].min
      if actual == 0
        log("#{@hero.name}は お金を持っていない！ ")
      else
        log("#{m.name}は #{actual}ゴールドを盗んでワープした！ ")

        @hero.gold -= actual
        m.item = Gold.new(actual)

        unless m.hallucinating?
          m.status_effects << StatusEffect.new(:hallucination, Float::INFINITY)
        end

        monster_teleport(m, @level.cell(*@level.coordinates_of(m)))
      end
    when "白い手"
      if !@hero.held?
        log("#{m.name}は #{@hero.name}の足をつかんだ！ ")
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
      log("#{m.name}は 酸を浴せた。")
      if @hero.shield
        take_damage_shield
      end

    when "パペット"
      log("#{m.name}は おどりをおどった。")
      if @hero.puppet_resistent?
        log("しかし #{@hero.name}は平気だった。")
      else
        hero_levels_down
      end

    when "土偶"
      if rand() < 0.5
        log("#{m.name}が #{@hero.name}のちからを吸い取る！")
        if @hero.puppet_resistent?
          log("しかし #{@hero.name}は平気だった。")
        else
          take_damage_max_strength(1)
        end
      else
        log("#{m.name}が #{@hero.name}の生命力を吸い取る！")
        if @hero.puppet_resistent?
          log("しかし #{@hero.name}は平気だった。")
        else
          take_damage_max_hp(5)
        end
      end

    when "目玉"
      log("目玉は#{@hero.name}を睨んだ！")
      unless @hero.confused?
        @hero.status_effects.push(StatusEffect.new(:confused, 10))
        log("#{@hero.name}は 混乱した。")
      end

    when "どろぼう猫"
      candidates = @hero.inventory.reject { |x| @hero.equipped?(x) }

      if candidates.any?
        item = candidates.sample
        @hero.remove_from_inventory(item)
        m.item = item
        log("#{m.name}は ", display_item(item), "を盗んでワープした。")

        unless m.hallucinating?
          m.status_effects << StatusEffect.new(:hallucination, Float::INFINITY)
        end

        monster_teleport(m, @level.cell(*@level.coordinates_of(m)))
      else
        log("#{@hero.name}は 何も持っていない。")
      end

    when "竜"
      mx, my = @level.coordinates_of(m)
      dir = Vec.normalize(Vec.minus([@hero.x, @hero.y], [mx, my]))
      log("#{m.name}は 火を吐いた。")
      breath_of_fire(m, mx, my, dir)

    when "ソーサラー"
      log("#{m.name}は ワープの杖を振った。")
      SoundEffects.magic
      wait_delay
      hero_teleport

    else
      fail
    end
  end

  # ヒーローがちからの最大値にダメージを受ける。
  def take_damage_max_strength(amount)
    fail unless amount == 1
    if @hero.raw_max_strength <= 1
      log("#{@hero.name}の ちからは これ以上さがらない。")
    else
      @hero.raw_max_strength -= 1
      @hero.raw_strength = [@hero.raw_strength, @hero.raw_max_strength].min
      log("#{@hero.name}の ちからの最大値が 下がった。")
    end
  end

  # ヒーローが最大HPにダメージを受ける。
  def take_damage_max_hp(amount)
    @hero.max_hp = [@hero.max_hp - amount, 1].max
    @hero.hp = [@hero.hp, @hero.max_hp].min
    log("#{@hero.name}の 最大HPが 減った。")
  end

  # モンスターが移動する。
  def monster_move(m, mx, my, dir)
    @level.cell(mx, my).remove_object(m)
    @level.cell(mx + dir[0], my + dir[1]).put_object(m)
    m.facing = dir
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

  # 行動により満腹度が消費される。満腹度が無い時はHPが減る。
  def hero_fullness_decrease
    old = @hero.fullness
    if @hero.fullness > 0.0
      unless @dungeon.on_return_trip?(@hero)
        @hero.fullness -= @hero.hunger_per_turn
        if old >= 20.0 && @hero.fullness <= 20.0
          log("おなかが 減ってきた。")
        elsif old >= 10.0 && @hero.fullness <= 10.0
          log("空腹で ふらふらしてきた。")
        elsif @hero.fullness <= 0.0
          log("早く何か食べないと死んでしまう！ ")
        end
      end

      # 自然回復
      @hero.hp = [@hero.hp + @hero.max_hp/150.0, @hero.max_hp].min
    else
      take_damage(1, quiet: true)
    end
  end

  # 64ターンに1回の敵湧き。
  def spawn_monster
    @dungeon.place_monster(@level, @level_number, @level.fov(@hero.x, @hero.y))
  end

  # ヒーローが居る部屋。
  def current_room
    @level.room_at(@hero.x, @hero.y)
  end

  # 部屋の出入りでモンスターが起きる。
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
              monster.action_point = 0
            end
          end
        end

      end
    end

  end

  # 状態以上が解けた時のメッセージ。
  def on_status_effect_expire(character, effect)
    case effect.type
    when :paralysis
      log("#{display_character(character)}の かなしばりがとけた。")
    when :sleep
      log("#{display_character(character)}は 目をさました。")
    when :held
      log("#{display_character(character)}の 足が抜けた。")
    when :confused
      log("#{display_character(character)}の 混乱がとけた。")
    when :quick
      log("#{display_character(character)}の 足はもう速くない。")
    else
      log("#{display_character(character)}の #{effect.name}状態がとけた。")
    end
  end

  # 状態以上の残りターン数減少処理。
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

  # ヒーローの名前を付ける。
  def naming_screen
    # 背景画面をクリア
    Curses.stdscr.clear
    Curses.stdscr.refresh

    name = NamingScreen.run(@default_name)
    if name
      @default_name = name
      while true
        reset()
        @hero.name = name
        play()
        if @beat
          break
        end
        unless ask_retry?
          break
        end
      end
    end
  end

  def confirm_give_up?
    menu = Menu.new(["冒険をあきらめる", "あきらめない"],
                    cols: 20, y: 8, x: 30)
    type, item = menu.choose
    case type
    when :chosen
      case item
      when "冒険をあきらめる"
        return true
      when "あきらめない"
        return false
      else fail
      end
    when :cancel
      return false
    else fail
    end
  end

  def ask_retry?
    Curses.stdscr.clear
    Curses.stdscr.refresh

    menu = Menu.new(["もう一度挑戦する", "やめる"],
                    cols: 20, y: 8, x: 30)
    type, item = menu.choose
    case type
    when :chosen
      case item
      when "もう一度挑戦する"
        return true
      when "やめる"
        return false
      else fail
      end
    when :cancel
      return false
    else fail
    end
  end

  def validate_ranking(data)
    data.is_a?(Array)
  end

  # メッセージボックス。
  def message_window(message, opts = {})
    cols = opts[:cols] || message.size * 2 + 2
    y = opts[:y] || (Curses.lines - 3)/2
    x = opts[:x] || (Curses.cols - cols)/2

    win = Curses::Window.new(3, cols, y, x) # lines, cols, y, x
    win.clear
    win.rounded_box

    win.setpos(1, 1)
    win.addstr(message.chomp)

    Curses.flushinp
    win.getch
    win.clear
    win.refresh
    win.close
  end

  # ランキングでの登録日時フォーマット。
  def format_timestamp(unix_time)
    Time.at(unix_time).strftime("%y-%m-%d")
  end

  def sort_ranking_by_score(ranking)
    ranking.sort { |a,b|
      b["gold"] <=> a["gold"]
    }
  end

  def sort_ranking_by_time(ranking)
    ranking.sort { |a,b|
      a["time"] <=> b["time"]
    }
  end

  def sort_ranking_by_timestamp(ranking)
    ranking.sort { |a,b|
      b["timestamp"] <=> a["timestamp"]
    }
  end

  # ランキング表示画面。
  def ranking_screen(title, ranking_file_name, dispfunc)
    Curses.stdscr.clear
    Curses.stdscr.refresh

    begin
      f = File.open(ranking_file_name, "r")
      f.flock(File::LOCK_SH)
      ranking = JSON.parse(f.read)
      unless validate_ranking(ranking)
        message_window("番付ファイルが壊れています。")
        return
      end
    rescue Errno::ENOENT
      ranking = []
    ensure
      f&.close
    end

    if ranking.empty?
      message_window("まだ記録がありません。")
    else
      menu = Menu.new(ranking, y: 0, x: 5, cols: 70, dispfunc: dispfunc, title: title)
      while true
        Curses.stdscr.clear
        Curses.stdscr.refresh

        cmd, *args = menu.choose
        case cmd
        when :cancel
          return
        when :chosen
          data = args[0]

          ResultScreen.run(data)
        end
      end
    end
  end

  def format_time(seconds)
    h = seconds / 3600
    m = (seconds % 3600) / 60
    s = seconds % 60
    "%2d:%02d:%02d" % [h, m, s]
  end

  # 起動時のメニュー。
  def initial_menu
    reset()

    Curses.stdscr.clear

    Curses.stdscr.setpos(Curses.stdscr.maxy-2, 0)
    Curses.stdscr.addstr("決定: Enter")
    Curses.stdscr.setpos(Curses.stdscr.maxy-1, 0)
    Curses.stdscr.addstr("もどる: q")

    Curses.stdscr.refresh

    menu = Menu.new([
                      "冒険に出る",
                      "スコア番付",
                      "タイム番付",
                      "最近のプレイ",
                      "終了",
                    ], y: 0, x: 0, cols: 16)
    cmd, *args = menu.choose
    case cmd
    when :cancel
      return
    when :chosen
      item, = args
      case item
      when "冒険に出る"
        naming_screen
      when "スコア番付"
        ranking_screen("スコア番付", SCORE_RANKING_FILE_NAME,
                       proc do |win, data|
                         name = data["hero_name"] + ('　'*(6-data["hero_name"].size))
                         gold = "%7dG" % data["gold"]
                         win.addstr("#{gold}  #{name}  #{format_timestamp(data["timestamp"])}  #{data["message"]}")
                       end
                      )
      when "タイム番付"
        ranking_screen("タイム番付", TIME_RANKING_FILE_NAME,
                       proc do |win, data|
                         name = data["hero_name"] + ('　'*(6-data["hero_name"].size))
                         time = format_time(data["time"])
                         win.addstr("#{time}  #{name}  #{format_timestamp(data["timestamp"])}  #{data["message"]}")
                       end
                      )
      when "最近のプレイ"
        ranking_screen("最近のプレイ", RECENT_GAMES_FILE_NAME,
                       proc do |win, data|
                         name = data["hero_name"] + ('　'*(6-data["hero_name"].size))
                         win.addstr("#{format_timestamp(data["timestamp"])}  #{name}  #{data["message"]}")
                       end
                      )
      when "終了"
        return
      else
        fail item
      end
    end
    initial_menu
  end

  def intrude_party_room
    unless @hero.audition_enhanced?
      @hero.status_effects << StatusEffect.new(:audition_enhancement)
    end

    log("魔物の巣窟だ！ ")
    SoundEffects.partyroom
    render

    if @hero.ring&.name != "盗賊の指輪"

      wake_monsters_in_room(@level.party_room, 1.0)

      room = @level.party_room
      ((room.top+1)..(room.bottom-1)).each do |y|
        ((room.left+1)..(room.right-1)).each do |x|

          monster = @level.cell(x, y).monster
          if monster
            monster.on_party_room_intrusion
            monster.action_point = 0
          end
        end
      end

    end
    @level.party_room = nil
  end

  def walk_in_or_out_of_room
    if @last_room
      wake_monsters_in_room(@last_room, 0.5)
    end
    if current_room
      if current_room == @level.party_room
        intrude_party_room
      else
        wake_monsters_in_room(current_room, 0.5)
      end
    end
  end

  # 十字路、T字路で止まる。
  def fork?(point)
    if @level.room_at(*point)
      return false
    end

    unless [[-1,-1],[+1,-1],[-1,+1],[+1,+1],[-1,0],[0,-1],[+1,0],[0,+1]].all? { |d|
             @level.in_dungeon?(*Vec.plus(point,d))
           }
      return false
    end

    # # ナナメ四隅が壁で…
    # unless [[-1,-1],[+1,-1],[-1,+1],[+1,+1]].all? { |d|
    #          @level.cell(*Vec.plus(point,d)).wall?
    #        }
    #   return false
    # end

    unless [[-1,0],[0,-1],[+1,0],[0,+1]].count { |d|
             @level.cell(*Vec.plus(point,d)).type == :PASSAGE ||
             @level.cell(*Vec.plus(point,d)).type == :FLOOR
           } >= 3
      return false
    end

    return true
  end

  def should_keep_dashing?
    target = Vec.plus(@hero.pos, @dash_direction)
    index = DIRECTIONS.index(@dash_direction)
    forward_area = (-2..+2).map { |ioff|
      Vec.plus(@hero.pos, DIRECTIONS[(index+ioff) % 8])
    }

    # if @hero.status_effects.any?
    #   return false
    # els
    if !hero_can_move_to?(target)
      return false
    elsif @level.cell(*target).monster # ありえなくない？
      return false
    elsif forward_area.any? { |x,y|
      cell = @level.cell(x,y)
      cell.staircase ||
        cell.item ||
        cell.gold ||
        (cell.trap && trap_visible_to_hero(cell.trap)) ||
        cell.monster ||
        cell.type == :STATUE
    }
      return false
    elsif current_room && @level.first_cells_in(current_room).include?(@hero.pos)
      return false
    elsif current_room.nil? && @level.room_at(*target) &&
          @level.first_cells_in(@level.room_at(*target)).include?(target)
      return false
    elsif fork?(@hero.pos)
      return false
    else
      return true
    end
  end

  def hero_dash
    if should_keep_dashing?
      hero_walk(*Vec.plus(@hero.pos, @dash_direction), false)
      return :move
    else
      @dash_direction = nil
      return :nothing
    end
  end

  # () -> :action | :nothing | :move
  def hero_phase
    if @hero.asleep?
      log("眠くて何もできない。")
      return :action
    elsif @dash_direction # ダッシュ中
      return hero_dash
    else
      while true
        # 画面更新
        cancel_delay
        message_status = render
        cancel_delay

        c = read_command(message_status)

        if c
          return dispatch_command(c)
        end
      end
    end
  end

  def recover_monster_action_point
    @level.all_monsters_with_position.each do |m, pos|
      m.action_point += m.action_point_recovery_rate
    end
  end

  def next_turn
    @level.turn += 1
    @hero.action_point += @hero.action_point_recovery_rate
    recover_monster_action_point
    status_effects_wear_out
    hero_fullness_decrease
    if @level.turn % 64 == 0 && @level.monster_count < 25
      spawn_monster
    end
  end

  def all_monsters_moved?
    @level.all_monsters_with_position.all? { |m, pos|
      m.action_point < 2
    }
  end

  # モンスターの移動・行動フェーズ。
  def monster_phase
    doers = []
    @level.all_monsters_with_position.each do |m, mx, my|
      next if m.action_point < 2
      action = monster_action(m, mx, my)
      if action.type == :move
        # その場で動かす。
        monster_move(m, mx, my, action.direction)
        m.action_point -= 2
      else
        doers << [m, action]
      end
    end

    doers.each do |m, action|
      next if m.hp < 1.0

      dispatch_action(m, action)
      if m.single_attack?
        # 攻撃するとAPを使いはたす。
        m.action_point = 0
      else
        m.action_point -= 2
      end
    end
  end

  # ダンジョンのプレイ。
  def play
    @start_time = Time.now
    @quitting = false

    new_level(+1, false)
    render

    begin
      until @quitting
        if @hero.action_point >= 2
          old = @hero.action_point
          @hero.action_point -= 2
          case hero_phase
          when :move, :action
          when :nothing
            @hero.action_point = old
          end
        elsif all_monsters_moved?
          next_turn
        else
          if @hero.ring&.name == "退魔の指輪"
            rect = @level.fov(@hero.x, @hero.y)
            rect.each_coords do |x, y|
              next unless @level.in_dungeon?(x, y)
              m = @level.cell(x, y).monster
              if m && !m.hallucinating?
                m.status_effects << StatusEffect.new(:hallucination, Float::INFINITY)
              end
            end
          end
          monster_phase
        end
      end
    rescue HeroDied
      log("#{@hero.name}は ちからつきた。")
      render
      gameover_message
    end
  end
end

unless $started
  $started = true
  Program.new.initial_menu
end
