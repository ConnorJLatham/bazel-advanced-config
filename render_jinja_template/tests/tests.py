import cbor2
import pathlib


def _load_config(name):
    return cbor2.load(
        pathlib.Path(f"render_jinja_template/tests/{name}.cbor").open(mode="rb")
    )


rendered_config = _load_config("render_template_test_config")

assert rendered_config["string_1"] == "string"
assert rendered_config["integer_1"] == 1
assert rendered_config["float_1"] == 1.1

assert rendered_config["dict_1"] == {
    "string_5": "string!",
    "integer_5": 1,
    "float_5": 1.1,
}
