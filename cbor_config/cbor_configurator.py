import cbor2
import yaml
import argparse
import pathlib
import json


def add_to_config(dict_to_add_to, file_with_more_config, check_conflicts=True):
    new_config = {}
    if "yaml" in file.suffix:
        new_config.update(
            yaml.load(file_with_more_config.open(), Loader=yaml.UnsafeLoader)
        )
    if "json" in file.suffix:
        new_config.update(json.load(file_with_more_config.open()))
    if "cbor" in file.suffix:
        new_config.update(cbor2.load(file_with_more_config.open(mode="rb")))

    if check_conflicts:
        for key in new_config:
            if key in config_dict:
                raise Exception(
                    f"Conflicting key: '{key}' found in {file}. Please rename one of the keys."
                )

    dict_to_add_to.update(**new_config)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("config_directory", type=str)
    parser.add_argument("output_cbor_path", type=str)

    args = parser.parse_args()

    config_dir_path = pathlib.Path(args.config_directory)
    override_dir_path = pathlib.Path(args.config_directory) / "override"
    output_cbor_path = pathlib.Path(args.output_cbor_path)

    config_dict = {}

    for file in config_dir_path.glob("*"):
        add_to_config(config_dict, file)

    for file in override_dir_path.glob("*"):
        add_to_config(config_dict, file, check_conflicts=False)

    with output_cbor_path.open(mode="wb") as fp:
        cbor2.dump(config_dict, fp)
