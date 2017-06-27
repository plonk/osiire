require 'curses'
include Curses

class Program
  def show_map
    win = Window.new(lines, cols, 0, 0)
    @map.each.with_index do |line, i|
      line.each.with_index do |ch, j|
        win.setpos(i, j)
        win.addstr(ch)
      end
    end
    win.refresh
    win.getch
    win.close
  end

  # def show_message(message)
  #   win = Window.new(lines, cols, 0, 0)
  #   win.box(?|, ?-)
  #   win.setpos(1, 1)
  #   win.addstr(message)
  #   win.refresh
  #   win.getch
  #   win.close
  # end

  def load_map
    txt = File.read("map.txt")
    @map = txt.each_line.map { |l| l.chomp!.each_char.to_a }
  end

  def main
    load_map

    init_screen

    unless @map.size.between?(0, lines) and
           @map[0].size.between?(0, cols)
      fail 'map too large'
    end

    begin
      crmode
      show_map
    ensure
      close_screen
    end
  end
end

prog = Program.new
prog.main
