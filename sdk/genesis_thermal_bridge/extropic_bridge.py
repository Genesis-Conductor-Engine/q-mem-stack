"""Mock interface for Extropic TSU hardware calls."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict


@dataclass
class ExtropicBridgeInterface:
    """Mockable hardware bridge for local simulations."""

    endpoint: str = "local://diamond-vault"

    def send(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Send a payload to the mock TSU interface."""

        return {
            "endpoint": self.endpoint,
            "accepted": True,
            "echo": payload,
        }
