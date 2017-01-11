FactoryGirl.define do
  factory :merchant_user1, class: User do |f|
    f.first_name FFaker::Name.first_name
    f.last_name FFaker::Name.last_name
    f.email FFaker::Internet.email
    f.password FFaker::Internet.password
    f.phone_number FFaker::PhoneNumberBR.international_mobile_phone_number
    f.confirmed_at Date.today
    f.user_level 1
  end

  factory :merchant_user2, class: User do |f|
    f.first_name FFaker::Name.first_name
    f.last_name FFaker::Name.last_name
    f.email FFaker::Internet.email
    f.password FFaker::Internet.password
    f.phone_number FFaker::PhoneNumberBR.international_mobile_phone_number
    f.confirmed_at Date.today
    f.user_level 1
  end

  factory :merchant_user3, class: User do |f|
    f.first_name FFaker::Name.first_name
    f.last_name FFaker::Name.last_name
    f.email FFaker::Internet.email
    f.password FFaker::Internet.password
    f.phone_number FFaker::PhoneNumberBR.international_mobile_phone_number
    f.confirmed_at Date.today
    f.user_level 1
  end
end
