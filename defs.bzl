"""Bring everything to a top level defs.bzl."""

load("//cbor_config:defs.bzl", _cbor_config = "cbor_config")
load("//render_templates:defs.bzl", _render_templates = "render_templates")

cbor_config = _cbor_config
render_templates = _render_templates
