task create_lists: :environment do
  email_list = ['<redacted_email>', '<redacted_email>']
  merchant = User.find_by_email('<redacted_email>')
  email_list.each do |email|
    user = User.new(email: email, password: 'suryasiwakoti', user_level: 0, phone_number: rand(10000000000..<redacted_phone_number>).to_s)
    user.save(validate: false)
    list = merchant.lists.build(name: "test#{rand(1..100)}")
    list.user_lists.build(user_id: user.id)
    list.save(validate: false)
  end if merchant.present?
end
