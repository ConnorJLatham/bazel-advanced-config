"""Implementation for cbor_config."""

def _cbor_config_impl(ctx):
    name = ctx.label.name
    file_srcs = ctx.attr.file_srcs
    file_overrides_srcs = ctx.attr.file_overrides_srcs
    json_string_srcs = ctx.attr.json_string_srcs
    json_string_override_srcs = ctx.attr.json_string_override_srcs

    exec_args = ctx.actions.args()
    inputs = []

    config_files = []
    override_config_files = []

    for i, json_string in enumerate(json_string_srcs):
        file = ctx.actions.declare_file("_{}_{}.json".format(ctx.attr.name, i))
        ctx.actions.write(content = json_string, output=file)
        config_files.append(file)

    for i, json_string in enumerate(json_string_override_srcs):
        file = ctx.actions.declare_file("_{}_override_{}.json".format(ctx.attr.name, i))
        ctx.actions.write(content = json_string, output=file)
        override_config_files.append(file)

    for file_group in file_srcs:
        for file in file_group.files.to_list():
            config_files.append(file)

    for file_group in file_overrides_srcs:
        for file in file_group.files.to_list():
            override_config_files.append(file)

    for file in config_files:
        exec_args.add("--config_file_paths", file)
        inputs.append(file)

    for file in override_config_files:
        exec_args.add("--override_config_file_paths", file)
        inputs.append(file)

    inputs = config_files + override_config_files

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
_ALLOWED_SOURCE_TYPES = [".toml", ".yaml", ".cbor", ".json"]

_cbor_config = rule(
    implementation = _cbor_config_impl,
    attrs = {
        "file_srcs": attr.label_list(
            doc = "The source files being used for configuration.",
            allow_files = _ALLOWED_SOURCE_TYPES,
            # Ya gotta have some config!
            mandatory = True,
        ),
        "file_overrides_srcs": attr.label_list(
            doc = "Source files that are allowed to directly override key/values that may already exist.",
            allow_files = _ALLOWED_SOURCE_TYPES,
            default = [],
        ),
        "json_string_srcs": attr.string_list(
            doc = "JSON string that will be used in the config dict.",
            default = [],
        ),
        "json_string_override_srcs": attr.string_list(
            doc = "JSON string that will be used in the config dict.",
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
    file_srcs = []
    json_string_srcs = []

    for src in srcs:
        if type(src) == "string":
            file_srcs.append(src)
        elif type(src) == "dict":
            json_string_srcs.append(json.encode(src))
        else:
            fail("CBOR source {} could not be added to the config.".format(src))

    file_overrides_srcs = []
    json_string_override_srcs = []

    for override in overrides:
        if type(override) == "string":
            file_overrides_srcs.append(override)
        elif type(override) == "dict":
            json_string_override_srcs.append(json.encode(override))
        else:
            fail("CBOR source {} could note be added to the config.".format(src))

    _cbor_config(
        name = name,
        file_srcs = file_srcs,
        json_string_srcs = json_string_srcs,
        file_overrides_srcs = file_overrides_srcs,
        json_string_override_srcs = json_string_override_srcs,
        **kwargs,
    )
