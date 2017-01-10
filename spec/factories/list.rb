FactoryGirl.define do
  factory :list1, class: 'List' do |f|
    f.name FFaker::Lorem.word
    association :user, factory: :merchant_user2
  end
end
