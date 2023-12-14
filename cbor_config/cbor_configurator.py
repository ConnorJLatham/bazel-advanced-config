import cbor2
import yaml
import argparse
from pathlib import Path
import json
import tomllib


def _recursively_check_dict_for_key(
    dict_to_recurse, key_values_to_check, file_being_checked, root_key_name=""
):
    """
    Args:
        dict_to_recurse (dict): dictionary containing the config.
        keys_to_check (list[str]): check all the keys together to avoid multiple recursive traversals.

    Returns:
        (string, ): _description_
    """
    all_flattened_key_values = {}

    for key_in_dict_to_check, value_in_dict_to_check in dict_to_recurse.items():
        full_key_name = (
            f"{root_key_name}.{key_in_dict_to_check}"
            if root_key_name
            else key_in_dict_to_check
        )

        for key_to_check, value_of_key_to_check in key_values_to_check.items():
            if key_to_check == key_in_dict_to_check:
                exception_text = (
                    f"Found existing key/value '{key_to_check}: {value_of_key_to_check}' (full nested name: '{full_key_name}')!\n"
                    f"Conflicts with key/value {key_in_dict_to_check}: {value_in_dict_to_check} in "
                )

                if file_being_checked.suffix == ".cbor":
                    exception_text += f"bazel target with name {file_being_checked.name.replace(f'{file_being_checked.suffix}', '')}.\n"
                else:
                    exception_text += f"file with name {file_being_checked.name}."

                raise ValueError(exception_text)

            if not isinstance(key_to_check, str):
                raise ValueError(
                    f"Key '{key_to_check}' is not of type 'string'! All keys must be of type 'string'."
                )

        all_flattened_key_values[full_key_name] = value_in_dict_to_check

    # Okay, the key wasnt in this level of dict, lets keep traversing.
    for potential_dict_key, potential_nested_dict in dict_to_recurse.items():
        if isinstance(potential_nested_dict, dict):
            all_flattened_key_values.update(
                **_recursively_check_dict_for_key(
                    potential_nested_dict,
                    key_values_to_check,
                    file_being_checked,
                    root_key_name=potential_dict_key,
                )
            )

    # If we haven't returned yet, we found no conflicts!
    return all_flattened_key_values


def convert_file_to_dict(file):
    if "yaml" in file.suffix:
        return yaml.load(file.open(), Loader=yaml.UnsafeLoader)

    if "json" in file.suffix:
        return json.load(file.open())
    if "cbor" in file.suffix:
        return cbor2.load(file.open(mode="rb"))
    if "toml" in file.suffix:
        return tomllib.load(file.open(mode="rb"))

    raise Exception(
        f"File {file} did not create new config and is empty! Cannot include empty files."
    )


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config_file_paths", type=Path, action="append")
    parser.add_argument(
        "--override_config_file_paths", type=Path, action="append", default=[]
    )
    parser.add_argument("--output_cbor_path", type=Path)

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    # The full dict to turn into a .cbor.
    total_config_dict = {}
    # A list of all full keypaths and their values.
    flattened_total_config_dict = {}

    for file in args.config_file_paths:
        new_config_dict = convert_file_to_dict(file)

        # We search the new dictionary for any keys we already added.
        # This might look like "my.nested.path.to.key"
        flattened_total_config_dict.update(
            **_recursively_check_dict_for_key(
                new_config_dict,
                flattened_total_config_dict,
                file,
            )
        )

        total_config_dict.update(**new_config_dict)

    for file in args.override_config_file_paths:
        total_config_dict.update(**convert_file_to_dict(file))

    with args.output_cbor_path.open(mode="wb") as fp:
        cbor2.dump(total_config_dict, fp)
