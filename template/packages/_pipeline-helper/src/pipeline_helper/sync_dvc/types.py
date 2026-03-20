"""Types."""

from typing import TYPE_CHECKING, TypeAlias, TypeVar

from pydantic import BaseModel

if TYPE_CHECKING:
    from pipeline_helper.sync_dvc.contexts import DvcContexts

DvcValidationInfo: TypeAlias = ContextValidationInfo["DvcContexts"]
DvcSerializationInfo: TypeAlias = ContextSerializationInfo["DvcContexts"]


Model = TypeVar("Model", bound=BaseModel)
"""Pydantic model type."""
