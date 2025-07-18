"""Models."""

from collections.abc import Callable
from json import loads

from pipeline_helper.models.types import Model


def get_parser(model: type[Model]) -> Callable[[str], Model]:
    """Get parser for model or JSON-encoded string."""

    def parse(v: Model | str) -> Model:
        """Parse model or JSON-encoded string."""
        return model(**loads(v)) if isinstance(v, str) else v

    return parse
