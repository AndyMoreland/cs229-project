#! /Users/amoreland/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
require 'rubygems'
require 'mongo'
require 'bson'
require 'pry'
require 'set'


include Mongo
client = MongoClient.new('localhost', 3002)
db = client['meteor']
coll = db['uploaded_files']


word_cursor = coll.find({document_text: {"$ne" => ""}, grade: { "$ne" => "" }})

documents = {}
documents["A"] = []
documents["B"] = []

word_cursor.each_with_index do |file, i|
  if file["document_text"] && file["document_text"].length > 100 && (file["grade"] =~ /.*A.*/ || file["grade"] =~ /.*B.*/)
    if file["grade"] =~ /.*A.*/
      documents["A"] << file["document_text"]
    elsif file["grade"] =~ /.*B.*/
      documents["B"] << file["document_text"]
    end
  end
end

[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9].each do |ratio|
  iterator = 0
  holdout_a = documents["A"].shuffle!.take(documents["A"].size * ratio)
  train_a = documents["A"].drop(documents["A"].size * ratio)

  holdout_b = documents["B"].shuffle!.take(documents["B"].size * ratio)
  train_b = documents["B"].drop(documents["B"].size * ratio)

  holdout_a.each do |data|
    File.open("holdout#{ratio}/A/#{iterator}.document", "w+") do |f|
      f << data
    end
    
    iterator += 1
  end

  holdout_b.each do |data|
    File.open("holdout#{ratio}/B/#{iterator}.document", "w+") do |f|
      f << data
    end
    
    iterator += 1
  end

  train_a.each do |data|
    File.open("train#{ratio}/A/#{iterator}.document", "w+") do |f|
      f << data
    end
    
    iterator += 1
  end

  train_b.each do |data|
    File.open("train#{ratio}/B/#{iterator}.document", "w+") do |f|
      f << data
    end
    
    iterator += 1
  end
end
