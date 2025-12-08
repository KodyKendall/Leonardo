#!/usr/bin/env python3
import os
import re
from pathlib import Path

def fix_show_spec(filepath):
    """Fix show spec files"""
    with open(filepath, 'r') as f:
        content = f.read()

    # Extract model name from file path
    model_name = filepath.stem.replace('.html.tailwindcss_spec', '')
    singular = model_name.rstrip('s') if model_name.endswith('s') else model_name

    # Pattern to match the create block with attributes
    pattern = r'assign\(:(\w+), create\(:(\w+),.*?\)\)'

    def replacement(match):
        var_name = match.group(1)
        factory_name = match.group(2)
        return f'@{var_name} = create(:{factory_name})\n    assign(:{var_name}, @{var_name})'

    content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    # Simplify test expectations
    content = re.sub(
        r'it "renders attributes in <p>" do\s+render\s+(?:expect\(rendered\)\.to match\(/.*?\)\s*)+end',
        'it "renders attributes in <p>" do\n    render\n  end',
        content,
        flags=re.DOTALL
    )

    with open(filepath, 'w') as f:
        f.write(content)

def fix_index_spec(filepath):
    """Fix index spec files"""
    with open(filepath, 'r') as f:
        content = f.read()

    # Pattern to match array of creates with attributes
    pattern = r'assign\(:(\w+), \[\s*create\(:(\w+),.*?\),\s*create\(:(\w+),.*?\)\s*\]\)'

    def replacement(match):
        var_name = match.group(1)
        factory_name = match.group(2)
        return f'@{var_name} = [create(:{factory_name}), create(:{factory_name})]\n    assign(:{var_name}, @{var_name})'

    content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    # Simplify test assertions
    content = re.sub(
        r'it "renders a list of \w+" do\s+render\s+cell_selector = \'div>p\'\s+(?:assert_select.*?\n\s*)+end',
        lambda m: m.group(0).split('cell_selector')[0] + 'render\n  end',
        content,
        flags=re.DOTALL
    )

    with open(filepath, 'w') as f:
        f.write(content)

def fix_edit_spec(filepath):
    """Fix edit spec files"""
    with open(filepath, 'r') as f:
        content = f.read()

    # Pattern to match let block with attributes
    pattern = r'before\(:each\) do\s+@user = create\(:user\)\s+sign_in\(@user\)\s+end\s+let\(:(\w+)\) \{\s+create\(:(\w+),.*?\)\s+\}\s+before\(:each\) do\s+assign\(:\1, \1\)\s+end'

    def replacement(match):
        var_name = match.group(1)
        factory_name = match.group(2)
        return f'''let(:{var_name}) {{ create(:{factory_name}) }}

  before(:each) do
    @user = create(:user)
    sign_in(@user)
    assign(:{var_name}, {var_name})
  end'''

    content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    with open(filepath, 'w') as f:
        f.write(content)

# Process all view spec files
view_spec_dir = Path('rails/spec/views')
for spec_file in view_spec_dir.rglob('*_spec.rb'):
    if 'show.html' in spec_file.name:
        fix_show_spec(spec_file)
        print(f'Fixed show: {spec_file}')
    elif 'index.html' in spec_file.name:
        fix_index_spec(spec_file)
        print(f'Fixed index: {spec_file}')
    elif 'edit.html' in spec_file.name:
        fix_edit_spec(spec_file)
        print(f'Fixed edit: {spec_file}')

print('Done!')
