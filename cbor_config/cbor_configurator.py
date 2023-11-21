import cbor2
import yaml
import argparse
import pathlib
import json

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("config_directory", type=str)
    parser.add_argument("output_cbor_path", type=str)

    args = parser.parse_args()

    config_dir_path = pathlib.Path(args.config_directory)
    output_cbor_path = pathlib.Path(args.output_cbor_path)

    config_dict = {}

    for file in config_dir_path.glob("*"):
        new_config = {}
        if "yaml" in file.suffix:
            new_config.update(yaml.load(file.open(), Loader=yaml.UnsafeLoader))
        if "json" in file.suffix:
            new_config.update(json.load(file.open()))
        if "cbor" in file.suffix:
            new_config.update(cbor2.load(file.open(mode="rb")))

        for key in new_config:
            if key in config_dict:
                raise Exception(
                    f"Conflicting key: '{key}' found in {file}. Please rename one of the keys."
                )

        config_dict.update(**new_config)

    with output_cbor_path.open(mode="wb") as fp:
        cbor2.dump(config_dict, fp)
