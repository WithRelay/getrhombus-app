
  desc "enrich number in csv"
  task :enrich_number_in_csv => :environment do
    require 'csv'

    CSV::Converters[:blank_to_nil] = lambda do |field|
      field && field.blank? ? nil : field.to_s.squish
    end

    file_data = CSV.read("/home/taiwo/Downloads/PhoneNumbersToReverseAppend.csv", headers: true, skip_blanks: true, 
                          header_converters: :symbol, converters: [:all, :blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/)

    CSV.open("/home/taiwo/Downloads/file.csv", "wb") do |csv|
      
      headers = ["name", "address", "line_provider", "cnam", "carrier", "gender", "linetype", "profile"]
      match_hash = headers.each_with_object({}) { |k, h| h[k] = 0 }
      csv << ['phone'] + headers
      ary = Array.new

      file_data.each_with_index do |row, index|
        row = row.to_hash
        ary.push(row[:phone])
        response = EveryoneApiService.enrich_number(row[:phone])
        
        if response.try(:[], "data")
          api_data = response['data']
          data = api_data.try(:[], "name") || ""
          ary.push(data)

          data = api_data.try(:[], "address") || ""
          ary.push(data)

          data = api_data.try(:[], "line_provider").try(:[], 'name') || ""
          ary.push(data)

          data = api_data.try(:[], "cnam") || ""
          ary.push(data)

          data = api_data.try(:[], "carrier").try(:[], "name") || ""
          ary.push(data)

          data = api_data.try(:[], "gender") || ""
          ary.push(data)

          data = api_data.try(:[], "linetype") || ""
          ary.push(data)

          data = ""
          if api_data.try(:[], "profile")
            api_data["profile"].each { |k,v| data = data + " #{k}: #{v}." }
          end
          ary.push(data.strip)

          # update match count
          headers.each { |h| match_hash[h] = match_hash[h] + 1 unless response['missed'].include?(h) }
        end

        csv << ary
        ary.clear
      end

      CSV.open("/home/taiwo/Downloads/enrichment_match.csv", "wb") do |match_csv|
        match_hash.each { |k,v| match_csv << [k, v] }
      end

    end
    
  end
