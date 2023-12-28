import cbor2
import pathlib


def _load_config(name):
    return cbor2.load(
        pathlib.Path(f"render_jinja_template/tests/{name}.cbor").open(mode="rb")
    )


rendered_config = _load_config("render_yaml_template_config")

assert rendered_config == {
    "test": "test",
    "string_1": "string",
    "integer_1": 1,
    "float_1": 1.1,
    "dict_1": {
        "string_5": "string!",
        "integer_5": 1,
        "float_5": 1.1,
    },
    "dict_2": {
        "string_6": "string",
    },
}

