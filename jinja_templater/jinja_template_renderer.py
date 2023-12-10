import argparse
import jinja2
from jinja2 import Environment, StrictUndefined, FileSystemLoader
from pathlib import Path
import cbor2


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--template_files_dir", type=Path)
    parser.add_argument("--rendered_files_dir", type=Path)
    parser.add_argument("--cbor_config_path", type=Path, default=None)
    parser.add_argument("--config_keyword", type=str, default="")

    return parser.parse_args()


def create_jinja_environment(template_files_dir, jinja_config={}):
    jinja_env = Environment(
        loader=FileSystemLoader(template_files_dir),
        undefined=StrictUndefined,
        autoescape=False,
        trim_blocks=True,
        lstrip_blocks=True,
        **jinja_config,
    )


if __name__ == "__main__":
    args = parse_args()

    print(args)

    template_files_dir = args.template_files_dir
    rendered_files_dir = args.rendered_files_dir

    if args.cbor_config_path:
        config = cbor2.load(args.cbor_config_path.open(mode="rb"))
    else:
        config = {}

    if args.config_keyword:
        config = {args.config_keyword: config}
    # jinja_config = args.jinja_config_path

    jinja_env = create_jinja_environment(template_files_dir)

    # Render each template, write to rendered dir
    for template_name in jinja_env.list_templates():
        try:
            rendered_text = jinja_env.get_template(template_name).render(
                **combined_config
            )
        except jinja2.exceptions.UndefinedError as undefined_err:
            raise Exception(
                "You seemed to have used an incorrect string when referencing config "
                "in one of your templates! Please ensure you reference other config "
                f"with the correct keyword: {undefined_err}"
            )
        except Exception as err:
            raise Exception(f"Seems like we dont capture this error: {err}")

        (rendered_files_dir / template_name).write_text(rendered_text)
