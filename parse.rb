require 'pdf/reader'
require 'json'

class CustomPageTextReceiver < PDF::Reader::PageTextReceiver
  attr_reader :characters, :mediabox
end

class CustomPageLayout < PDF::Reader::PageLayout
  attr_reader :runs
end

reader = PDF::Reader.new(ARGV[0])

text_receiver = CustomPageTextReceiver.new

first_dot = {:x => 54, :y => 106}	# F3 is 54 steps from the back of the field, 106 from left (endzone)
last_dot = {:x => 68, :y => 44.06}		# TS1		x and y are flipped because the drill pdf is sideways ;)

spots = []

slope = {}
step_function = {}

reader.pages.each do |page|
	unless page.nil?
		page.walk(text_receiver)
		runs = CustomPageLayout.new(text_receiver.characters, text_receiver.mediabox).runs

		runs = runs.select {|run| run.text == "p"}
		runCoordinates = runs.map {|run| {:x => run.x, :y => run.y}}

		if page.number == 1
			# now we calculate the additive and multiplicative offset for both x and y
			slope = {
				:x => (first_dot[:x] - last_dot[:x]) / (runCoordinates[0][:x] - runCoordinates[-1][:x]),
				:y => (first_dot[:y] - last_dot[:y]) / (runCoordinates[0][:y] - runCoordinates[-1][:y])
			}

			step_function = {
				:x => Proc.new {|x| slope[:x] * (x - runCoordinates[0][:x]) + first_dot[:x]},
				:y => Proc.new {|y| slope[:y] * (y - runCoordinates[0][:y]) + first_dot[:y]}
			}
		end

		dots = runCoordinates.map {|coords| {:x => (step_function[:x].call(coords[:x]) * 2).round / 2.0, :y => (step_function[:y].call(coords[:y]) * 2).round / 2.0}}

		spots << dots
	end
end

File.open(ARGV[0] + ".json", 'w') do |file|
	file.write(JSON.generate(spots))
end

File.open(ARGV[0] + ".js", 'w') do |file|
	file.write("var pages="JSON.generate(spots) + ";");
end
