import argparse
import jinja2
from jinja2 import Environment, StrictUndefined, FileSystemLoader
from pathlib import Path
import cbor2


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--template_file_paths", type=Path, action="append")
    parser.add_argument("--cbor_config_path", type=Path, default=None)
    parser.add_argument("--config_keyword", type=str, default="")

    return parser.parse_args()


def create_jinja_environment(template_files_dir, jinja_config={}):
    print(template_files_dir)
    return Environment(
        loader=FileSystemLoader(searchpath="./"),
        undefined=StrictUndefined,
        autoescape=False,
        trim_blocks=True,
        lstrip_blocks=True,
        **jinja_config,
    )


if __name__ == "__main__":
    args = parse_args()

    if args.cbor_config_path:
        config = cbor2.load(args.cbor_config_path.open(mode="rb"))
    else:
        config = {}

    if args.config_keyword:
        config = {args.config_keyword: config}

    # TODO add jinja options file here
    jinja_env = create_jinja_environment(args.template_file_paths)

    for template_name in args.template_file_paths:
        try:
            rendered_text = jinja_env.get_template(str(template_name)).render(**config)
        except jinja2.exceptions.UndefinedError as undefined_err:
            raise Exception(
                "You seemed to have used an incorrect string when referencing config "
                "in one of your templates! Please ensure you reference other config "
                f"with the correct keyword: {undefined_err}"
            )
        except Exception as err:
            raise Exception(f"Seems like we dont capture this error: {err}")

        Path(f"./rendered/{template_name.name}").write_text(rendered_text)
