# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpreadsheetParser do
  let(:fixtures_path) { Rails.root.join('spec', 'fixtures', 'files', 'spreadsheets') }

  describe '.open' do
    context 'with valid CSV file' do
      let(:file_path) { fixtures_path.join('simple.csv') }

      it 'returns a Roo spreadsheet object' do
        spreadsheet = described_class.open(file_path)
        expect(spreadsheet).to be_a(Roo::CSV)
      end

      it 'can read the first row' do
        spreadsheet = described_class.open(file_path)
        expect(spreadsheet.row(1)).to eq(['Name', 'Value', 'Description'])
      end
    end

    context 'with CSV containing newline in quoted field' do
      let(:file_path) { fixtures_path.join('newline_in_field.csv') }

      it 'parses successfully' do
        spreadsheet = described_class.open(file_path)
        headers = spreadsheet.row(1)
        expect(headers).to be_present
        expect(headers.length).to eq(3)
      end
    end

    context 'with unsupported file type' do
      it 'raises UnsupportedFormatError' do
        # Create a temp file with .pdf extension
        Tempfile.create(['document', '.pdf']) do |file|
          file.write('PDF content')
          file.rewind

          expect { described_class.open(file.path) }
            .to raise_error(SpreadsheetParser::UnsupportedFormatError, /Unsupported file format/)
        end
      end
    end

    context 'with corrupted xlsx file' do
      let(:file_path) { fixtures_path.join('corrupted.xlsx') }

      it 'raises ParseError', skip: 'Requires corrupted.xlsx fixture' do
        expect { described_class.open(file_path) }
          .to raise_error(SpreadsheetParser::ParseError)
      end
    end

    context 'with forced extension option' do
      let(:file_path) { fixtures_path.join('simple.csv') }

      it 'uses the provided extension' do
        spreadsheet = described_class.open(file_path, extension: '.csv')
        expect(spreadsheet).to be_a(Roo::CSV)
      end
    end
  end

  describe '.parse_to_hashes' do
    context 'with standard CSV' do
      let(:file_path) { fixtures_path.join('simple.csv') }

      it 'returns array of hashes' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)

        expect(result).to be_an(Array)
        expect(result.first).to be_a(Hash)
      end

      it 'uses headers as keys' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)

        expect(result.first.keys).to include('Name', 'Value', 'Description')
      end

      it 'returns correct data values' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)

        expect(result.first['Name']).to eq('Alice')
        # CSV files return string values, not integers
        expect(result.first['Value']).to eq('100')
      end

      it 'skips empty rows' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)

        expect(result.none? { |row| row.values.all?(&:nil?) }).to be true
      end

      it 'preserves numeric strings from CSV' do
        # Note: CSV files return all values as strings
        # XLSX files would return actual integers/floats
        result = described_class.parse_to_hashes(file_path, header_row: 1)

        expect(result.first['Value']).to eq('100')
      end
    end

    context 'with header row not on first row' do
      let(:file_path) { fixtures_path.join('header_on_row_3.csv') }

      it 'respects header_row parameter' do
        result = described_class.parse_to_hashes(file_path, header_row: 3)

        expect(result.first.keys).to include('Actual', 'Headers', 'Here')
      end

      it 'returns data starting after header row' do
        result = described_class.parse_to_hashes(file_path, header_row: 3)

        expect(result.first['Actual']).to eq('Data')
        expect(result.first['Headers']).to eq('Row')
      end
    end

    context 'with blank headers' do
      let(:file_path) { fixtures_path.join('blank_headers.csv') }

      it 'provides default column names for blank headers' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)

        expect(result.first.keys).to include('column_2')
      end

      it 'still includes non-blank headers' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)

        expect(result.first.keys).to include('Name', 'Value')
      end
    end

    context 'with empty file' do
      it 'returns empty array' do
        Tempfile.create(['empty', '.csv']) do |file|
          file.write('')
          file.rewind

          result = described_class.parse_to_hashes(file.path, header_row: 1)
          expect(result).to eq([])
        end
      end
    end

    context 'with headers only (no data rows)' do
      it 'returns empty array' do
        Tempfile.create(['headers_only', '.csv']) do |file|
          file.write("Name,Value\n")
          file.rewind

          result = described_class.parse_to_hashes(file.path, header_row: 1)
          expect(result).to eq([])
        end
      end
    end
  end

  describe '.parse_to_rows' do
    let(:file_path) { fixtures_path.join('simple.csv') }

    it 'returns array of arrays' do
      result = described_class.parse_to_rows(file_path)

      expect(result).to be_an(Array)
      expect(result.first).to be_an(Array)
    end

    it 'includes all rows including headers' do
      result = described_class.parse_to_rows(file_path)

      expect(result.first).to eq(['Name', 'Value', 'Description'])
      # CSV files return all values as strings
      expect(result[1]).to eq(['Alice', '100', 'First item'])
    end
  end

  describe '.info' do
    let(:file_path) { fixtures_path.join('simple.csv') }

    it 'returns spreadsheet metadata' do
      info = described_class.info(file_path)

      expect(info[:sheets]).to be_present
      expect(info[:row_count]).to be_a(Integer)
      expect(info[:first_row]).to eq(1)
    end

    it 'returns row count' do
      info = described_class.info(file_path)

      expect(info[:row_count]).to eq(4) # header + 3 data rows
    end

    context 'with invalid file' do
      it 'returns error hash instead of raising' do
        Tempfile.create(['invalid', '.pdf']) do |file|
          file.write('not a spreadsheet')
          file.rewind

          info = described_class.info(file.path)
          expect(info[:error]).to be_present
        end
      end
    end
  end

  describe '.with_attachment' do
    # These tests require ActiveStorage setup
    # Skip if ActiveStorage is not configured
    context 'with ActiveStorage attachment', skip: 'Requires ActiveStorage setup' do
      it 'opens the attachment and yields the spreadsheet' do
        # Would need to set up a model with ActiveStorage attachment
      end
    end
  end

  describe 'encoding handling' do
    context 'with UTF-8 content' do
      let(:file_path) { fixtures_path.join('simple.csv') }

      it 'parses UTF-8 content correctly' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)
        expect(result).to be_present
      end
    end

    context 'with mixed line endings and BOM (real-world BOQ file)' do
      let(:file_path) { fixtures_path.join('Structural Steel Schedule.csv') }

      it 'parses successfully' do
        spreadsheet = described_class.open(file_path)
        expect(spreadsheet).to be_a(Roo::Base)
        expect(spreadsheet.last_row).to be > 1
      end

      it 'extracts headers correctly' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)
        expect(result).to be_present
        expect(result.first.keys).to include('Item', 'MEMBER SIZE', 'Unit')
      end

      it 'parses all data rows' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)
        expect(result.length).to be >= 20
      end

      it 'handles the multiline header field' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)
        # The header "TOTAL\nWEIGHT(tonnes)" should be normalized
        weight_header = result.first.keys.find { |k| k.include?('WEIGHT') || k.include?('TOTAL') }
        expect(weight_header).to be_present
      end
    end

    # Note: Binary encoding fixtures (BOM, Windows-1252) need to be generated
    # using the generate_fixtures.rb script in the fixtures directory
    context 'with UTF-8 BOM', skip: 'Requires binary fixture with_bom.csv' do
      let(:file_path) { fixtures_path.join('with_bom.csv') }

      it 'strips BOM from first header' do
        spreadsheet = described_class.open(file_path)
        first_header = spreadsheet.row(1).first
        expect(first_header).to eq('Name')
        expect(first_header).not_to start_with("\xEF\xBB\xBF")
      end
    end

    context 'with Windows-1252 encoding', skip: 'Requires binary fixture windows1252.csv' do
      let(:file_path) { fixtures_path.join('windows1252.csv') }

      it 'parses Windows-1252 encoded content' do
        result = described_class.parse_to_hashes(file_path, header_row: 1)
        expect(result.first['Name']).to include('caf')
      end
    end
  end

  describe 'error classes' do
    it 'defines ParseError as base error' do
      expect(SpreadsheetParser::ParseError.superclass).to eq(StandardError)
    end

    it 'defines UnsupportedFormatError as subclass of ParseError' do
      expect(SpreadsheetParser::UnsupportedFormatError.superclass).to eq(SpreadsheetParser::ParseError)
    end

    it 'defines EncodingError as subclass of ParseError' do
      expect(SpreadsheetParser::EncodingError.superclass).to eq(SpreadsheetParser::ParseError)
    end
  end
end
