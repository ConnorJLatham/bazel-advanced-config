import cbor2
import yaml
import argparse
from pathlib import Path
import json
import tomllib
import glob


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
    if "toml" in file.suffix:
        new_config.update(tomllib.load(file_with_more_config.open(mode="rb")))

    if check_conflicts:
        for key in new_config:
            if key in dict_to_add_to:
                raise Exception(
                    f"Conflicting key: '{key}' found in {file_with_more_config}. Please rename one of the keys."
                )

    dict_to_add_to.update(**new_config)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config_file_paths", type=Path, action="append")
    parser.add_argument(
        "--override_config_file_paths", type=Path, action="append", default=[]
    )
    parser.add_argument("--output_cbor_path", type=Path)

    args = parser.parse_args()

    config_dict = {}

    for file in args.config_file_paths:
        add_to_config(config_dict, file)

    for file in args.override_config_file_paths:
        add_to_config(config_dict, file, check_conflicts=False)

    with args.output_cbor_path.open(mode="wb") as fp:
        cbor2.dump(config_dict, fp)
