# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :address do
    flat "MyString"
    building "MyString"
    street "MyString"
    district_id 1
    addressable_id 1
    addressable_type "MyString"
    address_type "MyString"
  end

  factory :profile_address, parent: :address do
    address_type "profile"
    district_id "1"
  end
end
