require 'pry'

averages = []

ITERATIONS = 10

(1..12).each do |j|
  answers = []

  puts `ruby mongo_test.rb #{ITERATIONS} #{j}`
  ITERATIONS.times do |i|
    
    Dir::chdir("ps2")
    `mv ../output.test#{i} output.test`
    `mv ../output.train#{i} output.train`
    output = `/Applications/MATLAB_R2012a.app/bin/matlab -nodisplay -r nb_train`
    Dir::chdir("..")
    answer = output.scan(/ans.*?([.\d]+).*/m)[0][0].to_f
    puts "Iteration: #{i} of coordinate #{j} got #{answer}"

    answers << answer
  end
  average_score = answers.inject(&:+) / answers.size
  averages << average_score
  puts "#{average_score} for iteration #{j}"
end

puts "Averages:"
puts averages


