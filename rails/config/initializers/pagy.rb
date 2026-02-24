# frozen_string_literal: true

# Pagy Configuration
# https://ddnexus.github.io/pagy/
#
# Pagy is a fast, lightweight pagination gem. This initializer sets default
# options that apply across the entire application.

# Number of items per page (default: 20)
Pagy::DEFAULT[:limit] = 20

# Number of page links to show in the navigation bar
# Format: [start, before_current, after_current, end]
# Example: [1, 2, 2, 1] shows: 1 ... 3 4 [5] 6 7 ... 10
# Pagy::DEFAULT[:size] = 7

# Overflow handling: what to do when page number is out of range
# :empty_page  - returns empty page (default)
# :last_page   - redirects to last page
# :exception   - raises Pagy::OverflowError
# Pagy::DEFAULT[:overflow] = :last_page

# Enable if using Tailwind CSS for styled pagination
# require 'pagy/extras/tailwind'
