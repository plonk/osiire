module Curses
  def flushinp
    Curses.timeout = 0
    nil until Curses.getch == nil
  end
  module_function :flushinp
end

class Curses::Window
  # def rounded_box
  #   win = self
  #   win.box("\0", "\0")
  #   win.setpos(0,0)
  #   win.addstr("╭")
  #   win.setpos(0, win.maxx-1)
  #   win.addstr("╮")
  #   win.setpos(win.maxy-1, 0)
  #   win.addstr("╰")
  #   win.setpos(win.maxy-1,win.maxx-1)
  #   win.addstr("╯")
  # end

  def rounded_box
    box("\0", "\u{104231}")
    setpos(0,0)
    addstr("\u{104230}")
    addstr("\u{104231}" * (maxx - 2))
    addstr("\u{104232}")
    (1..(maxy-2)).each do |y|
      setpos(y, 0)
      addstr("\u{104233}")
      setpos(y, maxx-1)
      addstr("\u{104235}")
    end
    addstr("\u{104234}")
    addstr("\u{104237}" * (maxx - 2))
    addstr("\u{104236}")
  end

  class << self
    alias_method :new_orig, :new

    def new(*args)
      if block_given?
        new_orig(*args).tap do |win|
          begin
            yield(win)
          ensure
            win.close
          end
        end
      else
        new_orig(*args)
      end
    end
  end
end
