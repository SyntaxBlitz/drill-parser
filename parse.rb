require 'pdf/reader'

class CustomPageTextReceiver < PDF::Reader::PageTextReceiver
  attr_reader :characters, :mediabox
end

class CustomPageLayout < PDF::Reader::PageLayout
  attr_reader :runs
end

reader = PDF::Reader.new(ARGV[0])

text_receiver = CustomPageTextReceiver.new

reader.pages.each do |page|
	unless page.nil?
		page.walk(text_receiver)
		runs = CustomPageLayout.new(text_receiver.characters, text_receiver.mediabox).runs

		runs = runs.select {|run| run.text == "p"}
	end
end
