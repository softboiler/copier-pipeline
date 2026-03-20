from pipeline_helper.notebook_namespaces import get_nb_ns

from copier_pipeline_pipeline.stages.example import Example as Params


def main(params: Params):
    nb = params.deps.nb.read_text(encoding="utf-8")
    get_nb_ns(nb=nb, params={"PARAMS": params.model_dump_json()})


if __name__ == "__main__":
    main(Params())
