class Game
  def initialize
    @guesses_allowed = 12
    @guesses = []
    @responses = []
    @human_codebreaker = nil
    @code = nil
    @candidates = initial_candidates
  end
  attr_reader :guesses_allowed
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

  def introduce_game
    puts
    puts "           ..........................."
    puts "           ....      FEED-        ...."
    puts "           o...      BACC         o..."
    puts "           *...                   oo.."
    puts "           oo..       (a          ooo."
    puts "           *o..      text-        oooo"
    puts "           **..      based        *..."
    puts "           ooo.     tribute       *o.."
    puts "           *oo.       to          *oo."
    puts "           **o.       the         *ooo"
    puts "           ***.     classic       **.."
    puts "           oooo       code-       **o."
    puts "           *ooo     breaking,     **oo"
    puts "           **oo       game,       ***."
    puts "           ****    Master Mind)   ****"
    puts "           ***************************"
    puts
    puts "            One player MAKES a CODE"
    puts "           as a sequence of 4 letters,"
    puts "           each from the set, ABCDEF."
    puts
    puts "         The other player BREAKS the CODE"
    puts "           in a maximum of #{guesses_allowed} guesses."
    puts
    puts "       Each guess generates feedback such as"
    puts
    puts "           *o..        or         **oo"
    puts
    puts "                  which tallies:"
    puts
    puts "           *  (correctly-placed letters)"
    puts "           o  (out-of-place letters)"
    puts "           .  (superfluous letters)"
    puts
    print "                       "
    gets
  end

  def choose_roles
    puts "               Choose your role: "
    puts "      M. Make a Code      B. Break the Code"
    choice = ''
    until %w[M B].include?(choice)
      print "                       "
      choice = gets.chomp.upcase
    end

    self.human_codebreaker = case choice
                             when 'B' then true
                             when 'M' then false
                             end
  end

  def play_game
    make_code
    break_code
    puts

    if guesses.last == code
      if self.human_codebreaker
        print "Congratulations! You broke the "
      else
        print "\nWhoa! The computer broke your "
      end
      print "code in #{guesses.length} guesses.\n"
    else
      puts "          So close! And yet so far."
      puts
      puts "              The code was #{code}."
    end

    puts
    print "Play again? (Y/N) "
    choice = ''
    until ['Y', 'N'].include?(choice.upcase)
      choice = gets.chomp.upcase
    end
    puts

    if choice == 'Y'
      replay
    else
      exit
    end
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
    print "\n"
    puts "           GUESS    (case-        FEED-   "
    puts "                  insensitive)    BACC    "
    puts
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
