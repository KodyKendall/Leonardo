FactoryBot.define do
  factory :claim_line_item do
    claim
    line_item_description { "Line Item Description" }
    tender_rate { 100.0 }
    claimed_quantity { 50.0 }
    claimed_amount { 5000.0 }
  end
end