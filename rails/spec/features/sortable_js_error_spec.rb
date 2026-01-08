require 'rails_helper'

RSpec.describe "Sortable JS Module Resolution", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:tender) { create(:tender) }

  before do
    Capybara.current_driver = :cuprite
    login_as(user, scope: :user)
  end

  it "can resolve the 'sortablejs' module" do
    visit builder_tender_path(tender)

    # Use evaluate_async_script to try importing the module
    # In ESM/Importmap, we can use dynamic import()
    result = page.evaluate_async_script(<<~JS)
      const callback = arguments[arguments.length - 1];
      import('sortablejs')
        .then(() => callback({ success: true }))
        .catch((err) => callback({ success: false, error: err.message }));
    JS
    
    expect(result['success']).to be(true), "Failed to resolve 'sortablejs': #{result['error']}"
  end
end
