desc 'get number type data'
task number_type_data: :environment do
  require 'csv'

  CSV::Converters[:blank_to_nil] = lambda do |field|
    field && field.blank? ? nil : field.to_s.squish
  end

  file_data = CSV.read('/home/taiwo/Downloads/2018-10-31 CoCO Text Universe.csv',
                        headers: true,
                        skip_blanks: true,
                        header_converters: :symbol,
                        converters: [:all, :blank_to_nil],
                        skip_lines: /^(?:[,:;]\s*)+$/)

  CSV.open('/home/taiwo/Downloads/NumberTypeData.csv', 'wb') do |csv|
    csv << %w[phone type]
    file_data.each_with_index do |row, index|
      puts index
      row = row.to_hash
      linetype = EveryoneApiService.line_type(row[:phone])

      csv << [row[:phone], linetype || 'NA']
    end
  end
end
