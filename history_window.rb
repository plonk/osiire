require 'curses'
require_relative 'curses_ext'

class HistoryWindow
  def initialize(history, disp_func)
    @history = history
    @top = [@history.size - 22, 0].max
    @disp_func = disp_func
  end

  def run
    Curses.curs_set(0)
    Curses::Window.new(24, 80, 0, 0) do |win|
      win.keypad(true)
      while true
        win.rounded_box
        win.setpos(0, 1)
        win.addstr("メッセージ履歴")

        @top.upto(@history.size-1).with_index(1) do |i, y|
          if y == 23
            break
          end
          win.setpos(y, 1)
          @disp_func.(win, @history[i])
        end

        c = win.getch
        case c
        when 'j', Curses::KEY_DOWN
          if (@history.size - @top) <= 22
            #Curses.beep
          else
            @top = [@top+1, @history.size].min
          end
        when 'k', Curses::KEY_UP
          if @top == 0
            #Curses.beep
          else
            @top = [@top-1, 0].max
          end
        when 'q'
          return
        end
        win.clear
      end
    end
  ensure
    Curses.curs_set(1)
  end
end

if __FILE__ == $0
  Curses.init_screen
  hist = ["hoge", "fuga"]
  w = HistoryWindow.new(hist)
  w.run
end
