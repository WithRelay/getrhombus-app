FactoryGirl.define do
  factory :campaign, class: 'Campaign' do |f|
    f.name FFaker::Lorem.word
    f.channel 0
    f.deliver_now 0
    f.frequency_type 1
    f.repeat_days 0
    f.text FFaker::Lorem.paragraph
    f.date_time((DateTime.now + 1.hour))
    association :user, factory: :merchant_user3
  end
end
