#!/usr/bin/python3

import os
import re

# base_dir: the path to examine
# depth: how deep this is (start at 0 for top level menu items)
# returns: (weight, string) tuple
def build_menu_item(base_dir, depth):
	# Check for an index file
	index_path = os.path.join(base_dir, "index.md")
	has_index = os.path.isfile(index_path)
	# Get properties from the index file
	index_properties = get_index_properties(index_path)
	# Get menu for all subdirectories
	subdirs = [f for f in os.listdir(base_dir) if not os.path.isfile(os.path.join(base_dir, f))]
	subitems = [build_menu_item(os.path.join(base_dir, i), depth + 1) for i in subdirs]
	submenu = compile_menu_items(subitems)
	# Get or build the menu items title
	menu_title = index_properties['menu_title']
	if None == menu_title:
		short_dirname = os.path.split(base_dir)[1]
		if("." == short_dirname):
			short_dirname = ""
		menu_title = short_dirname.replace("-", " ").title()
	# Get or build the menu items weight
	weight = 10000
	if None != index_properties['menu_weight']:
		weight = eval(index_properties['menu_weight'])
	# Get the the menu string for this directory and all subdirectories
	return (weight, build_menu_item_string(menu_title, depth, base_dir, has_index, submenu))

# menu_items: list of (weight, string) tuples
# returns: sorted by weight, each string joined
def compile_menu_items(menu_items):
	sorted_menu_items = sorted(menu_items, key=lambda i: i[0])
	return "".join([i[1] for i in sorted_menu_items])
	
# title: the page title
# depth: the depth in the menu
# directory: the path containing this file
# has_index: whether 'index.md' exists
# submenu_string: the concatenated menuitems for its children
# returns: a string for this menu item
def build_menu_item_string(title, depth, directory, has_index, submenu_string):
	has_submenu = "" != submenu_string.strip()
	if not has_submenu and not has_index:
		return ""
	space = "    " * depth
	menu_string = space + "- text: " + title + "\n" + \
		      space + "  url: /" + directory + "\n"
	if not has_index:
		menu_string += space + "  nolink: true\n"
	if has_submenu:
		menu_string += space + "  subitems:\n" + submenu_string
	return menu_string

# Gets the menu title and weight properties from index.md files
def get_index_properties(index_path):
	props = {}
	props['menu_title'] = None
	props['menu_weight'] = None
	if os.path.isfile(index_path):
		index_file = open(index_path, "r")
		title_regex = re.compile(r"menu_title:([-a-zA-Z0-9 ]*)")
		weight_regex = re.compile(r"menu_weight:([-0-9\. ]*)")
		is_title_matched = False
		is_weight_matched = False
		for line in index_file.readlines():
			title_match = title_regex.match(line)
			weight_match = weight_regex.match(line)
			if None != title_match and not is_title_matched:
				props['menu_title'] = title_match.group(1).strip()
				is_title_matched = True
			if None != weight_match and not is_weight_matched:
				props['menu_weight'] = weight_match.group(1).strip()
				is_weight_matched = True
			if is_title_matched and is_weight_matched:
				break
	return props
		

# Build the menu
menu = "- text: Home\n  url: /\n"
dirs = [f for f in os.listdir(".") if (not os.path.isfile(f) and not f.startswith("_") and f != "vendor")]
menu += compile_menu_items([build_menu_item(d, 0) for d in dirs])

# Write to the sv_wiki.yml in _data
datafile = open("_data/sv_wiki.yml", "w")
datafile.write(menu)
datafile.close()
print("Menu Generated")

