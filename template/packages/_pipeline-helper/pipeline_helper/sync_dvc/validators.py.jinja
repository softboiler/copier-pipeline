"""Validators for syncing `dvc.yaml` and `params.yaml` with pipeline specification."""

from collections.abc import Sequence
from datetime import datetime
from itertools import chain
from pathlib import Path
from typing import Any, Literal

from cappa.arg import Arg
from more_itertools import first
from pydantic import BaseModel, ValidationInfo
from pydantic.fields import FieldInfo
from pydantic.functional_validators import ModelWrapValidatorHandler

from pipeline_helper import sync_dvc
from pipeline_helper.sync_dvc.contexts import DVC
from pipeline_helper.sync_dvc.dvc import OutFlags, Stage
from pipeline_helper.sync_dvc.types import Model


class Constants(BaseModel):
    """Constants."""

    table_key: str = sync_dvc.const.table_key
    """Key for the global parameters table."""
    out_config: OutFlags = OutFlags(persist=True)
    """Default `dvc.yaml` configuration for `outs`."""
    skip_cloud: list[str] = ["data/mboxes", "data/reqs"]
    """These paths are too large and unwieldy to cache or push to cloud storage."""
    out_skip_cloud_config: OutFlags = OutFlags(cache=False, persist=True, push=False)
    """Default `dvc.yaml` configuration for `outs` that skip the cloud."""


const = Constants()


def dvc_prepare_stage(
    data: dict[str, Any],
    handler: ModelWrapValidatorHandler[Model],
    info: ValidationInfo,
    model: type[Model],
) -> Model:
    """Prepare a pipeline stage for `dvc.yaml`."""
    if not (dvc := info.context.get(DVC)):  # ty:ignore[unresolved-attribute]
        return handler(data)
    if not dvc.model.stages:
        dvc.params[const.table_key] = {}
    name = model.__module__.split(".")[-1]
    if dvc.model.stages.get(name):
        return handler(data)
    dvc.stage = Stage(cmd="")
    dvc.stage.params.append(const.table_key)
    dvc.model.stages[name] = dvc.stage
    sep = " "
    dvc.stage.cmd = sep.join([
        "./j.ps1 notes-pipeline",
        f"stage {name.replace('_', '-')}",
    ])
    self = handler(data)
    dvc.stage.cmd = f'pwsh -Command "{dvc.stage.cmd}"'
    return self


def dvc_add_param(
    value: Any, info: ValidationInfo, fields: dict[str, FieldInfo]
) -> Any:
    # sourcery skip: low-code-quality
    """Add param to global parameters and stage command for `dvc.yaml`."""
    param = first(
        (m for m in fields[info.field_name].metadata if isinstance(m, Arg)),  # ty:ignore[invalid-argument-type]
        default=Arg,
    )
    if (
        (dvc := info.context.get(DVC))  # ty:ignore[unresolved-attribute]
        and not param.hidden
        and (params := dvc.params.get(const.table_key)) is not None
    ) and isinstance(value, Sequence | bool | int | float | complex | datetime):
        name = info.field_name
        arg = name.replace("_", "-")  # ty:ignore[unresolved-attribute]
        sep = " "
        # ? Add to global parameters list if missing
        if not params.get(name):
            if isinstance(value, bool):
                params[name] = f"--{arg}" if value else f"--no-{arg}"
            elif not isinstance(value, str) and isinstance(value, Sequence):
                values = []
                for v in value:
                    if isinstance(v, Path):
                        v = v.as_posix()
                    elif not isinstance(v, bool | int | float | complex | datetime):
                        return value
                    values.append(v)
                params[name] = sep.join(chain.from_iterable((arg, v) for v in values))
            else:
                params[name] = value
        # ? Append parameter to stage command
        if isinstance(value, bool) or (
            not isinstance(value, str) and isinstance(value, Sequence)
        ):
            args = [f"${{{const.table_key}.{name}}}"]
        else:
            args = [f"--{arg}", f"${{{const.table_key}.{name}}}"]
        dvc.stage.cmd = sep.join([
            *(
                dvc.stage.cmd
                if isinstance(dvc.stage.cmd, list)
                else dvc.stage.cmd.split(sep)
            ),
            *args,
        ])
    return value


def dvc_set_stage_path(
    path: Path, info: ValidationInfo, kind: Literal["deps", "outs"]
) -> Path:
    """Set stage path as a stage dep, plot, or out for `dvc.yaml`."""
    if info.field_name != "context" and (dvc := info.context.get(DVC)):  # ty:ignore[unresolved-attribute]
        path = Path(path).resolve().relative_to(Path.cwd())
        if info.field_name == "plots":
            dvc.plot_dir = path
            return path
        p = path.as_posix()
        getattr(dvc.stage, kind).append(
            p
            if kind == "deps"
            else (
                {p: const.out_skip_cloud_config}
                if p in const.skip_cloud
                else {p: const.out_config}
            )
        )
    return path


def dvc_set_only_sample(
    only_sample: bool, info: ValidationInfo, sample_field: str
) -> bool:
    """Set the only sample for `dvc.yaml` if `only_sample` is enabled."""
    if (
        info.field_name != "context"
        and (dvc := info.context.get(DVC))  # ty:ignore[unresolved-attribute]
        and dvc.plot_dir
        and only_sample
    ):
        dvc.only_sample = info.data[sample_field]
    return only_sample


def dvc_extend_with_timestamp_suffixed_plots(
    times: list[str], info: ValidationInfo
) -> list[str]:
    """Extend stage plots for `dvc.yaml` with timestamp-suffixed plots."""
    if info.field_name != "context" and (dvc := info.context.get(DVC)) and dvc.plot_dir:  # ty:ignore[unresolved-attribute]
        dvc.stage.plots.extend(
            sorted(
                (dvc.plot_dir / ("_".join([f"{name}", time]) + ".png")).as_posix()
                for name in dvc.plot_names
                for time in ([dvc.only_sample] if dvc.only_sample else times)
            )
        )
        dvc.plot_dir = None
        dvc.plot_names.clear()
    return times


def dvc_extend_with_named_plots_if_missing(
    model: BaseModel, info: ValidationInfo
) -> Any:
    """Extend stage plots for `dvc.yaml` with named plots if plots haven't been set."""
    if (
        info.field_name != "context"
        and (dvc := info.context.get(DVC))  # ty:ignore[unresolved-attribute]
        and dvc.plot_dir
        and not dvc.stage.plots
    ):
        dvc.stage.plots.extend(
            sorted((dvc.plot_dir / f"{name}.png").as_posix() for name in dvc.plot_names)
        )
        dvc.plot_dir = None
        dvc.plot_names.clear()
    return model
