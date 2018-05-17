#!/usr/bin/python3

import os
import re

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
			regex = re.compile(r"^([a-zA-Z0-9_]*) *:(.*)")
			index = 1
			while index < len(lines) and not lines[index].startswith("---"):
				match = regex.match(lines[index])
				if match:
					props[match.group(1).strip()] = match.group(2).strip()
				else:
					print("ERR: confused by prop in " + md_file_path)
				index = index + 1
		else:
			print("wrn: no frontmatter " + md_file_path)
	return props


class MenuContainer:
	# self.items = a list of MenuItems
	def __init__(self, items):
		self.items = sorted(items, key=lambda i: i.weight)
	
	def render(self, depth=0):
		return ''.join([i.render(depth) for i in self.items])
	
	@staticmethod
	def from_dir(path):
		"""Returns a ``MenuContainer``s looking at ``path``. Includes all markdown files and all ``subdir/index.md``."""
		def acceptable_directory(f):
			return os.path.isdir(os.path.join(path, f)) and \
			       not f.startswith("_") and \
			       not f.startswith(".") and \
			       f != "vendor"
		def acceptable_mdfile(f):
			if f == "README.md":
				return False
			if f == "index.md" and path != ".":
				return False
			return f.endswith(".md")
		def pretty_join(d, f):
			if d == ".":
				return f
			return os.path.join(d, f)
		print("MCfrom_dir " + path)
		contents = os.listdir(path)
		dirs = [f for f in contents if acceptable_directory(f)]
		print(", ".join(dirs))
		mdfiles = [f for f in contents if acceptable_mdfile(f)]
		
		d_items = [MenuItem.from_dir(pretty_join(path, f)) for f in dirs]
		f_items = [MenuItem.from_file(pretty_join(path, f)) for f in mdfiles]
		return MenuContainer(d_items + f_items)

class MenuItem:
	# self.path = path to markdown file
	# self.child = a MenuContainer
	def __init__(self, path, child):
		self.path = path
		self.child = child
		if path.endswith('index.md'):
			self.url = path[:-8]
			fallback_title = os.path.split(path[:-9])[1] # dir name
			if self.url == "":
				self.url = ""
		elif path.endswith('.md'):
			self.url = path[:-3] + ".html"
			fallback_title = os.path.split(path[:-3])[1] # file name
		else:
			self.url = path
			print("Unexpected path " + path)
		self.props = parse_frontmatter(path)
		self.valid = self.props['valid']
		self.weight = float(self.props.get('menu_weight', 10000))
		self.title = self.props.get('menu_title', fallback_title.replace("-", " ").title())
		self.nolink = self.props.get('menu_nolink', None) == "true"
	
	def render(self, depth):
		if self.child:
			submenu_string = self.child.render(depth + 1)
		else:
			submenu_string = ""
		# Suppress sub-branches that are not valid
		has_submenu = ("" != submenu_string.strip())
		if not has_submenu and not self.valid:
			return ""
		space = "    " * depth
		menu_string = space + "- text: " + self.title + "\n" + \
			      space + "  url: /" + self.url + "\n"
		if not self.valid or self.nolink:
			menu_string += space + "  nolink: true\n"
		if has_submenu:
			menu_string += space + "  subitems:\n" + submenu_string
		return menu_string

	@staticmethod
	def from_dir(path):
		print("MIfrom_dir " + path)
		return MenuItem(os.path.join(path, "index.md"), MenuContainer.from_dir(path))
	
	@staticmethod
	def from_file(path):
		print("MIfrom_file " + path)
		return MenuItem(path, None)
		

# Build the menu
menu = MenuContainer.from_dir(".")

# Write to the sv_wiki.yml in _data
with open("_data/sv_wiki.yml", "w") as f:
	f.write(menu.render())

print("Menu Generated")

