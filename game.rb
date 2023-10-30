class Game
  def initialize
    @guesses_allowed = 12
    @human_codebreaker = nil
    @code = nil
    @candidates = initial_candidates
    @guesses = []
    @responses = []
    @left_tab = 11
    @right_tab = 34
    @center_tab = 25
    @line_width = @center_tab * 2#- 1
  end
  attr_reader :guesses_allowed, :left_tab, :right_tab, :center_tab, :line_width, :all_codes, :all_codes_hash
  attr_accessor :guesses, :responses, :human_codebreaker, :code, :candidates

  def all_codes
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

    list
  end

  def all_codes_hash
    all_codes.map {|code| [code, code]}.to_h
  end

  def initial_candidates
    list = all_codes
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
    guess.compact!
    code.compact!

    guess.each_with_index do |letter, index|
      wrong_place = code.index(letter)
      if wrong_place
        tally[:wrong_places] += 1
        guess[index] = nil
        code[wrong_place] = nil
      end
    end
    guess.compact!
    code.compact!

    tally[:extraneous] = guess.length

    ("*" * tally[:right_places]) + ("o" * tally[:wrong_places] + ("." * tally[:extraneous]))
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

  def print_center(*lines, final_whitespace: "\n")
    lines.each_with_index do |line|
      if line.kind_of? String
        output = line.center(line_width)
      elsif line.kind_of? Array
        left, center, right =
          case line.size
          when 1 then ['', line[0], '']
          when 2 then [line[0], '', line[1]]
          when 3 then line[0..2]
          when 4.. then [line[0], line[1..-2].join(' '), line[-1]]
          end

        left_and_center_collide = (left_tab + left.length >= center_tab) && center.length > 0

        if left_and_center_collide
          left_width = ((line_width - center.length)/2.0).floor
          right_width = ((line_width - center.length)/2.0).ceil

          left_hugging_center = left.rjust(left_width)
          right_hugging_center = right.ljust(right_width)

          output = left_hugging_center + center + right_hugging_center
        else
          output = center.center(line_width)
          output[left_tab, left.length] = left
          output[right_tab, right.length] = right
        end
      end

      if (index = lines.length)
        print output.rstrip + final_whitespace
      else
        puts output
      end
    end
  end

  def prompt(menu, prompt: ' ' * (center_tab - 1))
    choice = nil
    loop do
      print prompt
      choice = gets.chomp.upcase
      break unless menu[choice] == nil
    end
    menu[choice]
  end

  def introduce_game
    puts
    print_center(
      ("." * 27),
      %w[....      FEED-        ....],
      %w[o...      BACC         o...],
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
      ["****", "Master Mind)", "****"],
      ("*" * 27),
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
      [".  (superfluous letters)", '', '']
    )
    puts
    prompt(Hash.new(''))
  end

  def choose_roles
    print_center(
      "Choose your role:",
      ["M. Make a Code", "     ", "B. Break the Code"]
    )

    self.human_codebreaker = prompt({'B'=>true, 'M'=>false})
     puts
  end

  def play_game
    make_code
    break_code
    puts

    if guesses.last == code
      winner_broke =
        self.human_codebreaker ?
        "Congratulations! You broke the" :
        "\nWhoa! The computer broke your"
      how_soon = guesses.count > 1 ?
       "in #{guesses.count} guesses." :
       "on the first guess!"
      print "#{winner_broke} code #{how_soon}\n"
    else
      print_center(
        "So close! And yet so far.",
        "",
        "The code was #{code}."
      )
    end

    puts
    print_center(
      "Play again?",
      "(Y/N)"
    )
    action = prompt({'Y'=>:replay, 'N'=>:exit})
    puts
    send(action)
  end

  def make_code
    if human_codebreaker
      self.code = all_codes.sample
    else
      print_center("Put your code here:")
      self.code = prompt(all_codes_hash, prompt: ' ' * (center_tab - 3))
    end
  end

  def break_code
    print_center(
      '',
      %w[GUESS (case- FEED-],
      ['', 'insensitive)', 'BACC'],
      ''
    )
    while guesses.count <= guesses_allowed
      puts "Make your final guess!\n" if guesses.count == guesses_allowed
      make_guess
      break if guesses.last == code
      consolidate_guesses unless human_codebreaker
    end
  end

  def make_guess
    if human_codebreaker
      guesses.push(
        prompt(
          all_codes_hash,
          prompt: "#{guesses.count + 1}. ".rjust(left_tab)
        )
      )
    else
      print "#{guesses.count + 1}. ".rjust(left_tab)
      guesses.push(candidates.first || 'WXYZ')
      print "#{guesses.last}\n"
    end

    responses.push feedback(code, guesses.last)
    print_center(
      ['', "`==>", responses.last],
      final_whitespace: " "
    )
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
