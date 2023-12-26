"""Tools for rendering a jinja template."""

load("//cbor_config:defs.bzl", "cbor_config")

def _render_jinja_template_impl(ctx):
    name = ctx.label.name
    cbor_config = ctx.file.cbor_config
    srcs = ctx.attr.srcs

    exec_args = ctx.actions.args()
    inputs = []
    outputs = []

    for file_group in srcs:
        for template_file in file_group.files.to_list():
            exec_args.add("--template_file_paths", template_file)
            inputs.append(template_file)

            # get rid of the j2 suffix and add as output.
            split_template_name = template_file.basename.split(".")
            split_template_name.pop(-1)
            rendered_file_name = ".".join(split_template_name)
            outputs.append(ctx.actions.declare_file("{}/rendered/{}".format(name, rendered_file_name)))

    if cbor_config:
        exec_args.add("--cbor_config_path", cbor_config.path)

    exec_args.add("--rendered_directory_path", outputs[0].dirname)

    ctx.actions.run(
        executable = ctx.executable._template_renderer_binary,
        arguments = [exec_args],
        inputs = inputs + [cbor_config],
        outputs = outputs,
    )

    return [DefaultInfo(files = depset(outputs))]

_render_jinja_templates = rule(
    implementation = _render_jinja_template_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = "Template files that will be rendered.",
            # Only allow .j2 files so that source is easier to interpret as a template.
            allow_files = [".j2"],
            # You can't just not have any templates!
            allow_empty = False,
        ),
        "cbor_config": attr.label(
            doc = "The cbor config that will be used to expand the template.",
            # Just allow cbor and use a macro to ingest other file types.
            allow_single_file = [".cbor"],
        ),
        "jinja_settings": attr.label(
            doc = """A cbor file that contains kwargs that will be passed to the Jinja2 Environment.""",
            # Just allow cbor and use a macro to ingest other file types.
            allow_single_file = [".cbor"],
        ),
        "_template_renderer_binary": attr.label(
            default = Label("//render_jinja_templates:render_jinja_templates"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def render_jinja_templates(name, srcs = [], deps = [], jinja_settings_files = [], **kwargs):
    """
    Render jinja templates using any file usable in cbor_config.

    Args:
        name (str): Name of the rendered file group target.
        srcs (list, optional): List of templates to render.
        deps (list, optional): List of config targets to use for rendering.
        jinja_settings_files (list, optional): List of files to use for configuring jinja settings.
        **kwargs: additional arguments for either rule.
    """
    cbor_config_target = None
    cbor_jinja_settings_target = None

    if deps:
        cbor_config_target = "{}.cbor_config".format(name)
        cbor_config(
            name = cbor_config_target,
            srcs = deps,
            **kwargs
        )

    if jinja_settings_files:
        cbor_jinja_settings_target = "{}.cbor_jinja_settings".format(name)
        cbor_config(
            name = cbor_jinja_settings_target,
            srcs = jinja_settings_files,
            **kwargs
        )

    _render_jinja_templates(
        name = name,
        srcs = srcs,
        cbor_config = cbor_config_target,
        jinja_settings = cbor_jinja_settings_target,
        **kwargs
    )
