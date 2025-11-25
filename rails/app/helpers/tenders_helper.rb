module TendersHelper
  def tender_client_link_content(client)
    content_tag :div, class: "space-y-1" do
      concat content_tag(:div, client.business_name || "Business Name Not Set", class: "font-semibold")
      if client.contact_name.present? || client.contact_email.present?
        contact_parts = []
        contact_parts << client.contact_name if client.contact_name.present?
        contact_parts << client.contact_email if client.contact_email.present?
        concat content_tag(:div, contact_parts.join(" • "), class: "text-sm text-gray-600")
      end
    end
  end

  def preview_qob_file(tender, max_rows: 10)
    return nil unless tender.qob_file.attached?

    filename = tender.qob_file.filename.to_s
    file_content = tender.qob_file.download

    begin
      if filename.end_with?('.csv')
        parse_csv(file_content, max_rows)
      elsif filename.end_with?('.xlsx')
        parse_xlsx_builtin(file_content, max_rows)
      end
    rescue => e
      nil
    end
  end

  private

  def parse_csv(content, max_rows)
    require 'csv'
    rows = CSV.parse(content).take(max_rows + 1)
    { headers: rows.first, data: rows[1..-1] }
  rescue
    nil
  end

  def parse_xlsx_builtin(content, max_rows)
    begin
      # XLSX files are ZIP archives, manually extract using Zlib
      worksheet_xml = extract_worksheet_from_xlsx(content)
      return nil unless worksheet_xml
      
      parse_xlsx_xml_string(worksheet_xml, max_rows)
    rescue => e
      nil
    end
  end

  def extract_worksheet_from_xlsx(content)
    # XLSX is a ZIP file, scan for worksheet entries
    # ZIP local file headers start with PK\x03\x04
    pos = 0
    while pos < content.length
      header_pos = content.index("PK\x03\x04", pos)
      break unless header_pos
      
      if header_pos + 30 <= content.length
        filename_len = content[header_pos + 26..header_pos + 27].unpack('v')[0]
        extra_len = content[header_pos + 28..header_pos + 29].unpack('v')[0]
        
        filename_start = header_pos + 30
        filename_end = filename_start + filename_len
        
        if filename_end <= content.length
          filename = content[filename_start...filename_end]
          
          # Check if this is a worksheet
          if filename.include?('xl/worksheets/sheet') && filename.end_with?('.xml')
            compressed_start = filename_end + extra_len
            compression_method = content[header_pos + 8..header_pos + 9].unpack('v')[0]
            compressed_size = content[header_pos + 18..header_pos + 21].unpack('V')[0]
            uncompressed_size = content[header_pos + 22..header_pos + 25].unpack('V')[0]
            
            if compression_method == 8 && compressed_size > 0
              compressed_data = content[compressed_start...compressed_start + compressed_size]
              begin
                return Zlib::Inflate.inflate(compressed_data)
              rescue
                return nil
              end
            elsif compression_method == 0
              return content[compressed_start...compressed_start + uncompressed_size]
            end
          end
        end
      end
      
      pos = header_pos + 1
    end
    
    nil
  end

  def parse_xlsx_xml_string(xml_content, max_rows)
    # Parse XML using simple string matching, no library required
    rows = []
    
    # Split by <row> tags
    row_matches = xml_content.scan(/<row[^>]*>(.*?)<\/row>/m)
    
    row_matches.each do |row_match|
      row_content = row_match[0]
      row_data = []
      
      # Extract cell values
      cell_matches = row_content.scan(/<c[^>]*>(.*?)<\/c>/m)
      
      cell_matches.each do |cell_match|
        cell_content = cell_match[0]
        value = ''
        
        # Try inline string (is tag)
        if cell_content.include?('<is>')
          value = cell_content.scan(/<is>.*?<t>(.*?)<\/t>.*?<\/is>/m)[0]&.[](0) || ''
        # Try value (v tag)
        elsif cell_content.include?('<v>')
          value = cell_content.scan(/<v>(.*?)<\/v>/m)[0]&.[](0) || ''
        end
        
        row_data << value
      end
      
      rows << row_data if row_data.any?
      break if rows.length > max_rows
    end

    return nil if rows.empty?

    { headers: rows.first, data: rows[1..-1] }
  rescue
    nil
  end
end
