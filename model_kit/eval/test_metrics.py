"""Unit tests for the metric FUNCTIONS on synthetic inputs. This validates the
math, not any model — no retrieval results are fabricated. Run: python test_metrics.py
"""
from metrics import (
    precision_at_k,
    recall_at_k,
    average_precision,
    mean_average_precision,
)


def approx(a, b, eps=1e-9):
    return abs(a - b) <= eps


def main():
    ranked = ["a", "b", "c", "d", "e"]
    rel = {"a", "c", "e"}  # relevant at ranks 1, 3, 5

    assert precision_at_k(ranked, rel, 1) == 1.0
    assert approx(precision_at_k(ranked, rel, 3), 2 / 3)
    assert precision_at_k(ranked, rel, 0) == 0.0

    assert approx(recall_at_k(ranked, rel, 3), 2 / 3)  # found a, c of {a,c,e}
    assert recall_at_k(ranked, rel, 5) == 1.0
    assert recall_at_k(ranked, set(), 5) == 0.0

    ap = (1 / 1 + 2 / 3 + 3 / 5) / 3  # precision at each hit / #relevant
    assert approx(average_precision(ranked, rel), ap)
    assert average_precision(ranked, set()) == 0.0

    # second query: one relevant "a" at rank 2 → AP = (1/2)/1 = 0.5
    assert approx(
        mean_average_precision([ranked, ["x", "a"]], [rel, {"a"}]),
        (ap + 0.5) / 2,
    )

    print("all metric tests passed")


if __name__ == "__main__":
    main()
