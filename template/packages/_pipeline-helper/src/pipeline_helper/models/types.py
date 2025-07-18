"""Types."""

from typing import TypeVar

from pydantic import BaseModel

Model = TypeVar("Model", bound=BaseModel)
"""Model type."""
