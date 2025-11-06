FactoryBot.define do
  factory :tender do
    e_number { "MyString" }
    status { "MyString" }
    client_name { "MyString" }
    tender_value { "9.99" }
    project_type { "MyString" }
    notes { "MyText" }
    awarded_project { nil }
  end
end
