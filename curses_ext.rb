class Curses::Window
  def rounded_box
    win = self
    win.box("\0", "\0")
    win.setpos(0,0)
    win.addstr("╭")
    win.setpos(0, win.maxx-1)
    win.addstr("╮")
    win.setpos(win.maxy-1, 0)
    win.addstr("╰")
    win.setpos(win.maxy-1,win.maxx-1)
    win.addstr("╯")
  end
end
