load("//cbor_config:defs.bzl", "cbor_config")

def _render_jinja_template_impl(ctx):
    ### GET ALL INPUT VARIABLES ###
    name = ctx.label.name

    cbor_config_path = ctx.file.cbor_config_path
    srcs = ctx.attr.srcs

    print(cbor_config_path.path)

    ### DECLARE INITIAL VALUES ###
    template_list = []
    rendered_list = []

    for file_group in srcs:
        for template_file in file_group.files.to_list():
            template_symlink = ctx.actions.declare_file("{}/templates/{}".format(name, template_file.basename))
            ctx.actions.symlink(output = template_symlink, target_file = template_file)
            template_list.append(template_symlink)

    # Now that we have collected all templates, check that we actually have some.
    if not template_list:
        fail("No templates found!")

    ### CREATE RENDERED FILES ###
    rendered_list = [ctx.actions.declare_file("{}/rendered/{}".format(name, template.basename)) for template in template_list]

    ### CREATE PY BINARY RENDERING ARGS ###
    exec_args = ctx.actions.args()
    exec_args.add("--template_files_dir", template_list[0].dirname)
    exec_args.add("--rendered_files_dir", rendered_list[0].dirname)
    if cbor_config_path:
        exec_args.add("--cbor_config_path", ctx.file.cbor_config_path.path)
    # exec_args.add("--config_keyword", )
    # exec_args.add("--jinja_config_path", jinja_config_path.path)

    ctx.actions.run(
        executable = ctx.executable._template_renderer_binary,
        arguments = [exec_args],
        inputs = template_list,
        outputs = rendered_list,
    )

    return [DefaultInfo(files = depset(rendered_list))]

_render_templates = rule(
    implementation = _render_jinja_template_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "cbor_config_path": attr.label(allow_single_file = True),
        # "fail_on_nonexistent_config": attr.bool(default = True),
        "config_keyword": attr.string(default = "config"),
        # Rendering binary, probably dont touch this.
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
