require 'csv'

# Base URL for the images
base_url = "https://git.bodhish.in/water_mission/images/water/"

# Array to hold the results
results = []

# Loop through the image numbers
(1..29).each do |number|
  # Generate the full URL for the current image
  url = "#{base_url}#{number}.jpeg"

  # Call the water reading service
  result = Water::ReadService.new(url).execute

  # Add the result to the results array
  results << [number, result[:value], result[:units], result[:notes]]
end

# Generate the CSV file
CSV.open("output.csv", "wb") do |csv|
  # Add headers to the CSV file
  csv << ["Image Number", "Value", "Units", "Notes"]

  # Add each result to the CSV file
  results.each do |result|
    csv << result
  end
end

puts "CSV file generated successfully."
