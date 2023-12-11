"""Tools for rendering a jinja template."""
load("//cbor_config:defs.bzl", "cbor_config")

def _render_jinja_template_impl(ctx):
    name = ctx.label.name
    cbor_config_path = ctx.file.cbor_config_path
    srcs = ctx.attr.srcs

    exec_args = ctx.actions.args()
    inputs = []
    outputs = []

    for file_group in srcs:
        for template_file in file_group.files.to_list():
            exec_args.add("--template_file_paths",  template_file)
            inputs.append(template_file)
            outputs.append(ctx.actions.declare_file("{}/rendered/{}".format(name, template_file.basename)))

    if cbor_config_path:
        exec_args.add("--cbor_config_path", ctx.file.cbor_config_path.path)

    ctx.actions.run(
        executable = ctx.executable._template_renderer_binary,
        arguments = [exec_args],
        inputs = inputs + [ctx.file.cbor_config_path],
        outputs = outputs,
    )

    return [DefaultInfo(files = depset(outputs))]

_render_templates = rule(
    implementation = _render_jinja_template_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, allow_empty = False),
        "cbor_config_path": attr.label(allow_single_file = True),
        "_template_renderer_binary": attr.label(
            default = Label("//jinja_templater:jinja_template_renderer"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def render_templates(name, srcs = [], config = [], **kwargs):
    """
    Render jinja templates using any file usable in cbor_config.

    Args:
        name (str): Name of the rendered file group target.
        srcs (list, optional): List of templates to render.
        config (list, optional): _List of config targets to use.
        **kwargs: additional arguments for either rule.
    """
    cbor_config_path = None
    if config:
        cbor_config_target_name = "{}.cbor_config".format(name)
        cbor_config(name = cbor_config_target_name, srcs = config, **kwargs)
        cbor_config_path = cbor_config_target_name

    _render_templates(name = name, srcs = srcs, cbor_config_path = cbor_config_path, **kwargs)
