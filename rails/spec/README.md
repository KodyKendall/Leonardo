# Test Suite

This directory contains all tests for LlamaPress Simple using both RSpec (backend) and Vitest (JavaScript/frontend).

## Quick Start

```bash
# Run all RSpec tests (backend, excludes system tests)
docker compose exec llamapress bundle exec rspec

# Run all Vitest tests (JavaScript/Stimulus)
docker compose exec llamapress npm test

# Run specific RSpec file
docker compose exec llamapress bundle exec rspec spec/requests/users_spec.rb

# Run Vitest in watch mode
docker compose exec llamapress npm run test:watch
```

## Directory Structure

```
spec/
├── javascript/              # JavaScript/Stimulus tests (Vitest)
│   ├── controllers/         # Stimulus controller tests
│   ├── helpers/            # Test utilities (rails_server.js)
│   └── setup.js            # Global Vitest configuration
├── models/                 # ActiveRecord model tests (RSpec)
├── requests/               # HTTP request tests (RSpec)
├── system/                 # Browser E2E tests (RSpec, excluded by default)
├── factories/              # FactoryBot test data factories
├── rails_helper.rb        # Rails-specific RSpec configuration
├── spec_helper.rb         # Core RSpec configuration
├── examples.txt           # Last RSpec run results
└── README.md             # This file
```

## Test Types

### JavaScript Tests (`spec/javascript/`)
Test Stimulus controllers and frontend behavior using Vitest with happy-dom.

```javascript
import { describe, it, expect } from 'vitest'
import { Controller } from '@hotwired/stimulus'

describe('MyController', () => {
  it('should connect', async () => {
    class MyController extends Controller {
      connect() {
        this.element.textContent = 'Hello!'
      }
    }

    registerController('my', MyController)
    document.body.innerHTML = '<div data-controller="my"></div>'

    await new Promise(resolve => setTimeout(resolve, 0))

    const element = document.querySelector('[data-controller="my"]')
    expect(element.textContent).toBe('Hello!')
  })
})
```

**See [spec/javascript/controllers/example_controller.test.js](javascript/controllers/example_controller.test.js) for comprehensive examples.**

### Request Specs (`spec/requests/`)
Test HTTP requests and responses. Replaces old controller tests.

```ruby
require 'rails_helper'

RSpec.describe "/users", type: :request do
  let(:user) { create(:user) }

  describe "GET /show" do
    it "renders a successful response" do
      get user_url(user)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    it "creates a new user" do
      expect {
        post users_url, params: { user: { name: "Test" } }
      }.to change(User, :count).by(1)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested user" do
      user = create(:user)
      expect {
        delete user_url(user)
      }.to change(User, :count).by(-1)
    end
  end
end
```

### Model Specs (`spec/models/`)
Test ActiveRecord models, validations, and business logic.

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe "associations" do
    it { should have_many(:posts) }
  end

  describe "#full_name" do
    it "returns the full name" do
      user = User.new(first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end
end
```

### System Specs (`spec/system/`)
Browser-based E2E tests using Capybara/Cuprite. **Excluded by default** due to Chromium requirements.

```ruby
require 'rails_helper'

RSpec.describe "Users", type: :system do
  it "displays the users page" do
    visit users_url
    expect(page).to have_content("Users")
  end

  it "creates a new user" do
    visit new_user_url
    fill_in "Name", with: "John Doe"
    click_button "Create User"
    expect(page).to have_content("User was successfully created")
  end
end
```

**Note:** System tests require Chromium and are excluded by default via `.rspec` configuration.

## Using FactoryBot

Factories are defined in `spec/factories/` and provide test data.

### Define a Factory

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "test@example.com" }
    password { "password123" }
  end

  factory :admin_user, parent: :user do
    admin { true }
  end
end
```

### Use in Tests

```ruby
# Create a user
user = create(:user)

# Create with overrides
user = create(:user, name: "Custom Name")

# Build without saving
user = build(:user)

# Build attributes hash
attrs = attributes_for(:user)
```

## Authentication in Tests

For Devise authentication:

```ruby
RSpec.describe "/admin", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it "allows authenticated access" do
    get admin_url
    expect(response).to be_successful
  end
end
```

## Database Cleaning

DatabaseCleaner handles test data cleanup automatically:
- **Transaction strategy** for request/model specs (faster)
- **Truncation strategy** for system specs (more reliable)

Configuration in `spec/rails_helper.rb`.

## Running Tests

### All tests (default, excludes system tests)
```bash
docker compose exec llamapress bundle exec rspec
```

### Specific file
```bash
docker compose exec llamapress bundle exec rspec spec/models/user_spec.rb
```

### Specific test by line number
```bash
docker compose exec llamapress bundle exec rspec spec/requests/users_spec.rb:22
```

### Only failing tests
```bash
docker compose exec llamapress bundle exec rspec --only-failures
```

### Tests matching a pattern
```bash
docker compose exec llamapress bundle exec rspec --example "creates a user"
```

### With verbose output
```bash
docker compose exec llamapress bundle exec rspec --format documentation
```

### System tests (if Chromium configured)
```bash
docker compose exec llamapress bundle exec rspec spec/system
```

## Test Output

### Success
```
Users
  GET /show
    renders a successful response ✓
  POST /create
    creates a new user ✓

Finished in 2.5 seconds
8 examples, 0 failures
```

### Failure
```
Users
  POST /create
    creates a new user ✗

Failures:

  1) Users POST /create creates a new user
     Failure/Error: expect(response).to be_successful

     expected #<Net::HTTPUnprocessableEntity:...> to be successful
```

## Coverage

Coverage reports are automatically generated in `coverage/` after running tests.

View: `coverage/index.html`

Current coverage shown at end of test run:
```
Coverage report generated for RSpec to /rails/coverage.
Line Coverage: 20.61% (61 / 296)
```

## Configuration Files

### `.rspec`
CLI options for RSpec:
```
--require spec_helper
--format documentation
--color
--exclude-pattern spec/system/**/*_spec.rb
```

### `spec/rails_helper.rb`
Rails-specific setup:
- Loads Rails environment
- Configures Capybara/Cuprite for system tests
- Sets up DatabaseCleaner
- Includes FactoryBot syntax
- Includes Devise test helpers

### `spec/spec_helper.rb`
Core RSpec configuration:
- Output formatting
- Test ordering (randomized)
- Shared configuration

## Helper Methods

Available in all specs via `rails_helper.rb`:

### FactoryBot
```ruby
create(:user)              # Create and save
build(:user)               # Build without saving
attributes_for(:user)      # Get attributes hash
create_list(:user, 3)      # Create multiple
```

### Devise (for authenticated routes)
```ruby
sign_in user               # Sign in a user
sign_out user              # Sign out
```

### Request Helpers
```ruby
get users_url              # GET request
post users_url, params: {} # POST request
patch user_url(user)       # PATCH request
delete user_url(user)      # DELETE request
```

## Troubleshooting

### Database not migrated
**Error:** `PG::UndefinedTable: ERROR: relation "users" does not exist`

**Solution:**
```bash
docker compose exec llamapress bin/rails db:test:prepare
```

### Factory not found
**Error:** `FactoryBot::UnregisteredFactoryError`

**Solution:** Create factory in `spec/factories/` or check factory name.

### Devise authentication error
**Error:** Redirect to login page

**Solution:** Add `sign_in user` in `before` block.

### System tests timing out
**Error:** `Ferrum::ProcessTimeoutError: Browser did not produce websocket url`

**Solution:** System tests are excluded by default. They require Chromium which is complex in Docker. Use request specs or Vitest instead.

## Best Practices

1. **Use request specs over controller specs** - Request specs test the full HTTP stack
2. **Use FactoryBot for test data** - Never create records manually
3. **One assertion per test** - Keep tests focused
4. **Use descriptive test names** - `it "creates a user with valid attributes"`
5. **Use `let` and `let!` for setup** - Lazy loading and memoization
6. **Test behavior, not implementation** - Focus on outcomes
7. **Keep tests fast** - Use build over create when possible
8. **Use contexts for different scenarios** - Group related tests

## Example Structure

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should have_many(:posts) }
  end

  describe "#full_name" do
    context "with first and last name" do
      it "returns the full name" do
        user = build(:user, first_name: "John", last_name: "Doe")
        expect(user.full_name).to eq("John Doe")
      end
    end

    context "with only first name" do
      it "returns the first name" do
        user = build(:user, first_name: "John", last_name: nil)
        expect(user.full_name).to eq("John")
      end
    end
  end
end
```

## Learn More

- [RSpec Documentation](https://rspec.info/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
- [Better Specs](https://www.betterspecs.org/) - RSpec best practices
