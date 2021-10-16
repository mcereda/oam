#!/usr/bin/env python3

import sys, yaml
from jinja2 import Environment, FileSystemLoader

if __name__ == "__main__":
	root_dir = sys.argv[1]
	template_filename = sys.argv[2]
	yaml_filename = sys.argv[3]

	with open('{}/{}'.format(root_dir, yaml_filename)) as y:
		config_data = yaml.safe_load(y)
		# print(config_data)

	env = Environment(loader = FileSystemLoader(root_dir), trim_blocks=True, lstrip_blocks=True)
	template = env.get_template(template_filename)

	print(template.render(config_data))
