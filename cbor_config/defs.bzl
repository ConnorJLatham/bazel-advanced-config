"""Implementation for cbor_config."""

def _cbor_config_impl(ctx):
    name = ctx.label.name
    srcs = ctx.attr.srcs
    overrides = ctx.attr.overrides

    exec_args = ctx.actions.args()
    inputs = []

    for file_group in srcs:
        for file in file_group.files.to_list():
            exec_args.add("--config_file_paths", file)
            inputs.append(file)

    for file_group in overrides:
        for file in file_group.files.to_list():
            exec_args.add("--override_config_file_paths", file)
            inputs.append(file)

    output_cbor = ctx.actions.declare_file("{}.cbor".format(name))

    exec_args.add("--output_cbor_path", output_cbor)

    ctx.actions.run(
        executable = ctx.executable._cbor_configurator,
        arguments = [exec_args],
        inputs = inputs,
        outputs = [output_cbor],
    )

    return [DefaultInfo(files = depset([output_cbor]))]

# Currently only support a selection of human readable file types.
# Can probably grow over time.
_ALLOWED_SOURCE_TYPES = [".toml", ".yaml", ".cbor", ".json"]

_cbor_config = rule(
    implementation = _cbor_config_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = "The source files being used for configuration.",
            allow_files = _ALLOWED_SOURCE_TYPES,
            # Ya gotta have some config!
            mandatory = True,
        ),
        "overrides": attr.label_list(
            doc = "Source files that are allowed to directly override key/values that may already exist.",
            allow_files = _ALLOWED_SOURCE_TYPES,
            default = [],
        ),
        "_cbor_configurator": attr.label(
            doc = "The binary used for generating the cbor config file.",
            default = Label("//cbor_config:cbor_config"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def cbor_config(name, srcs, overrides = [], **kwargs):
    _cbor_config(name = name, srcs = srcs, overrides = overrides)
