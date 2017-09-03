class Menu
  def initialize(items, opts = {})
    @items = items
    @y = opts[:y] || 0
    @x = opts[:x] || 0
    @cols = opts[:cols] || 25
    @index = 0
    winheight = [3, @items.size + 2].max
    @win = Curses::Window.new(winheight, @cols, @y, @x) # lines, cols, y, x
  end

  def close
    @win.clear
    @win.refresh
    @win.close
  end

  def choose
    @win.clear
    @win.box("|", "-", "-")

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
          @win.addstr(" " + @items[i].to_s)
          if i == @index
            @win.attroff(Curses::A_BOLD)
          end
        end
        @win.setpos(@index + 1,1)
        c = @win.getch
        case c
        when 'j'
          @index = [@index + 1, @items.size - 1].min
        when 'k'
          @index = [@index - 1, 0].max
        when 'q'
          return [:cancel]
        when 10
          return [:chosen, @items[@index]]
        end
      end
    end
  end
end
