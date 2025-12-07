FactoryBot.define do
  factory :boq do
    sequence(:boq_name) { |n| "BOQ ##{n}" }
    sequence(:file_name) { |n| "boq_#{n}.csv" }
    file_path { "active_storage" }
    status { "uploaded" }
    client_name { "Test Client Ltd" }
    client_reference { "REF-2024-001" }
    qs_name { "Test QS" }
    notes { "Test BOQ" }
    received_date { Date.current }
    header_row_index { 0 }
    association :uploaded_by, factory: :user
    tender { nil }

    trait :parsed do
      status { "parsed" }
      parsed_at { Time.current }
    end

    trait :parsing do
      status { "parsing" }
    end

    trait :error_state do
      status { "error" }
    end

    trait :with_csv_file do
      transient do
        csv_content { "Item #,Description,UOM,Quantity\n1,Steel Section,Tonne,10\n2,Bolts,Box,5" }
      end

      after(:create) do |boq, evaluator|
        require 'tempfile'
        csv_file = Tempfile.new(['boq_test', '.csv'])
        csv_file.write(evaluator.csv_content)
        csv_file.rewind
        boq.csv_file.attach(
          io: csv_file,
          filename: boq.file_name,
          content_type: 'text/csv'
        )
        csv_file.close
        csv_file.unlink
      end
    end

    trait :with_tender do
      association :tender, factory: :tender
    end

    trait :without_tender do
      tender { nil }
    end
  end
end
