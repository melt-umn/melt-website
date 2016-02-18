#!/usr/bin/python3

import os

def generate_menu_item(base_dir, depth):
	current_dir = os.path.split(base_dir)[1]
	if("." == current_dir):
		current_dir = ""
	# Get menu for all subdirectories
	submenu = ""
	subdirs = [f for f in os.listdir(base_dir) if not os.path.isfile(os.path.join(base_dir, f))]
	for f in subdirs:
		submenu += generate_menu_item(os.path.join(base_dir, f), depth + 1)
	# If the menu is empty...
	space = "    " * depth
	menu_text = current_dir.replace("-", " ")
	if("" == submenu.strip()):
		# If there is an index.md file, create a menu item
		if(os.path.isfile(os.path.join(base_dir, "index.md"))):
			return space + "- text: " + menu_text + "\n" + \
				space + "  url: /" + base_dir + "\n"
		# Otherwise, don't make a menu item
		else:
			return ""
	# Otherwise, make a new expandable menu item
	else:
		return space + "- text: " + menu_text + "\n" + \
			space + "  url: /" + base_dir + "\n" + \
			space + "  nolink: true\n" + \
			space + "  subitems:\n" + submenu

# Store the menu text in 'menu'
menu = "- text: home\n  url: /\n"
dirs = [f for f in os.listdir(".") if not os.path.isfile(f)]

# Generate menu items for all subdirectories
for d in dirs:
	menu += generate_menu_item(d, 0)

# Write to the sv_wiki.yml in _data
datafile = open("_data/sv_wiki.yml", "w")
datafile.write(menu)
datafile.close()
print(menu)

