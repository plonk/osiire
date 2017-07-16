require 'pp'

require_relative 'room'
require_relative 'level'


class Game
  def main
    @hero = Hero.new(0, 0)
    new_level

    play_level
  end

  def new_level
    @level = Level.new

    x, y = @level.get_random_place(:FLOOR)
    @hero.x, @hero.y = x, y

    x, y = @level.get_random_place(:FLOOR)
    @level.put_object(x, y, StairCase.new)
  end

  def play_level
    @quitting = false

    # メインループ
    until @quitting
      # 視界
      fov = @level.fov(@hero)
      @level.mark_explored(fov)
      @level.light_up(fov)

      puts render

      c = read_command
      @level.darken(@level.fov(@hero))
      dispatch_command(c)
    end
  end

  def read_command
    return STDIN.read(1)
  end

  # def read_command
  #   loop do
  #     line = gets

  #     if line.nil?
  #       return 'q'
  #     end

  #     line.chomp!
  #     if line.empty?
  #       redo
  #     end
  #     return line[0]
  #   end
  # end

  def dispatch_command(c)
    case c
    when 'h','j','k','l','y','u','b','n'
      hero_move(c)
    when '>'
      go_downstairs
    when 'q'
      @quitting = true
    end
  end

  def go_downstairs
    if @level.cell(@hero.x, @hero.y).objects.any? { |elt| elt.is_a?(StairCase) }
      new_level
    end
  end

  def hero_move(c)
    vec = { 'h' => [-1,  0],
            'j' => [ 0, +1],
            'k' => [ 0, -1],
            'l' => [+1,  0],
            'y' => [-1, -1],
            'u' => [+1, -1],
            'b' => [-1, +1],
            'n' => [+1, +1] }[c]
    x, y = vec
    if x * y != 0
      allowed = @level.passable?(@hero, @hero.x + x, @hero.y + y) &&
                @level.passable?(@hero, @hero.x + x, @hero.y) &&
                @level.passable?(@hero, @hero.x, @hero.y + y)
    else
      allowed = @level.passable?(@hero, @hero.x + x, @hero.y + y)
    end

    if allowed
      @hero.x += x
      @hero.y += y
    end
  end

  def render
    (0 ... @level.height).map do |y|
      (0 ... @level.width).map do |x|
        if @hero.x == x && @hero.y == y
          '@'
        else
          @level.dungeon_char(x, y)
        end
      end.join + "\n"
    end.join
  end
end

system('stty cbreak -echo')
at_exit { system('stty sane') }
Game.new.main

