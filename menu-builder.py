#!/usr/bin/python3

import os
import re

# TODO: BUG: We're not examining any files OTHER than index.md right now!

# Acceptable directories to traverse, looking for menu information		
def acceptable_directory(path, f):
	return not os.path.isfile(os.path.join(path, f)) and \
	       not f.startswith("_") and \
	       not f.startswith(".") and \
	       f != "vendor"

# Examines subdirectories below the given path
# NOTE: not the path itself!
def build_path(path, depth):
	def pretty_path_join(path, f):
		if path == ".":
			return f
		return os.path.join(path, f)
		
	subdirs = [f for f in os.listdir(path) if acceptable_directory(path,f)]
	subitems = [build_menu_item(pretty_path_join(path, f), depth) for f in subdirs]
	return compile_menu_items(subitems)

# base_dir: the path to examine
# depth: how deep this is (start at 0 for top level menu items)
# returns: (weight, string) tuple
def build_menu_item(base_dir, depth):
	# Get properties from the index file
	index_properties = parse_frontmatter(os.path.join(base_dir, "index.md"))
	# Get menu for all subdirectories
	submenu = build_path(base_dir, depth + 1)
	# Get or build the menu items title
	menu_title = index_properties.get('menu_title', os.path.split(base_dir)[1].replace("-", " ").title())
	# Get or build the menu items weight
	weight = float(index_properties.get('menu_weight', 10000))
	# Get the the menu string for this directory and all subdirectories
	return (weight, build_menu_item_string(menu_title, depth, base_dir, index_properties, submenu))

# menu_items: list of (weight, string) tuples
# returns: sorted by weight, each string joined
def compile_menu_items(menu_items):
	sorted_menu_items = sorted(menu_items, key=lambda i: i[0])
	return "".join([i[1] for i in sorted_menu_items])
	
# title: the page title
# depth: the depth in the menu
# directory: the path containing this file
# properties: properties for this markdown file
# submenu_string: the concatenated menuitems for its children
# returns: a string for this menu item
def build_menu_item_string(title, depth, directory, properties, submenu_string):
	has_submenu = "" != submenu_string.strip()
	if not has_submenu and not properties['valid']:
		return ""
	space = "    " * depth
	menu_string = space + "- text: " + title + "\n" + \
		      space + "  url: /" + directory + "/\n"
	if not properties['valid'] or properties.get('menu_nolink', None) == "true":
		menu_string += space + "  nolink: true\n"
	if has_submenu:
		menu_string += space + "  subitems:\n" + submenu_string
	return menu_string

# md_file_path: a path to a markdown file to examine
# returns: A dictionary:
#   present - does this file exist
#   valid - does this file start with '---'
#   <prop> - from the YAML frontmatter (We only parse the simplest properties though!)
def parse_frontmatter(md_file_path):
	props = {}
	props['present'] = os.path.isfile(md_file_path)
	props['valid'] = False
	if props['present']:
		md_file = open(md_file_path, "r")
		lines = md_file.readlines()
		props['valid'] = len(lines) > 0 and lines[0] == "---\n"
		if props['valid']:
			regex = re.compile(r"^([a-zA-Z0-9_ ]*):(.*)")
			index = 1
			while index < len(lines) and not lines[index].startswith("---"):
				match = regex.match(lines[index])
				if match:
					props[match.group(1).strip()] = match.group(2).strip()
				else:
					print("ERR: confused by prop in " + md_file_path)
				index = index + 1
		else:
			print("wrn: invalid index " + md_file_path)
	return props


# Build the menu
menu = "- text: Home\n  url: /\n" + build_path(".", 0)

# Write to the sv_wiki.yml in _data
with open("_data/sv_wiki.yml", "w") as f:
	f.write(menu)

print("Menu Generated")

