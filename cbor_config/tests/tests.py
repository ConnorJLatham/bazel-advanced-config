import cbor2
import pathlib
from cbor_config.cbor_config import recursively_check_dict_for_key


def _load_config(name):
    return cbor2.load(pathlib.Path(f"cbor_config/tests/{name}.cbor").open(mode="rb"))


SMALL_CONFIG = _load_config("small_config")
DOWNSTREAM_CONFIG = _load_config("downstream_config")
NESTED_CONFIG = _load_config("nested_config")

# Check that the small config is parsed as expected.
assert SMALL_CONFIG == {
    "string_1": "string",
    "integer_1": 1,
    "float_1": 1.1,
    "string_2": "string",
    "integer_2": 1,
    "float_2": 1.1,
    "string_3": "string",
    "integer_3": 1,
    "float_3": 1.1,
    "string_4": "string!",
    "integer_4": 1,
    "float_4": 1.1,
    "dict_1": {
        "string_5": "string!",
        "integer_5": 1,
        "float_5": 1.1,
    },
    "_overrides": {
        # Ensure all overrides are accompanied by a named file.
        "_small_config_override_0.json": {
            # Test that we can override values at the top level.
            "string_4": "string!",
            # Test that we can access nested dict values.
            "dict_1->string_5": "string!",
        },
    },
}


# Check that the downstream config (which just uses the small config) is the same.
assert DOWNSTREAM_CONFIG == SMALL_CONFIG

# Check that nested configs (with the same key names) are parsed fine.
assert NESTED_CONFIG == {"nice": {"nice": {"nice": 3}}}

# Check that the assertion error is descriptive enough by injecting a key/value pair.
try:
    recursively_check_dict_for_key(
        SMALL_CONFIG,
        {"string_1": "string haha"},
        pathlib.Path(f"cbor_config/tests/small_config.cbor"),
    )
except ValueError as key_exists_error:
    exception_text = (
        "Found existing key/value 'string_1: string haha' (full nested name: 'string_1')!\n"
        "Conflicts with key/value string_1: string in bazel target with name small_config.\n"
    )

    assert key_exists_error.args[0] == exception_text
