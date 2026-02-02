"""Reusable energy credit ledger for enforcing energy budgets."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict


class InsufficientEnergyError(RuntimeError):
    """Raised when an energy debit would drop the balance below zero."""


@dataclass
class EnergyCreditLedger:
    """Tracks an energy credit balance and applies debits/credits.

    Args:
        initial_balance: Starting balance in joules.
        metadata: Optional metadata for auditing (e.g., run id).
    """

    initial_balance: float
    metadata: Dict[str, str] = field(default_factory=dict)
    _balance: float = field(init=False, repr=False)

    def __post_init__(self) -> None:
        if self.initial_balance < 0:
            raise ValueError("initial_balance must be non-negative")
        self._balance = float(self.initial_balance)

    @property
    def balance(self) -> float:
        """Return the current balance."""

        return self._balance

    def can_debit(self, amount: float) -> bool:
        """Check if a debit is possible without going negative."""

        if amount < 0:
            raise ValueError("amount must be non-negative")
        return self._balance - amount >= 0

    def debit(self, amount: float) -> float:
        """Debit energy from the ledger and return the new balance."""

        if amount < 0:
            raise ValueError("amount must be non-negative")
        if not self.can_debit(amount):
            raise InsufficientEnergyError("energy credit balance would go negative")
        self._balance -= amount
        return self._balance

    def credit(self, amount: float) -> float:
        """Credit energy to the ledger and return the new balance."""

        if amount < 0:
            raise ValueError("amount must be non-negative")
        self._balance += amount
        return self._balance

    def reset(self) -> None:
        """Reset balance back to the initial value."""

        self._balance = float(self.initial_balance)

    def to_dict(self) -> Dict[str, float]:
        """Serialize the ledger state."""

        return {
            "initial_balance": float(self.initial_balance),
            "balance": float(self._balance),
        }
