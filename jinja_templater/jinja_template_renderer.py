import argparse
import jinja2
from jinja2 import Environment, StrictUndefined, FileSystemLoader
from pathlib import Path
import cbor2


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--template_file_paths", type=Path, action="append")
    parser.add_argument("--rendered_directory_path", type=Path)
    parser.add_argument("--cbor_config_path", type=Path, default=None)
    parser.add_argument("--config_keyword", type=str, default="")

    return parser.parse_args()


def create_jinja_environment(template_files_paths, jinja_config={}):
    template_paths = [
        template_file_path.parent for template_file_path in template_files_paths
    ]

    return Environment(
        loader=FileSystemLoader(template_paths),
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

    rendered_dir = Path(args.rendered_directory_path)
    rendered_dir.mkdir(parents=True, exist_ok=True)

    for template_name in args.template_file_paths:
        try:
            rendered_text = jinja_env.get_template(template_name.name).render(**config)
        except jinja2.exceptions.UndefinedError as undefined_err:
            raise Exception(
                "You seemed to have used an incorrect string when referencing config "
                "in one of your templates! Please ensure you reference other config "
                f"with the correct keyword: {undefined_err}"
            )
        except Exception as err:
            raise Exception(f"Seems like we dont capture this error: {err}")

        rendered_file = rendered_dir / f"{template_name.name}"
        rendered_file.write_text(rendered_text)
