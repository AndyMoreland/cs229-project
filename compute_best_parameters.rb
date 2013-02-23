#! /Users/amoreland/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
j = ARGV[0].to_i
total_errors = []
  (50..500).to_a.each do |i|
    puts "Iteration #{j}, #{i}"
    # iterate over all infogain possibilities
    `rainbow -v0 -d ~/model#{j} --prune-vocab-by-infogain=#{i} --prune-vocab-by-doc-count=#{j} --use-stemming --index ~/docs/*`
    output = `./test_vs_train.rb #{j}`
    errors = output.scan(/(\d+\.\d+) (\d+\.\d+)/).flatten
    total_errors << [i, j, errors]
  end


puts "writing results"

File.open("results.#{j}", "w") do |f|
  total_errors.each do |error|
    f << "#{error[0]}, #{error[1]}, #{error[2][0]}, #{error[2][1]} \n"
  end
end

puts "produced results"
