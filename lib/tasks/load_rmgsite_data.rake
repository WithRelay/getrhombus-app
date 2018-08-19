
desc "load rmgsite data"
task :load_rmgsite_data => :environment do
  
=begin
  ary = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>
      ]

  u = User.find 12569
  u.numbers.delete_all
  ary.each_with_index do |number, i|
    #number = "1" + number.to_s.gsub(/\s+/, "")
    number = number.to_s
    default = i == 0 ? 1 : 0
    #default = 0
    fn = "(" + number[1..3] + ") " + number[4..6] + "-" + number[7..10]
    u.numbers.create(number: number, country: 'CA', provider: 'fibernetics', default: default, friendly_name: fn)
  end
=end

  ary = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>
  ]

  u = User.find 14822
  #u.numbers.delete_all
  ary.each_with_index do |number, i|
    #number = "1" + number.to_s.gsub(/\s+/, "")
    number = number.to_s
    default = 0 # i == 0 ? 1 : 0
    #default = 0
    fn = "(" + number[1..3] + ") " + number[4..6] + "-" + number[7..10]
    u.numbers.create(number: number, country: 'CA', provider: 'fibernetics', default: default, friendly_name: fn)
  end
end

=begin
  ary = [
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>,
      <redacted_phone_number>
      ]
=end

=begin
  desc "load numbers from file"
  task :load_numbers_from_file => :environment do
    require 'csv'

    CSV::Converters[:blank_to_nil] = lambda do |field|
      field && field.blank? ? nil : field.to_s.squish
    end

    file_data = CSV.read("/home/taiwo/Downloads/numbers.csv", headers: true, skip_blanks: true, header_converters: :symbol, converters: [:all, :blank_to_nil], skip_lines: /^(?:[,:;]\s*)+$/)
     
    ary = Array.new 

    file_data.each do |row|
      row = row.to_hash
      ary.push("1" + row[:honey_harbour].to_s)
      ary.push("1" + row[:caledon_east].to_s)
      ary.push("1" + row[:ottawa].to_s)
      ary.push("1" + row[:chatham].to_s)
      ary.push("1" + row[:toronto].to_s)
    end

    puts ary.inspect
    puts ary.length
    
  end
=end



=begin
  #rmg's second account

  ary = [<redacted_phone_number>, <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>, <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>, <redacted_phone_number>,
  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,  <redacted_phone_number>,
  ] 
=end