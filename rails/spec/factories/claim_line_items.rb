FactoryBot.define do
  factory :claim_line_item do
    claim { nil }
    line_item_description { "MyString" }
    tender_rate { "9.99" }
    claimed_quantity { "9.99" }
    claimed_amount { "9.99" }
    cumulative_quantity { "9.99" }
    is_new_item { false }
    price_escalation { "9.99" }
  end
end
