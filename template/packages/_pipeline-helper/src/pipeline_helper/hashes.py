"""Hash utilities."""

from collections.abc import Callable, Hashable, ItemsView, Iterable, Mapping
from inspect import getsource, signature
from typing import Any

from cachier.config import _default_hash_func  # pyright: ignore[reportMissingImports]

from pipeline_helper.types import Freezable


def hash_args(
    fun: Callable[..., Any], args: Iterable[Any], kwds: Mapping[str, Any]
) -> str:
    """Hash a particular set of arguments meant to be passed to a particular function.

    Passing this function, with `fun` applied via `partial`, to `cachier`'s `hash_func`
    decorator allows us to create a cacheable form of `fun`.

    Returns: Hash of the arguments.

    Args:
        fun: Function from which the signature will be generated.
        args: Positional arguments to hash.
        kwds: Keyword arguments to hash.

    Example:
        ```Python
        import cachier
        from functools import partial

        @cachier(hash_func=partial(hash_args_PATCHED, uncached_function))
        def cached_function(*args, *kwds):
            return uncached_function(*args, *kwds)
        ```
    """
    bound_args = signature(fun).bind(*args, **kwds).arguments
    return _default_hash_func(
        (), {param: freeze(val) for param, val in bound_args.items()}
    )


def freeze(v: Hashable | Freezable | Any) -> Hashable:
    """Make value hashable."""
    match v:
        case Hashable():
            return v
        case Callable():  # type: ignore  # pyright: 1.1.347
            getsource(v)
        case Mapping():
            return tuple((k, freeze(v)) for k, v in v.items())
        case ItemsView():
            return tuple((k, freeze(v)) for k, v in v)
        case Iterable():
            return tuple(freeze(v) for v in v)
        case _:
            raise TypeError(
                f"{type(v)} not Hashable, Callable, Mapping, ItemsView, or Iterable."
            )
