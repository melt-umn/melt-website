#!/usr/bin/python3

import os
import re
import itertools

# path: a path to search
# returns: a list of md files to examine
def find_all_md_files(path):
	def acceptable_directory(f):
		return os.path.isdir(os.path.join(path, f)) and \
		       not f.startswith("_site") and \
		       not f.startswith(".") and \
		       f != "vendor"
	def acceptable_mdfile(f):
		if f == "README.md":
			return False
		return f.endswith(".md")
	def pretty_join(d, f):
		if d == ".":
			return f
		return os.path.join(d, f)

	contents = os.listdir(path)
	dirs = [pretty_join(path, f) for f in contents if acceptable_directory(f)]
	mdfiles = [pretty_join(path, f) for f in contents if acceptable_mdfile(f)]
	
	return mdfiles + list(itertools.chain.from_iterable([find_all_md_files(f) for f in dirs]))

# md_file_path: a path to a markdown file to examine
# returns: A dictionary:
#   valid - does this file start with '---'
#   filepath - path to this file
#   <prop> - from the YAML frontmatter (We only parse the simplest properties though!)
def parse_frontmatter(md_file_path):
	props = {}
	props['valid'] = False
	props['filepath'] = md_file_path
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

class MenuItem:
	def __init__(self, path):
		self.path = path
		self.subitems = {}
		self.valid = False
		self.weight = 10000
		self.nolink = False
		if path.endswith('.md'):
			self.url = path[:-3] + ".html"
			fallback_title = os.path.split(path[:-3])[1] # file name
		elif path.endswith('.html'):
			self.url = path
			fallback_title = os.path.split(path[:-5])[1] # file name
		else:
			self.url = path + "/"
			fallback_title = os.path.split(path)[1] # dir name
		self.title = fallback_title.replace("-", " ").title()
	
	def insert(self, pathspec, frontmatter):
		if len(pathspec) == 0:
			# We're a "nonindex.md"
			self.insertindex(frontmatter)
		elif len(pathspec) == 1 and (pathspec[0] in ["index.md", ""]):
			# We're a "index.md" (explicitly or implicitly)
			self.insertindex(frontmatter)
		else:
			# We're a "path/to/something/deeper"
			head, *tail = pathspec
			self.insertchild(head, tail, frontmatter)
	
	def insertindex(self, frontmatter):
		self.props = frontmatter
		self.valid = self.props['valid']
		self.weight = float(self.props.get('menu_weight', self.weight))
		if self.weight == 10000 and self.valid:
			print("No order: " + self.props['filepath'])
		self.title = self.props.get('menu_title', self.title)
		self.nolink = self.props.get('menu_nolink', None) == "true"
	
	def insertchild(self, child, pathspec, frontmatter):
		if not child in self.subitems:
			self.subitems[child] = MenuItem(os.path.join(self.path, child))
		self.subitems[child].insert(pathspec, frontmatter)

	def render(self, depth):
		children = sorted(self.subitems.values(), key=lambda i: i.weight)
		submenu_string = ""
		for c in children:
			submenu_string += c.render(depth + 1)
		
		# Suppress sub-branches that are not valid
		has_submenu = ("" != submenu_string.strip())
		if not has_submenu and not self.valid:
			return ""
		
		if self.url == "/":
			url = self.url
		else:
			url = "/" + self.url
		
		space = "    " * depth
		menu_string = space + "- text: " + self.title + "\n" + \
			      space + "  url: " + url + "\n"
		if not self.valid or self.nolink:
			menu_string += space + "  nolink: true\n"
		if has_submenu:
			if depth >= 0:
				menu_string += space + "  subitems:\n" + submenu_string
			else:
				menu_string += submenu_string
		return menu_string

# files: a list of files to parse
# returns: a MenuItem representing all these files
def menu_from_files(files):
	menu = MenuItem("")
	for file in files:
		frontmatter = parse_frontmatter(file)
		pathspec = frontmatter.get('permalink', file).split('/')
		# permalinks start with /, so strip that...
		if pathspec[0] == "":
			head, *tail = pathspec
			pathspec = tail
		menu.insert(pathspec, frontmatter)
	return menu

files = find_all_md_files(".")
menu = menu_from_files(files)

# Write to the sv_wiki.yml in _data
with open("_data/sv_wiki.yml", "w") as f:
	f.write(menu.render(-1))

print("Menu Generated")

