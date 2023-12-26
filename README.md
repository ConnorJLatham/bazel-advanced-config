This module provides helpers for ingesting multiple types of human-readable 'config'
files such as .yaml and .json and combining them into .cbor files. These .cbor files
can then be used as config for binaries or for expanding jinja templates using the
'render_templates' rule.