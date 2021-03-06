FactoryBot.define do
  factory :cancellation_reason do
    name_en         { generate(:cancellation_reasons).keys.sample }
    name_zh_tw      { generate(:cancellation_reasons)[name_en][:name_zh_tw] }
    visible_to_admin { generate(:cancellation_reasons)[name_en][:visible_to_admin] }
    # initialize_with { CancellationReason.find_or_initialize_by(name_en: name_en) }

    trait :visible do
      visible_to_admin true
    end

    trait :invisible do
      name_en "Unwanted"
      visible_to_admin false
    end
  end
end

