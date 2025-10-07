#!/usr/bin/env python3
"""
Wiki Link Fixer - Convert markdown-style internal links to wiki-style links
"""

import os
import re
import sys

def find_wiki_files():
    """Find all markdown files in the wiki directory"""
    wiki_files = []
    for root, dirs, files in os.walk('wiki'):
        for file in files:
            if file.endswith('.md'):
                wiki_files.append(os.path.join(root, file))
    return wiki_files

def get_all_wiki_pages():
    """Get a list of all wiki page names (without .md extension)"""
    wiki_files = find_wiki_files()
    pages = set()
    for file_path in wiki_files:
        # Get filename without extension
        filename = os.path.basename(file_path)
        page_name = filename.replace('.md', '')
        pages.add(page_name)
        
        # Also add the full path relative to wiki/ for nested pages
        rel_path = os.path.relpath(file_path, 'wiki')
        if '/' in rel_path:
            pages.add(rel_path.replace('.md', ''))
    
    return pages

def fix_wiki_links(file_path, content, wiki_pages):
    """Fix markdown-style internal links to wiki-style links"""
    
    def replace_link(match):
        link_text = match.group(1)
        link_url = match.group(2)
        
        # Skip external URLs, anchors, and email links
        if link_url.startswith(('http', 'mailto:', '#')):
            return match.group(0)
        
        # Skip relative paths to non-wiki files
        if link_url.startswith('../') and not '/wiki/' in link_url:
            return match.group(0)
            
        # Convert wiki-relative paths
        if link_url.startswith('../wiki/'):
            wiki_page = link_url.replace('../wiki/', '').replace('.md', '')
            return f'[[{wiki_page}|{link_text}]]'
        
        # Handle direct page references
        clean_url = link_url.replace('.md', '').replace('../', '')
        
        # Check if this is a known wiki page
        if clean_url in wiki_pages or clean_url.replace('/', '-') in wiki_pages:
            # Use the text as the page name if it matches a wiki page
            if link_text.replace(' ', '-') in wiki_pages:
                return f'[[{link_text.replace(" ", "-")}]]'
            else:
                return f'[[{clean_url}|{link_text}]]'
        
        # For relative paths within wiki structure
        if '/' in clean_url:
            return f'[[{clean_url.replace("/", "-")}|{link_text}]]'
        
        # Default: convert to simple wiki link
        return f'[[{clean_url}|{link_text}]]'
    
    # Find and replace markdown-style links
    fixed_content = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', replace_link, content)
    
    return fixed_content

def main():
    if not os.path.exists('wiki'):
        print("Error: wiki directory not found")
        sys.exit(1)
    
    wiki_files = find_wiki_files()
    wiki_pages = get_all_wiki_pages()
    
    print(f"Found {len(wiki_files)} wiki files")
    print(f"Found {len(wiki_pages)} wiki pages")
    
    fixed_count = 0
    total_links_fixed = 0
    
    for file_path in wiki_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
            
            fixed_content = fix_wiki_links(file_path, original_content, wiki_pages)
            
            if fixed_content != original_content:
                # Count how many links were fixed
                original_links = len(re.findall(r'\[([^\]]+)\]\(([^)]+)\)', original_content))
                fixed_links = len(re.findall(r'\[([^\]]+)\]\(([^)]+)\)', fixed_content))
                links_fixed = original_links - fixed_links
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(fixed_content)
                
                print(f"Fixed {links_fixed} links in {file_path}")
                fixed_count += 1
                total_links_fixed += links_fixed
        
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    print(f"\nSummary:")
    print(f"Files modified: {fixed_count}")
    print(f"Total links fixed: {total_links_fixed}")

if __name__ == '__main__':
    main()
