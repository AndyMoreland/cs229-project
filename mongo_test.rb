require 'rubygems'
require 'mongo'
require 'bson'
require 'pry'
require 'set'
load "stop_words.rb"

include Mongo
client = MongoClient.new('localhost', 3002)
db = client['meteor']
coll = db['uploaded_files']


class UploadedEssay
  attr_accessor :reading_ease, :grade_level, :fog_score, :document_text

  def self.filter_word(word)
    word.gsub(/[^a-zA-Z-]/, "").downcase
  end
  
  def initialize(attributes)
    @grade = attributes[:grade]
    @id = attributes[:_id]
    
    @words_count = {}
    @words_count.default = 0
    @unique_words = SortedSet.new()
    @fog_score = attributes[:fog_score]
    @reading_ease = attributes[:reading_ease]
    @grade_level = attributes[:grade_level]
    @document_text = attributes[:document_text]
  end

  def register_word(word)
    filtered_word = self.class.filter_word(word)
    @words_count[filtered_word] += 1
    @unique_words << filtered_word
  end

  def words_count
    @words_count
  end

  def unique_words
    @unique_words
  end

  def prune_words(restriction_set)
    @unique_words = @unique_words.intersection(restriction_set)
    @words_count.reject! {|word, count| !restriction_set.include?(word) }
  end

  def to_matrix_row(word_index_hash)
    output = []
    output << self.classification
    numbers = []
    numbers << word_index_hash[unique_words.first]
    numbers << words_count[unique_words.first]

    running_index = word_index_hash[unique_words.first]

    unique_words.to_a[1..-1].each_with_index do |word, i|
      numbers << word_index_hash[word] - running_index
      numbers << words_count[word]
      running_index = word_index_hash[word]
    end

    output += numbers
    output << -1

    output.join " "
  end

  def to_stats_row
    return [classification, average_word_length, reading_ease, grade_level, unique_word_count, fog_score].join(" ")
  end

  def average_word_length
    length_sum = 0
    count_sum = 0
    @words_count.each do |word, count|
      length_sum += word.length * count
      count_sum += count
    end
    
    return length_sum.to_f / count_sum.to_f
  end

  def unique_word_count
    @unique_words.size
  end

  def classification
    if @grade =~ /.*A.*/
      return 1
    elsif @grade =~ /.*B.*/
      return 0
    else
      return 3
    end
  end
end


MINIMUM_WORD_COUNT = 5
MINIMUM_APPEARANCES = 5

word_db = {}
word_db.default = 0
essays = []
words_to_sorted_indices = {}
essay_appearances = {}
essay_appearances.default = 0

word_cursor = coll.find({document_text: {"$ne" => ""}, grade: { "$ne" => "" }})

word_cursor.each do |file|
  if file["document_text"] && file["document_text"].length > 100 && (file["grade"] =~ /.*A.*/ || file["grade"] =~ /.*B.*/)
    essay = UploadedEssay.new(id: file["_id"], grade: file["grade"], fog_score: file["fog_score"], reading_ease: file["reading_ease"], grade_level: file["grade_level"], document_text: file["document_text"])
    if ARGV.size <= 1
      min_length = 4
    else
      min_length = ARGV[1].to_i
    end

    file["document_text"].split(" ").each do |word|
      if word != "" && word.length >= min_length && !STOP_WORDS.include?(word)
        filtered_word = UploadedEssay::filter_word(word)
        word_db[filtered_word] += 1
        essay.register_word(filtered_word)
      end
    end

    essays << essay
  end
end

essays.each do |essay|
  essay.unique_words.each do |word|
    essay_appearances[word] += 1
  end
end

puts "Word database was: #{word_db.size}"
word_db.reject! { |word, count| count < MINIMUM_WORD_COUNT }
puts "After first filtering: #{word_db.size}"
word_db.reject! { |word, count| essay_appearances[word] < MINIMUM_APPEARANCES }
puts "After second filtering: #{word_db.size}"
word_set = SortedSet.new(word_db.keys)

essays.each do |essay|
  essay.prune_words(word_set)
end

word_set.each_with_index do |word, i|
  words_to_sorted_indices[word] = i
end

def output_file(filename, output_essays, word_set, words_to_sorted_indices)
  File.open(filename, "w+") do |f|
    f << "HEADER\n"
    f << "#{output_essays.size} #{word_set.size}\n"
    
    word_set.each do |w|
      f << "#{w} "
    end

    f << "\n"
    
    output_essays.each do |e|
      f << e.to_matrix_row(words_to_sorted_indices) << "\n"
    end
  end
end

essay_folds = []
essays.shuffle!

if ARGV.length > 0

  essays.each_slice(essays.size / ARGV[0].to_i) do |slice|
    essay_folds << slice
  end

  essay_folds.each_with_index do |fold, i|
    test_fold = fold
    first_folds = essay_folds[0...i]
    last_folds = essay_folds[(i+1)...(essay_folds.size)]

    training_folds = first_folds
    training_folds += last_folds if last_folds != nil

    puts "Outputting fold #{i}"
    
    output_file("output.train#{i}", training_folds.flatten, word_set, words_to_sorted_indices)
    output_file("output.test#{i}", test_fold, word_set, words_to_sorted_indices)
  end
else
  binding.pry
end

#random subsampling
#ARGV[0].to_i.times do |i|
#  essays.shuffle!
#  
#  output_file("output.train#{i}", essays[0..-29], word_set, words_to_sorted_indices)
#  output_file("output.test#{i}", essays[-30..-1], word_set, words_to_sorted_indices)
#end

