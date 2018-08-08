require 'curses'
require_relative 'curses_ext'
require_relative 'menu'
require_relative 'hero'
require_relative 'item'

class Shop
  MERCHANDISE = [
    ["大きなパン", nil, 500],
    ["人形よけの指輪", nil, 20_000],
    ["ワナ抜けの指輪", nil, 10_000],
    ["毒けしの指輪", nil, 5_000],
    ["盗賊の指輪", nil, 10_000],
    ["メタルヨテイチの剣", 7, 10_000],
    ["銀の盾", 5, 8_000],
    ["ドラゴンキラー", 5, 8_000],
    ["結界の巻物", nil, 5_000],
    ["爆発の巻物", nil, 1_500],
    ["あかりの巻物", nil, 1_000],
    ["高級薬草", nil, 500],
    ["薬草", nil, 250],
    ["毒けし草", nil, 1500],
    ["幸せの種", nil, 5000],
    ["ちからの種", nil, 3000],
    ["メッキの巻物", nil, 4_000],
    ["木の矢", 25, 2500],
    ["同定の巻物", nil, 500],
  ]

  def initialize(hero, display_item, addstr_ml)
    @hero = hero

    # 関数
    @display_item = display_item
    @addstr_ml = addstr_ml

    @msgwin = Curses::Window.new(3, 40, 0, 0)
    @merchandise = MERCHANDISE.sample(6).sort_by(&:last)
    @goldwin = Curses::Window.new(3, 17, 0, 40)
  end

  def confirm_purchase(price)
    update_message("#{price}Gだけどいいかい？")
    menu = Menu.new(["買う", "やっぱり買わない"], cols: 20, y: 3, x: 0)
    begin
      cmd, arg = menu.choose
      if cmd == :chosen && arg == "買う"
        return true
      else
        return false
      end
    ensure
      menu.close
    end
  end

  def make_item(name, number)
    item = Item.make_item(name)
    if number
      item.number = number
    end
    item.cursed = false
    return item
  end

  def merchandise_screen
    cols = 30
    menu = Menu.new(@merchandise, cols: cols, y: 3, x: 0,
                    dispfunc: proc { |win, (name, number, price)|
                      item = make_item(name, number)
                      @addstr_ml.(win, ["span", @display_item.(item), " ", price.to_s, "G"])
                    })
    begin
      cmd, arg = menu.choose
      case cmd
      when :chosen
        name, number, price = arg
        if @hero.gold < price
          update_message("お金が足りないよ。")
        else
          if confirm_purchase(price)
            item = make_item(name, number)
            if @hero.add_to_inventory(item)
              update_message("まいどあり！")
              @hero.gold -= price
              update_gold
            else
              update_message("持ち物がいっぱいだよ！")
            end
          end
        end
      when :cancel
        return
      end
    ensure
      menu.close
    end
  end

  def update_message(msg)
    @msgwin.clear
    @msgwin.rounded_box
    @msgwin.setpos(1, 1)
    @msgwin.addstr(" \u{10422e}\u{10422f} #{msg}")
    @msgwin.refresh
  end

  def update_gold
    @goldwin.clear
    @goldwin.rounded_box
    @goldwin.setpos(1,1)
    @goldwin.addstr("所持金 %7dG" % [@hero.gold])
    @goldwin.refresh
  end

  def actions_for_item(item)
    ["すてる"]
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

    #Curses.flushinp
    win.getch
    win.clear
    win.refresh
    win.close
  end

  def item_action_menu(item)
    action_menu = Menu.new(actions_for_item(item), y: 3, x: 27, cols: 9)
    begin
      c, *args = action_menu.choose
      case c
      when :cancel
        return nil
      when :chosen
        c, = args
        return c
      else fail
      end
    ensure
      action_menu.close
    end
  end

  def inventory_screen
    dispfunc = proc { |win, item|
      prefix = if @hero.weapon.equal?(item) ||
                @hero.shield.equal?(item) ||
                @hero.ring.equal?(item) ||
                @hero.projectile.equal?(item)
               "E"
             else
               " "
             end
      @addstr_ml.(win, ["span", prefix, item.char, @display_item.(item)])
    }

    menu = nil
    item = c = nil

    loop do
      item = c = nil
      menu = Menu.new(@hero.inventory,
                      y: 3, x: 0, cols: 27,
                      dispfunc: dispfunc,
                      title: "持ち物 [s]ソート",
                      sortable: true)
      command, *args = menu.choose

      case command
      when :cancel
        #Curses.beep
        return
      when :chosen
        item, = args

        c = item_action_menu(item)
        if c.nil?
          next
        end
      when :sort
        @hero.sort_inventory!
      end

      if item and c
        case c
        when "すてる"
          @hero.remove_from_inventory(item)
          menu.close
        else fail 
        end
      end
    end
  ensure
    menu.close
  end

  def run
    update_message("何か買って行かないかい？")
    update_gold

    menu = Menu.new(["買い物をする", "持ち物を見る", "立ち去る"],
                    cols: 20, y: 3, x: 0)
    begin
      while true
        cmd, arg = menu.choose
        case cmd
        when :chosen
          case arg
          when "買い物をする"
            merchandise_screen
          when "持ち物を見る"
            inventory_screen
          when "立ち去る"
            bye
            return
          end
        when :cancel
          bye
          return
        end
      end
    ensure
      menu.close
    end
  end

  def bye
  end
end

if __FILE__ == $0
  Curses.init_screen
  hero = Hero.new(nil, nil, 15, 15, 8, 8, 0, 0, 100.0, 100.0, 1)
  hero.gold = 100_000
  shop = Shop.new(hero)
  shop.run
end
