"""Sync `dvc.yaml` and `params.yaml` with pipeline specification."""

from collections.abc import Sized
from importlib import import_module
from inspect import getfile, getmembers
from pathlib import Path
from types import NoneType
from typing import Any, get_args

from cappa.base import invoke
from context_models import CONTEXT, PLUGIN_SETTINGS, ContextStore
from more_itertools import first, one
from pydantic import create_model
from pydantic.alias_generators import to_pascal
from yaml import safe_dump, safe_load

from pipeline_helper.environment import run
from pipeline_helper.sync_dvc import SyncDvc, const
from pipeline_helper.sync_dvc.contexts import DVC, DvcContext, DvcContexts
from pipeline_helper.sync_dvc.dvc import DvcYamlModel, Stage
from pipeline_helper.sync_dvc.types import Model


def main(params: SyncDvc):
    """Sync `dvc.yaml` and `params.yaml` with pipeline specification."""
    dvc = get_dvc_context(
        params=(
            safe_load(params.params.read_text(encoding="utf-8"))
            if params.params.exists()
            else {}
        ),
        stages=params.stages,
    )
    (params.root / params.pipeline).write_text(
        encoding="utf-8",
        data=safe_dump(
            indent=2,
            width=float("inf"),
            data=dvc_clear_defaults(dvc.model).model_dump(exclude_none=True),
        ),
    )
    (params.root / params.params).write_text(
        encoding="utf-8",
        data=safe_dump(
            indent=2,
            width=float("inf"),
            data={
                **dvc.params,
                **(
                    {}
                    if params.update_param_values or not params.params.exists()
                    else {
                        k: v
                        for k, v in safe_load(
                            params.params.read_text(encoding="utf-8")
                        ).items()
                        if k in dvc.params
                    }
                ),
            },
        ),
    )
    run(args="pre-commit run --all-files prettier", check=False, capture_output=True)


def get_dvc_context(params: dict[str, Any], stages: str) -> DvcContext:
    """Get DVC context for pipeline model and stages."""
    stage_models = {
        p.stem: dict(getmembers(import_module(f"{stages}.{p.stem}")))[to_pascal(p.stem)]
        for p in Path(getfile(import_module(stages))).parent.iterdir()
        if not p.stem.startswith("_")
    }
    stage = first(stage_models.values())

    class CombinedContext(stage.model_fields["context"].annotation, DvcContexts): ...

    return create_model(  # pyright: ignore[reportCallIssue]
        "_Stages",
        __base__=ContextStore,
        **{k: (v, ...) for k, v in {CONTEXT: CombinedContext, **stage_models}.items()},  # pyright: ignore[reportArgumentType]
    )(**{
        CONTEXT: {
            **stage.model_config[PLUGIN_SETTINGS][CONTEXT],
            **DvcContexts(dvc=DvcContext()),
        },
        **{
            field: {
                k: (("--no" not in v) if isinstance(v, str) and "--" in v else v)
                for k, v in params[const.table_key].items()
                if k in stage.model_fields
            }
            for field, stage in stage_models.items()
            if field != CONTEXT
        },
    }).context[DVC]


def dvc_clear_defaults(model: DvcYamlModel) -> DvcYamlModel:
    """Clear defaults in DVC model and its nested stages."""
    model = clear_defaults(DvcYamlModel.model_validate(model))
    for name, stage in model.stages.items():
        if isinstance(stage, Stage):
            stage = clear_defaults(stage)
            for i, out in enumerate(stage.outs):
                if isinstance(out, dict):
                    stage.outs[i] = {one(out.keys()): clear_defaults(one(out.values()))}
            model.stages[name] = stage
    return model


def clear_defaults(model: Model) -> Model:
    """Clear default fields of a model."""
    model = model.model_copy(deep=True)
    for (field, value), info in zip(
        dict(model).items(), model.model_fields.values(), strict=True
    ):
        if (
            value is not None  # noqa: PLR0916
            and (ann := info.annotation)
            and (
                (isinstance(value, Sized) and not len(value))
                or (value == info.default and NoneType in get_args(ann))
            )
        ):
            setattr(model, field, None)
    return model


if __name__ == "__main__":
    invoke(SyncDvc)
