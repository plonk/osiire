module Sound
  module_function

  LETTER_TO_OFFSET_FROM_A = {
    "c" => -9,
    "d" => -7,
    "e" => -5,
    "f" => -4,
    "g" => -2,
    "a" =>  0,
    "b" => 2,
  }

  def key_to_offset_from_a440(key)
    if key =~ /^([a-g])(#?)([0-8])$/
      letter = $1
      sharp = ($2 === "#") ? 1 : 0
      octave = $3.to_i
      offset = (octave - 4) * 12 + LETTER_TO_OFFSET_FROM_A[letter] + sharp
      if offset >= 0
        return offset
      else
        return 256 + offset
      end
    else
      fail "invalid key designation: #{key.inspect}"
    end
  end

  def translate_rest(duration)
    "\e[0;#{duration};0-~" # vol dur note
  end

  def translate_note(duration, note, volume)
    case note
    when String
      note_number = key_to_offset_from_a440(note)
    when Integer
      note_number = note % 256
    else fail
    end
    "\e[#{volume};#{duration};#{note_number}-~"
  end

  def compile(sequence)
    total_duration = 0
    compiled = sequence.map do |command|
      inst, *args = command
      case inst
      when :rest
        duration, = args
        total_duration += duration
        translate_rest(duration)
      when :note
        duration, note, volume = args
        total_duration += duration
        translate_note(duration, note, volume)
      else fail
      end
    end.join
    { tune: compiled, duration: total_duration }
  end

  def play(tune)
    print tune[:tune]
    # flushする必要あり？

    s = tune[:duration].fdiv(1000)
    sleep s
  end
end

module SoundEffects
  module_function

  extend Sound

  def fanfare
    tune = compile([
                     [:note, (800 * 0.6).round, 'c5', 40],
                     [:note, (600 * 0.6).round, 'b4', 40],
                     [:note, (200 * 0.6).round, 'f4', 40],
                     [:note, (400 * 0.6).round, 'a4', 40],
                     [:note, (400 * 0.6).round, 'g4', 40],
                     [:note, (400 * 0.6).round, 'f4', 40],
                     [:note, (400 * 0.6).round, 'd4', 40],

                     # [:note, ( 50 * 0.6).round, 'c4', 40],
                     # [:note, ( 50 * 0.6).round, 'd4', 40],
                     # [:note, ( 50 * 0.6).round, 'c4', 40],
                     # [:note, ( 50 * 0.6).round, 'd4', 40],
                     # [:note, ( 50 * 0.6).round, 'c4', 40],
                     # [:note, ( 50 * 0.6).round, 'd4', 40],
                     # [:note, ( 50 * 0.6).round, 'c4', 40],
                     # [:note, ( 50 * 0.6).round, 'd4', 40],
                     # [:note, ( 50 * 0.6).round, 'c4', 40],
                     # [:note, ( 50 * 0.6).round, 'd4', 40],
                     # [:note, ( 50 * 0.6).round, 'c4', 40],
                     # [:note, ( 50 * 0.6).round, 'd4', 40],
                     # [:note, ( 50 * 0.6).round, 'c4', 40],
                     # [:note, ( 50 * 0.6).round, 'd4', 40],
                     # [:note, ( 33 * 0.6).round, 'c4', 40],
                     # [:note, ( 33 * 0.6).round, 'b3', 40],
                     # [:note, ( 33 * 0.6).round, 'c4', 40],

                     [:note, (400 * 0.6).round, 'c4', 40],
                     [:note, (200 * 0.6).round, 'b3', 40],
                     [:note, (200 * 0.6).round, 'c4', 40],

                     [:note, (400 * 0.6).round, 'e4', 40],
                     [:note, (200 * 0.6).round, 'd4', 40],
                     [:note, (200 * 0.6).round, 'e4', 40],
                     [:note, (800 * 0.6).round, 'd4', 40],
                     [:note, (400 * 0.6).round, 'c4', 40],
                   ])
    play(tune)
  end

  def fanfare2
    tune = compile([
                     [:note, (200/1.75).round, 'c6', 50],
                     [:rest, (200/1.75).round],

                     [:note, (150/1.75).round, 'b5', 40],
                     [:rest, (150/1.75).round],

                     [:note, (100/1.75).round, 'f5', 40],

                     [:note, (100/1.75).round, 'a5', 40],
                     [:rest, (100/1.75).round],
                     [:note, (100/1.75).round, 'g5', 40],
                     [:rest, (100/1.75).round],
                     [:note, (100/1.75).round, 'f5', 40],
                     [:rest, (100/1.75).round],
                     [:note, (100/1.75).round, 'd5', 40],
                     [:rest, (100/1.75).round],

                     [:note, (200/1.75).round, 'c5', 40],
                     [:note, (100/1.75).round, 'b4', 40],
                     [:note, (100/1.75).round, 'c5', 40],
                     [:note, (200/1.75).round, 'e5', 40],
                     [:note, (100/1.75).round, 'd5', 40],
                     [:note, (100/1.75).round, 'e5', 40],
                     [:note, (400/1.75).round, 'd5', 40],
                     [:note, (200/1.75).round, 'c5', 40],
                   ])
    play(tune)
  end

  def fanfare3
    tune = compile([
                     [:note, 800, 'c5', 40],
                     [:note, 600, 'b4', 40],
                     [:note, 200, 'f4', 40],
                     [:note, 400, 'a4', 40],
                     [:note, 400, 'g4', 40],
                     [:note, 400, 'f4', 40],
                     [:note, 400, 'd4', 40],

                     [:note, 50, 'c4', 40],
                     [:note, 50, 'd4', 40],
                     [:note, 50, 'c4', 40],
                     [:note, 50, 'd4', 40],
                     [:note, 50, 'c4', 40],
                     [:note, 50, 'd4', 40],
                     [:note, 50, 'c4', 40],
                     [:note, 50, 'd4', 40],
                     [:note, 50, 'c4', 40],
                     [:note, 50, 'd4', 40],
                     [:note, 50, 'c4', 40],
                     [:note, 50, 'd4', 40],
                     [:note, 50, 'c4', 40],
                     [:note, 50, 'd4', 40],
                     [:note, 33, 'c4', 40],
                     [:note, 33, 'b3', 40],
                     [:note, 33, 'c4', 40],

                     [:note, 400, 'e4', 40],
                     [:note, 200, 'd4', 40],
                     [:note, 200, 'e4', 40],
                     [:note, 800, 'd4', 40],
                     [:note, 400, 'c4', 40],
                   ])
    play(tune)
  end

  def gameover
    tune = compile([
                     [:note, 400, 12, 40],
                     [:note, 400, 8, 40],
                     [:note, 400, 5, 40],
                     [:note, 400, 3, 40],

                     [:note, 50, 2, 40],
                     [:note, 50, 3, 40],
                     [:note, 50, 2, 40],
                     [:note, 50, 3, 40],
                     [:note, 50, 2, 40],
                     [:note, 50, 3, 40],
                     [:note, 50, 2, 40],
                     [:note, 50, 3, 40],
                     [:note, 50, 2, 40],
                     [:note, 50, 3, 40],
                     [:note, 50, 2, 40],
                     [:note, 50, 3, 40],

                     [:note, 600, 2, 40],

                     [:note, 380, 3, 40],
                     [:rest, 20],
                     [:note, 1600, 3, 40],
                   ])
    play(tune)
  end

  def trapdoor
    tune = compile([
                     *(30).downto(18).map { |offset|
                       [:note, 50, offset, 40]
                     },
                     [:note, 50, 17, 40],
                     [:note, 50, 18, 40],
                     [:note, 50, 17, 40],
                     [:note, 50, 18, 40],
                     [:note, 50, 17, 40],
                     [:note, 50, 18, 40],
                     [:note, 50, 17, 40],
                     [:note, 50, 18, 40],
                     [:note, 50, 17, 40],
                     [:note, 50, 18, 40],
                     [:note, 200, 17, 40],
                   ])
    play(tune)
  end

  def staircase
    print "\e[0;100;0-~"
    print "\e[100;2;208-~"
    print "\e[0;250;0-~"
    print "\e[100;2;206-~"
    print "\e[0;250;0-~"
    print "\e[100;2;220-~"
    print "\e[0;250;0-~"
    print "\e[100;2;218-~"
    sleep 1
  end

  def partyroom
    print "\e[0;60;8-~" # 無音

    print "\e[50;30;8-~"
    print "\e[50;30;252-~"
    print "\e[50;30;7-~"
    print "\e[50;30;251-~"
    print "\e[50;30;6-~"
    print "\e[50;30;250-~"
    print "\e[50;30;5-~"
    print "\e[50;30;249-~"
    print "\e[50;30;4-~"
    print "\e[50;30;248-~"
    print "\e[50;30;3-~"
    print "\e[50;30;247-~"
    print "\e[50;30;8-~"
    print "\e[50;30;252-~"
    print "\e[50;30;7-~"
    print "\e[50;30;251-~"
    print "\e[50;30;6-~"
    print "\e[50;30;250-~"
    print "\e[50;30;5-~"
    print "\e[50;30;249-~"
    print "\e[50;30;4-~"
    print "\e[50;30;248-~"
    print "\e[50;30;3-~"
    print "\e[50;30;247-~"
    sleep 1
  end

  def hit
    print "\e[0;60;247-~"
    print "\e[50;30;247-~"
    print "\e[0;30;247-~"
    print "\e[50;30;3-~"
    #sleep 0.12
  end

  def miss
    print "\e[0;60;0-~"
    print "\e[40;100;9-~"
    print "\e[0;25;9-~"
    print "\e[40;100;6-~"
    #sleep 0.285
  end

  def footstep
    print "\e[0;50;0-~"
    print "\e[100;2;240-~"
    sleep 0.052
  end

  def heal
    print "\e[50;50;3-~"
    print "\e[50;50;7-~"
    print "\e[50;50;10-~"
    print "\e[50;50;15-~"
    #sleep 0.2
  end

  def teleport
    print "\e[0;60;0-~"

    tune = compile([
                     [:note, 15, 'a3', 40],
                     [:note, 15, 'b3', 40],
                     [:note, 15, 'c4', 40],
                     [:note, 15, 'd4', 40],
                     [:note, 15, 'e4', 40],
                     [:note, 15, 'f4', 40],
                     [:note, 15, 'g#4', 40],
                     [:note, 15, 'a4', 40],
                     [:note, 15, 'g#4', 40],
                     [:note, 15, 'f4', 40],
                     [:note, 15, 'e4', 40],
                     [:note, 15, 'd4', 40],
                     [:note, 15, 'c4', 40],
                     [:note, 15, 'b3', 40],
                     [:note, 15, 'a3', 40],
                     [:rest, 50],
                   ] * 4)
    play(tune)
  end

  def magic
    print "\e[0;60;0-~"

    tune = compile([
                     [:note, 100, 'a4', 40],
                     [:note, 100, 'c5', 40],
                     [:note, 100, 'b4', 40],
                     [:note, 100, 'd5', 40],
                     [:note, 100, 'c5', 40],
                     [:note, 100, 'd#5', 40],
                   ])
    play(tune)
  end

  def weapon
    print "\e[0;60;0-~"

    tune = compile([
                     [:note, 20, 'c5', 40],
                     [:note, 20, 'c#6', 40],
                     [:rest, 20],
                     [:note, 20, 'c5', 40],
                     [:note, 20, 'c#6', 40],
                   ])
    play(tune)
  end

  def strew
    print "\e[0;30;3-~"
    print "\e[50;30;3-~"
    print "\e[0;30;3-~"
    print "\e[50;30;15-~"
    print "\e[0;30;3-~"
    print "\e[50;30;3-~"
    print "\e[0;30;3-~"
    print "\e[50;30;15-~"
    print "\e[0;30;3-~"
    print "\e[50;30;3-~"
    print "\e[0;30;3-~"
    print "\e[50;30;15-~"
    print "\e[0;30;3-~"
    print "\e[50;30;3-~"
    print "\e[0;30;3-~"
    print "\e[50;30;15-~"

    sleep 0.48
  end

  def earthquake1
    print "[30;1000;196-~"
    print "[25;1000;196-~"
    print "[20;1000;196-~"
    print "[15;500;196-~"
    sleep 3.5
  end

  def earthquake2
    print "[30;1000;196-~"
    print "[40;1000;196-~"
    print "[30;1000;196-~"
    print "[15;1000;196-~"
    sleep 4.0
  end

  def earthquake3
    print "[25;1000;196-~"
    print "[50;1000;196-~"
    print "[80;1000;196-~"
    print "[80;2000;196-~"
    print "[100;1000;196-~"
    sleep 6.0
  end

end
