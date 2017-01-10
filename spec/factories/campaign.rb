FactoryGirl.define do
  factory :campaign, class: 'Campaign' do |f|
    f.name FFaker::Lorem.word
    f.channel 0
    f.deliver_now 1
    f.frequency_type 0
    f.text FFaker::Lorem.paragraph
    association :user, factory: :merchant_user3
  end
end
