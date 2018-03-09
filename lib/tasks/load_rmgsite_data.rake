
desc "load rmgsite data"
task :load_rmgsite_data => :environment do
  ary = [ 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 

          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 

          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", 
          "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>", "<redacted_phone_number>"
        ]


  u = User.find 2626
  ary.each_with_index do |number, i|
    default = i == 0 ? 1 : 0
    fn = "(" + number[1..3] + ") " + number[4..6] + "-" + number[7..10]
    u.numbers.create(number: number, country: 'CA', provider: 'fibernetics', default: default, friendly_name: fn)
  end
  
end
