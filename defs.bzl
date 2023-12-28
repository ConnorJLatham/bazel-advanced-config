"""Bring everything to a top level defs.bzl."""

load("//cbor_config:defs.bzl", _cbor_config = "cbor_config")
load("//render_jinja_template:defs.bzl", _render_jinja_template = "render_jinja_template")

cbor_config = _cbor_config
render_jinja_template = _render_jinja_template
