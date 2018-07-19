require_relative 'curses_ext'

class Menu
  attr_accessor :items

  def initialize(items, opts = {})
    @items = items
    @y = opts[:y] || 0
    @x = opts[:x] || 0
    @cols = opts[:cols] || 25
    @index = 0
    winheight = [3, @items.size + 2].max
    @win = Curses::Window.new(winheight, @cols, @y, @x) # lines, cols, y, x
    @win.keypad(true)
    @dispfunc = opts[:dispfunc] || :to_s.to_proc
    @title = opts[:title] || ""
    @sortable = opts[:sortable] || false
  end

  def close
    @win.clear
    @win.refresh
    @win.close
  end


  def choose
    @win.clear
    @win.rounded_box
    @win.setpos(0, 1)
    @win.addstr(@title)

    case @items.size
    when 0
      @win.setpos(1, 1)
      @win.attron(Curses::A_BOLD)
      @win.addstr(" 何も持っていない")
      @win.attroff(Curses::A_BOLD)
      @win.setpos(1, 1)
      @win.refresh
      @win.getch
      return [:cancel]
    else
      loop do
        (0 ... @items.size).each do |i|
          @win.setpos(i + 1, 1)
          if i == @index
            @win.attron(Curses::A_BOLD)
          end
          @win.addstr(" " + @dispfunc.call(@items[i]))
          if i == @index
            @win.attroff(Curses::A_BOLD)
          end
        end
        @win.setpos(@index + 1,1)
        c = @win.getch
        case c
        when 'j', Curses::KEY_DOWN
          @index = (@index + 1) % @items.size
        when 'k', Curses::KEY_UP
          @index = (@index - 1) % @items.size
        when 's'
          if @sortable
            return [:sort]
          end
        when 'q'
          return [:cancel]
        when 10
          return [:chosen, @items[@index]]
        end
      end
    end
  end
end
