class Game
  def initialize
    @guesses_allowed = 12
    @guesses = []
    @responses = []
    @human_codebreaker = nil
    @code = nil
    @candidates = initial_candidates
    @left_tab = 11
    @right_tab = 34
    @center_tab = 25
    # @center_tab = ((@left_tab + @right_tab) / 2.0).ceil
    @line_width = @center_tab * 2 - 1
  end
  attr_reader :guesses_allowed, :left_tab, :right_tab, :center_tab, :line_width
  attr_accessor :guesses, :responses, :human_codebreaker, :code, :candidates

  def initial_candidates
    list = []

    ('A'..'F').each do |n1|
      ('A'..'F').each do |n2|
        ('A'..'F').each do |n3|
          ('A'..'F').each do |n4|
            list.push("#{n1}#{n2}#{n3}#{n4}")
          end
        end
      end
    end

    list.shuffle!
    starting_guesses = ['AABB', 'CCDD', 'EEFF'].shuffle
    starting_guesses.map! {|guess| guess.split('').shuffle.join('') }
    starting_guesses.each { |guess| list.unshift(list.delete(guess))}
    list
  end

  def feedback(code_string, guess_string)
    code = code_string.upcase.split('').first(4)
    guess = guess_string.upcase.split('').first(4)
    tally = Hash.new(0)

    guess.each_with_index do |letter, index|
      right_place = index if letter == code[index]
      if right_place
        tally[:right_places] += 1
        guess[right_place] = nil
        code[right_place] = nil
      end
    end
    compact!(guess, code)

    guess.each_with_index do |letter, index|
      wrong_place = code.index(letter)
      if wrong_place
        tally[:wrong_places] += 1
        guess[index] = nil
        code[wrong_place] = nil
      end
    end
    compact!(guess, code)

    tally[:extraneous] = guess.length

    ("*" * tally[:right_places]) + ("o" * tally[:wrong_places] + ("." * tally[:extraneous]))
  end

  def compact!(*arrays)
    arrays.each {|array| array.compact!}
  end

  def play
    introduce_game
    choose_roles
    play_game
  end

  def replay
    initialize
    choose_roles
    play_game
  end

  def print_center(array_of_lines)
    array_of_lines.each do |line|
      if line.kind_of? String
        output = line.center(line_width)
      elsif line.kind_of? Array
        (left, center, right) =
          case line.size
          when 1 then ['', line[0], '']
          when 2 then [line[0], '', line[1]]
          when 3 then line
          when (4..) then [line[0], line[1..-2].join(' '), line[-1]]
          end

        triple_aligned = center.center(line_width)
        triple_aligned[left_tab, left.length] = left
        triple_aligned[right_tab, right.length] = right

        outside_space = (line_width - center.length)
        left_space = (outside_space/2.0).floor
        right_space = (outside_space/2.0).ceil
        left_hugging_center = left.rjust(left_space)
        right_hugging_center = right.ljust(right_space)
        centered = left_hugging_center + center + right_hugging_center

        # centered = (left + center + right).center(line_width)
        # centered = center.center(line_width)
        # center_left_edge = (center_tab - (center.length / 2.0).floor) - 1
        # center_right_edge = (center_tab + (center.length / 2.0).ceil) - 1
        # centered[center_left_edge - left.length, left.length] = left
        # centered[center_right_edge, right.length] = right

        room_for_left_and_center_alignment = center == '' || (center_tab - left_tab > left.length)

        output =
          room_for_left_and_center_alignment ?
            triple_aligned :
            centered
        end
      puts output
    end
  end

  def prompt_center(hash = {'' => ''})
    choice = nil
    until hash.keys.include?(choice) do
      print ' ' * (center_tab - 1)
      choice = gets.chomp.upcase
    end
    hash[choice]
  end
  def introduce_game
    introduction = [
      '',
      "...........................",
      %w[.... FEED- ....],
      %w[o... BACC o...],
      %w[*...                   oo..],
      %w[oo..       (a          ooo.],
      %w[*o..      text-        oooo],
      %w[**..      based        *...],
      %w[ooo.     tribute       *o..],
      %w[*oo.       to          *oo.],
      %w[**o.       the         *ooo],
      %w[***.     classic       **..],
      %w[oooo       code-       **o.],
      %w[*ooo     breaking,     **oo],
      %w[**oo       game,       ***.],
      %w[****    Master Mind)   ****],
      %w[***************************],
      "",
      "One player MAKES a CODE",
      "as a sequence of 4 letters,",
      "each from the set, ABCDEF.",
      "",
      "The other player BREAKS the CODE",
      "in a maximum of #{guesses_allowed} guesses.",
      "",
      "Each guess generates feedback such as",
      ""                                      ,
      %w[*o.. or **oo],
      "",
      "which tallies:",
      "",
      ["*  (correctly-placed letters)", '', ''],
      ["o  (out-of-place letters)", '', ''],
      [".  (superfluous letters)", '', ''],
      ""
    ]
    print_center(introduction)
    prompt_center
  end

  def choose_roles
    print_center([
      "Choose your role:",
      ["M. Make a Code", "     ", "B. Break the Code"]
    ])

    self.human_codebreaker =
     prompt_center({
      "B" => true,
      "M" => false,
     })
  end

  def play_game
    make_code
    break_code
    puts

    if guesses.last == code
      winner_broke =
        self.human_codebreaker ?
        "Congratulations! You broke the " :
        "\nWhoa! The computer broke your "
      how_soon = guesses.count > 1 ?
       "in #{guesses.count} guesses." :
       "on the first guess!"
      print "#{winner_broke} code #{how_soon}\n"
    else
      print_center([
        "So close! And yet so far.",
        "",
        "The code was #{code}."
      ])
    end

    puts
    print_center([
      "Play again?",
      "(Y/N)"
    ])
    action = prompt_center({
      'Y' => :replay,
      'N' => :exit
    })
    send(action)
  end

  def make_code
    if human_codebreaker
      self.code = random_code
    else
      print "\nType your code here: "
      choice = ''
      until validate_code(choice)
        choice = gets.chomp.upcase
      end
      self.code = choice
    end
  end

  def random_code
    letters = %w[A B C D E F]
    code = ''
    4.times {code << letters.sample}
    code
  end

  def validate_code(code)
    code.length == 4 && code.split('').all? {|n| %w[A B C D E F].include?(n.upcase) }
  end

  def break_code
    print_center([
      '',
      %w[GUESS (case- FEED-],
      ['', 'insensitive)', 'BACC'],
      ''
    ])
    # print "\n"
    # puts "           GUESS    (case-        FEED-   "
    # puts "                  insensitive)    BACC    "
    # puts
    (1..guesses_allowed).each do |i|
      puts "Make your final guess!\n" if i == guesses_allowed
      print "       "
      print " " if i < 10
      print "#{i}. "
      make_guess
      break if guesses.last == code
      consolidate_guesses unless human_codebreaker
    end
  end

  def make_guess
    if human_codebreaker
      guesses.push(gets.chomp.upcase)
    else
      guesses.push(candidates.first || 'WXYZ')
      print "#{guesses.last}\n"
    end

    responses.push feedback(code, guesses.last)
    print "                      `==>        #{responses.last}"
    gets unless guesses.length == 10 || code == guesses.last || human_codebreaker
    print "\n" if human_codebreaker
  end

  def consolidate_guesses
    candidates.shift
    candidates.each_with_index do |possible_guess, i|
      unless feedback(possible_guess, guesses.last) == feedback(code, guesses.last)
        self.candidates[i] = nil
      end
    end
    candidates.compact!
  end
end

new_game = Game.new
new_game.play
