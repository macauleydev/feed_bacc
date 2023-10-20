class Game
  def initialize
    @guesses_allowed = 10
  end
  attr_reader :guesses_allowed

  def rating(code_string, guess_string)
    code = code_string.upcase.split('').first(4)
    guess = guess_string.upcase.split('').first(4)
    tally = Hash.new(0)
    #  {
    #   :right_places => 0,
    #   :wrong_places => 0,
    #   :extraneous => 0
    # }

    guess.each_with_index do |letter, index|
      right_place = index if letter == code[index]
      if right_place
        tally[:right_places] += 1
        guess[right_place] = nil
        code[right_place] = nil
      end
    end
    # guess.compact!
    # code.compact!
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
    play_game
  end

  def introduce_game
    puts "           ..........................."
    puts "           ....      CODE         ...."
    puts "           o...    BREAKER!       o..."
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
    puts "           ***o      Master       ***o"
    puts "           ****       Mind)       ****"
    puts "           ***************************"
    puts
    puts "                The secret code"
    puts "           is a sequence of 4 letters,"
    puts "            each from the set, ABCDEF."
    puts
    puts "          (BBCB, for example. Or: FACE.)"
    puts
    puts "             You must break the code"
    puts "              in #{guesses_allowed} guesses or fewer."
    puts
    puts "         (Guesses are not case-sensitive.)"
    puts
    puts "          Each guess will be rated with one"
    puts "          '*' per correctly-placed letter, one"
    puts "          'o' per out-of-place letter, and one"
    puts "          '.' per superfluous letter."
    puts
    # puts "      (Guesses are not case-sensitive.)"
    # puts
    # puts "                     Ready?"
    print "                       "
    gets
  end

  def play_game
    letters = %w[A B C D E F]
    code = ''
    4.times {code << letters.sample}

    guesses = []
    (1..guesses_allowed).each do |i|
      print " Guess ##{i}? "
      guesses.push(gets.chomp.upcase)
      puts "   Rating: #{rating(code, guesses.last)}"
      puts
      break if guesses.last == code
    end
    if guesses.last == code
      puts "Congratulations! You broke the code in #{guesses.length} guesses."
    else
      puts "Sorry, you used up all #{guesses_allowed} guesses!"
      puts "The code was #{code}."
    end
    puts
    print "Play again? (Y/N) "
    choice = ''
    until ['Y', 'N'].include?(choice.upcase)
      choice = gets.chomp.upcase
    end
    play_game if choice == 'Y'
  end


end

new_game = Game.new
new_game.play
