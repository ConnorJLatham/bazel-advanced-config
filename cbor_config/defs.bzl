def _cbor_config_impl(ctx):
    """Take in a variety of different file types and create a cbor object."""

    ### GET ALL INPUT VARIABLES ###
    name = ctx.label.name

    # Get configs
    srcs = ctx.attr.srcs

    # overrides = ctx.attr.srcs
    config_list = []

    for file_group in srcs:
        for file in file_group.files.to_list():
            config_symlink = ctx.actions.declare_file("{}/config/{}".format(name, file))
            ctx.actions.symlink(output = config_symlink, target_file = file)
            config_list.append(config_symlink)

    # for file_group in overrides:
    #     for file in file_group.files.to_list():
    #         config_symlink = ctx.actions.declare_file("{}/config/{}".format(name, file))
    #         ctx.actions.symlink(output = config_symlink, target_file = file)
    #         config_list.append(config_symlink)

    output_cbor = ctx.actions.declare_file("{}.cbor".format(name))

    ### CREATE PY BINARY RENDERING ARGS ###
    exec_args = ctx.actions.args()
    exec_args.add(config_list[0].dirname)
    exec_args.add(output_cbor.path)

    ### RUN PY BINARY TO RENDER THINGS ###
    ctx.actions.run(
        executable = ctx.executable._cbor_configurator,
        arguments = [exec_args],
        inputs = config_list,
        outputs = [output_cbor],
    )

    return [DefaultInfo(files = depset([output_cbor]))]

cbor_config = rule(
    implementation = _cbor_config_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "overrides": attr.label_list(allow_files = True),
        # Rendering binary, probably dont touch this.
        "_cbor_configurator": attr.label(
            default = Label("//cbor_config:cbor_configurator"),
            executable = True,
            cfg = "exec",
        ),
    },
)
