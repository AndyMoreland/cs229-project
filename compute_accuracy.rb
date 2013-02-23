#! /Users/amoreland/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
answers = $stdin.to_a.map { |line| line.chomp.scan(/document\s(a|b)\s(a|b)/i).flatten }
equality = answers.map { |e| e[0] == e[1] }
puts equality.count {|e| e == true}.to_f / answers.size.to_f
