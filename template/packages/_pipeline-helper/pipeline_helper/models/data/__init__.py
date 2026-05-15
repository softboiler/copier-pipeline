"""Output data model."""

from pandas import DataFrame
from pydantic import BaseModel, Field


class Dfs(BaseModel, arbitrary_types_allowed=True):
    """Data frames."""

    src: DataFrame = Field(default_factory=DataFrame)
    """Source data for this stage."""
    dst: DataFrame = Field(default_factory=DataFrame)
    """Destination data for this stage."""


class Plots(BaseModel, arbitrary_types_allowed=True):
    """Plots."""


class Data[Dfs_T, Plots_T](BaseModel):
    """Data frame and plot outputs."""

    dfs: Dfs_T = Field(default_factory=Dfs)  # ty:ignore[invalid-assignment]
    plots: Plots_T = Field(default_factory=Plots)  # ty:ignore[invalid-assignment]
