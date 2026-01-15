# Script to generate binary test fixtures for SpreadsheetParser
# Run from Rails console: load 'spec/fixtures/files/spreadsheets/generate_fixtures.rb'

fixtures_path = File.dirname(__FILE__)

# with_bom.csv - UTF-8 BOM at start (common Excel export)
File.write(
  File.join(fixtures_path, 'with_bom.csv'),
  "\xEF\xBB\xBFName,Value\r\nTest,123\r\nAnother,456\r\n",
  mode: 'wb'
)
puts "Created with_bom.csv"

# windows1252.csv - Windows-1252 encoding (e = 0xE9 in Win-1252)
File.write(
  File.join(fixtures_path, 'windows1252.csv'),
  "Name,Value\ncaf\xE9,123\nR\xE9sum\xE9,456\n".b,
  mode: 'wb'
)
puts "Created windows1252.csv"

# newline_in_field.csv - Newline inside quoted field with BOM and CRLF
File.write(
  File.join(fixtures_path, 'newline_in_field.csv'),
  "\xEF\xBB\xBFItem,\"TOTAL\r\nWEIGHT\",Notes\r\n1,100,First\r\n2,200,Second\r\n",
  mode: 'wb'
)
puts "Created newline_in_field.csv"

# nbsp.csv - Non-breaking space in header (0xC2 0xA0 is NBSP in UTF-8)
File.write(
  File.join(fixtures_path, 'nbsp.csv'),
  "TOTAL\xC2\xA0WEIGHT,Value\nTest,123\n",
  mode: 'wb'
)
puts "Created nbsp.csv"

# corrupted.xlsx - Invalid file for error testing
File.write(
  File.join(fixtures_path, 'corrupted.xlsx'),
  "not a real xlsx file - random binary content",
  mode: 'wb'
)
puts "Created corrupted.xlsx"

puts "\nAll fixtures created in #{fixtures_path}"
