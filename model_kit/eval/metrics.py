"""Retrieval-evaluation metrics for PixelSearch (framework only — NO results).

Every function operates on a *ranked list of predicted ids* plus a *set of
relevant ids* (ground truth). Feed these with MEASURED retrievals only; this
module never generates or assumes data. See eval/README.md for the protocol.
"""
from typing import List, Sequence, Set


def precision_at_k(ranked: Sequence[str], relevant: Set[str], k: int) -> float:
    """Fraction of the top-k that are relevant."""
    if k <= 0:
        return 0.0
    topk = ranked[:k]
    if not topk:
        return 0.0
    hits = sum(1 for x in topk if x in relevant)
    return hits / min(k, len(topk))


def recall_at_k(ranked: Sequence[str], relevant: Set[str], k: int) -> float:
    """Fraction of all relevant items found within the top-k."""
    if not relevant:
        return 0.0
    hits = sum(1 for x in ranked[:k] if x in relevant)
    return hits / len(relevant)


def average_precision(ranked: Sequence[str], relevant: Set[str]) -> float:
    """AP = mean of precision@rank taken at each relevant hit."""
    if not relevant:
        return 0.0
    hits = 0
    score = 0.0
    for i, x in enumerate(ranked, start=1):
        if x in relevant:
            hits += 1
            score += hits / i
    return score / len(relevant)


def mean_average_precision(
    rankings: List[Sequence[str]], relevants: List[Set[str]]
) -> float:
    """mAP = mean of per-query average precision."""
    if not rankings:
        return 0.0
    aps = [average_precision(r, rel) for r, rel in zip(rankings, relevants)]
    return sum(aps) / len(aps)
