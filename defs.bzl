"""Bring everything to a top level defs.bzl."""

load("//cbor_config:defs.bzl", _cbor_config = "cbor_config")
load("//render_jinja_templates:defs.bzl", _render_jinja_templates = "render_jinja_templates")

cbor_config = _cbor_config
render_jinja_templates = _render_jinja_templates
