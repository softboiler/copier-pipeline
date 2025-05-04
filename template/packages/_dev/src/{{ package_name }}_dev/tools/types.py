"""Types."""

from typing import Literal, TypeAlias

ChangeType: TypeAlias = Literal["breaking", "deprecation", "change"]
"""Type of change to add to changelog."""
