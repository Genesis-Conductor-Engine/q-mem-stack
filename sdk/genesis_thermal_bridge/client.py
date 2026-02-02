"""Orchestration client for the Genesis Thermal Bridge."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict

from .energy_credit_ledger import EnergyCreditLedger
from .extropic_bridge import ExtropicBridgeInterface


@dataclass
class ThermalBridgeClient:
    """Coordinates ledger checks with bridge calls."""

    ledger: EnergyCreditLedger
    bridge: ExtropicBridgeInterface

    def submit_operation(self, energy_cost: float, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Debit energy and forward payload to the bridge."""

        self.ledger.debit(energy_cost)
        return self.bridge.send(payload)
