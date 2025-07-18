"""Types."""

from typing import TYPE_CHECKING, Any, ParamSpec, Protocol, TypeVar

if TYPE_CHECKING:
    from pipeline_helper.models.column import Col


class SupportsMul(Protocol):
    """Protocol for types that support multiplication."""

    def __mul__(self, other: Any) -> Any: ...


SupportsMul_T = TypeVar("SupportsMul_T", bound=SupportsMul)
"""Type that supports multiplication."""
P = TypeVar("P", contravariant=True)
"""Contravariant type to represent parameters."""
R = TypeVar("R", covariant=True)
"""Covariant type to represent returns."""
Ps = ParamSpec("Ps")
"""Parameter type specification."""


class Transform(Protocol[P, R, Ps]):
    def __call__(
        self, v: P, src: "Col", dst: "Col", /, *args: Ps.args, **kwds: Ps.kwargs
    ) -> R: ...
