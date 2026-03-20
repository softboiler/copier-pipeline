"""Pipeline types."""

from collections.abc import Callable, ItemsView, Iterable, Mapping
from typing import Any, Literal, TypeAlias, TypeVar

from pydantic_settings import BaseSettings

T = TypeVar("T")
Slicer: TypeAlias = tuple[int, int]
Slicer2D: TypeAlias = tuple[Slicer, Slicer]


Bound = TypeVar("Bound", bound=tuple[float | str, float | str])
"""Boundary for a parameter to be fitted."""

Guess = TypeVar("Guess", bound=float)
"""Guess for a parameter to be fitted."""

Coupon = Literal["A0", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9"]
"""The coupon attached to the rod for this trial."""

Rod = Literal["W", "X", "Y", "R"]
"""The rod used in this trial."""

Group = Literal["control", "porous", "hybrid"]
"""The group that this sample belongs to."""

Joint = Literal["paste", "epoxy", "solder", "none"]
"""The method used to join parts of the sample in this trial."""

Sample = Literal["B3"]
"""The sample attached to the coupon in this trial."""

Action: TypeAlias = Literal["default", "error", "ignore", "always", "module", "once"]
"""Action to take for a warning."""

Freezable: TypeAlias = (
    Callable[..., Any] | Mapping[str, Any] | ItemsView[str, Any] | Iterable[Any]
)
"""Value that can be frozen."""

SettingsModel = TypeVar("SettingsModel", bound=BaseSettings)
"""Settings model type."""


Params: TypeAlias = Mapping[str, Any]
Attributes: TypeAlias = Iterable[str]

SimpleNamespaceReceiver: TypeAlias = Callable[..., Any]
"""Should be a `Callable` with an `ns` parameter expecting a `SimpleNamespace`."""
