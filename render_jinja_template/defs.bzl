"""Tools for rendering a jinja template."""

load("//cbor_config:defs.bzl", "cbor_config")

def _render_jinja_template_impl(ctx):
    cbor_config = ctx.file.cbor_config
    template_file = ctx.file.template_to_expand
    other_template_deps = ctx.attr.template_deps
    args = ctx.actions.args()

    inputs = [template_file, cbor_config]

    for info in other_template_deps:
        for file in info.files.to_list():
            inputs.append(file)
            args.add("--template_dep_path", file)

    args.add("--template_file_path", template_file)
    if cbor_config:
        args.add("--cbor_config_path", cbor_config.path)

    # get rid of the j2 suffix and add as output.
    split_template_name = template_file.basename.split(".")
    split_template_name.pop(-1)
    rendered_file_name = ".".join(split_template_name)
    rendered_file = ctx.actions.declare_file("{}".format(rendered_file_name))

    args.add("--rendered_file_path", rendered_file)

    ctx.actions.run(
        executable = ctx.executable._template_renderer_binary,
        arguments = [args],
        inputs = inputs,
        outputs = [rendered_file],
    )

    return [DefaultInfo(files = depset([rendered_file]))]

_render_jinja_template = rule(
    implementation = _render_jinja_template_impl,
    attrs = {
        "template_to_expand": attr.label(
            doc = "Template files that will be rendered.",
            # Only allow .j2 files so that source is easier to interpret as a template.
            allow_single_file = [".j2"],
            mandatory = True,
        ),
        "template_deps": attr.label_list(
            doc = "Other templates the one being expanded relies on.",
            allow_files = [".j2"],
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
            default = Label("//render_jinja_template:render_jinja_template"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def render_jinja_template(name, template, deps = [], jinja_settings_files = [], **kwargs):
    """
    Render jinja templates using any file usable in cbor_config.

    Args:
        name (str): Name of the rendered file group target.
        template (str): Template to render.
        deps (list, optional): List of config targets to use for rendering.
        jinja_settings_files (list, optional): List of files to use for configuring jinja settings.
        **kwargs: additional arguments for either rule.
    """
    cbor_config_target = None
    cbor_jinja_settings_target = None
    template_deps = []
    cbor_deps = []

    for dep in deps:
        if ".j2" in dep:
            template_deps.append(dep)
        else:
            cbor_deps.append(dep)

    if cbor_deps:
        cbor_config_target = "{}.cbor_config".format(name)
        cbor_config(
            name = cbor_config_target,
            srcs = cbor_deps,
            **kwargs
        )

    if jinja_settings_files:
        cbor_jinja_settings_target = "{}.cbor_jinja_settings".format(name)
        cbor_config(
            name = cbor_jinja_settings_target,
            srcs = jinja_settings_files,
            **kwargs
        )

    _render_jinja_template(
        name = name,
        template_to_expand = template,
        template_deps = template_deps,
        cbor_config = cbor_config_target,
        jinja_settings = cbor_jinja_settings_target,
        **kwargs
    )
