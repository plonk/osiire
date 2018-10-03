require 'curses'
require_relative 'curses_ext'

module NamingScreen
  module_function

  COMMAND_ROW = ["かなカナ英数", "おまかせ", "けす", "おわる"]
  LAYERS = [
    [
      "あいうえおはひふへほ",
      "かきくけこまみむめも",
      "さしすせそやゆよっー",
      "たちつてとらりるれろ",
      "なにぬねのわをん゛゜",
      "ぁぃぅぇぉゃゅょ？　"
    ],

    [
      "アイウエオハヒフヘホ",
      "カキクケコマミムメモ",
      "サシスセソヤユヨッー",
      "タチツテトラリルレロ",
      "ナニヌネノワヲン゛゜",
      "ァィゥェォャュョ　　"
    ],

    [
      "０１２３４５６７８９",
      "ＡＢＣＤＥＦＧＨＩＪ",
      "ＫＬＭＮＯＰＱＲＳＴ",
      "ＵＶＷＸＹＺ＋－！？",
      "ａｂｃｄｅｆｇｈｉｊ",
      "ｋｌｍｎｏｐｑｒｓｔ",
      "ｕｖｗｘｙｚ　　　　",
    ],
  ]

  DAKUON_TABLE = {
    "う" => "ゔ",
    "は" => "ば",
    "ひ" => "び",
    "ふ" => "ぶ",
    "へ" => "べ",
    "ほ" => "ぼ",
    "か" => "が",
    "き" => "ぎ",
    "く" => "ぐ",
    "け" => "げ",
    "こ" => "ご",
    "さ" => "ざ",
    "し" => "じ",
    "す" => "ず",
    "せ" => "ぜ",
    "そ" => "ぞ",
    "た" => "だ",
    "ち" => "ぢ",
    "つ" => "づ",
    "て" => "で",
    "と" => "ど",

    "ウ" => "ヴ",
    "ハ" => "バ",
    "ヒ" => "ビ",
    "フ" => "ブ",
    "ヘ" => "ベ",
    "ホ" => "ボ",
    "カ" => "ガ",
    "キ" => "ギ",
    "ク" => "グ",
    "ケ" => "ゲ",
    "コ" => "ゴ",
    "サ" => "ザ",
    "シ" => "ジ",
    "ス" => "ズ",
    "セ" => "ゼ",
    "ソ" => "ゾ",
    "タ" => "ダ",
    "チ" => "ヂ",
    "ツ" => "ヅ",
    "テ" => "デ",
    "ト" => "ド",
  }

  HANDAKUON_TABLE = {
    "は" => "ぱ",
    "ひ" => "ぴ",
    "ふ" => "ぷ",
    "へ" => "ぺ",
    "ほ" => "ぽ",

    "ハ" => "パ",
    "ヒ" => "ピ",
    "フ" => "プ",
    "ヘ" => "ペ",
    "ホ" => "ポ",
  }

  OMAKASE_NAMES = [
    "すたちゅー",
    "よてえもん",
    "ＸＡＸＡ",
    "ヌヌー",
    "ばんたけ",
    "ＯＬ",
    "あぐん",
  ]

  def run(default_name = nil)
    name = default_name || ""
    layer_index = 0
    old_layer = nil
    y, x = 0, 0
    tm = 3 # (Curses.lines - 13)/2 # top margin

    next_omakase = proc do
      i = OMAKASE_NAMES.index(name)
      if i
        i = (i + 1) % OMAKASE_NAMES.size
        name = OMAKASE_NAMES[i]
      else
        name = OMAKASE_NAMES[0]
      end
    end

    field = Curses::Window.new(3, 14, tm+0, (Curses.cols - 14)/2) # lines, cols, y, x
    field.rounded_box
    field.setpos(0, 3)
    field.addstr("なまえ？")
    update_name = proc do
      s = name + "＊" * (6 - name.size )
      field.setpos(1, 1)
      field.addstr(s)
      field.refresh
    end
    update_name.()

    keyboard = Curses::Window.new(10, 44, tm+3, (Curses.cols - 44)/2)
    keyboard.keypad(true)

    handle_input = proc do |c|
      case c
      when 9 # Tab
        handle_input.('l')
      when Curses::KEY_BTAB
        handle_input.('h')
      when 'h', Curses::KEY_LEFT
        x = (x - 1) % (y == 0 ? COMMAND_ROW.size : LAYERS[layer_index][y-1].size)
      when 'j', Curses::KEY_DOWN
        old_length = (y == 0 ? COMMAND_ROW.size : LAYERS[layer_index][y-1].size)
        y = (y + 1) % (LAYERS[layer_index].size + 1)
        new_length = (y == 0 ? COMMAND_ROW.size : LAYERS[layer_index][y-1].size)
        x = (x.fdiv(old_length) * new_length).floor
      when 'k', Curses::KEY_UP
        old_length = (y == 0 ? COMMAND_ROW.size : LAYERS[layer_index][y-1].size)
        y = (y - 1) % (LAYERS[layer_index].size + 1)
        new_length = (y == 0 ? COMMAND_ROW.size : LAYERS[layer_index][y-1].size)
        x = (x.fdiv(old_length) * new_length).floor
      when 'l', Curses::KEY_RIGHT
        x = (x + 1) % (y == 0 ? COMMAND_ROW.size : LAYERS[layer_index][y-1].size)
      when 'y'
        handle_input.('h')
        handle_input.('k')
      when 'u'
        handle_input.('l')
        handle_input.('k')
      when 'b'
        handle_input.('h')
        handle_input.('j')
      when 'n'
        handle_input.('l')
        handle_input.('j')
      when 8, Curses::KEY_DC, 'x'
        # Backspace, Delete Character or x
        name = name[0..-2]
      when 'q'
        return nil
      when 10 # Enter
        if y == 0
          case COMMAND_ROW[x]
          when "かなカナ英数"
            layer_index = (layer_index + 1) % LAYERS.size
          when "おまかせ"
            name = next_omakase.()
          when "けす"
            name = name[0..-2]
          when "おわる"
            unless name.empty?
              return name
            end
          end
        else
          c = LAYERS[layer_index][y-1][x]
          if c == "゛" && DAKUON_TABLE[name[-1]]
            name[-1] = DAKUON_TABLE[name[-1]]
          elsif c == "゜" && HANDAKUON_TABLE[name[-1]]
            name[-1] = HANDAKUON_TABLE[name[-1]]
          else
            if name.size == 6
              name[5] = c
            else
              name += c
            end
          end
        end
      else
        # fail "#{c.inspect}"
      end
    end

    begin
      while true
        update_name.()

        if old_layer != layer_index
          old_layer = layer_index

          keyboard.clear
          keyboard.rounded_box
          keyboard.setpos(1, 1)
          keyboard.addstr("  " + COMMAND_ROW.join("　"))

          LAYERS[layer_index].each.with_index(+2) do |row, ypos|
            keyboard.setpos(ypos, 3)
            keyboard.addstr(row.chars.join("　"))
          end
        end

        if y == 0
          keyboard.setpos(1, 3 + COMMAND_ROW[0...x].join("").size*2 + x*2)
        else
          keyboard.setpos(1 + y, 3 + 4*x)
        end

        c = keyboard.getch
        handle_input.(c)
      end
    ensure
      field.close
      keyboard.close
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
  name = NamingScreen.run
  Curses.close_screen
  p name
end
