"""Types."""

from typing import TYPE_CHECKING, Literal, TypeVar

if TYPE_CHECKING:
    from pipeline_helper.models.stage import DfsPlotsOuts

StagePathsKind = Literal["deps", "outs"]
DfsPlotsOuts_T = TypeVar("DfsPlotsOuts_T", bound="DfsPlotsOuts", covariant=True)
