import argparse
import jinja2
from pathlib import Path
import cbor2


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--template_file_path", type=Path)
    parser.add_argument("--rendered_file_path", type=Path)
    parser.add_argument("--cbor_config_path", type=Path, default=None)
    parser.add_argument("--template_dep_path", type=Path, action="append", default=[])

    return parser.parse_args()


def create_jinja_environment(template_files_paths, jinja_config={}):
    template_paths = [
        template_file_path.parent for template_file_path in template_files_paths
    ]

    return jinja2.Environment(
        loader=jinja2.FileSystemLoader(template_paths),
        undefined=jinja2.StrictUndefined,
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

    # TODO add jinja options file here
    jinja_env = create_jinja_environment(
        [args.template_file_path] + args.template_dep_path
    )

    try:
        rendered_text = jinja_env.get_template(args.template_file_path.name).render(
            **config
        )
    except jinja2.exceptions.UndefinedError as undefined_err:
        raise Exception(
            "You seemed to have used an incorrect string when referencing config "
            "in one of your templates! Please ensure you reference other config "
            f"with the correct keyword: {undefined_err}"
        )
    except Exception as err:
        raise Exception(f"Seems like we dont capture this error: {err}")

    args.rendered_file_path.write_text(rendered_text)
