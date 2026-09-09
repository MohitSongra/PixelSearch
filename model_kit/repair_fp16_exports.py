#!/usr/bin/env python3
"""Rebuild valid FP16 MobileCLIP artifacts from the existing fp32 exports."""

from pathlib import Path

from fp16_conversion import rebuild_fp16_artifacts


if __name__ == '__main__':
    rebuild_fp16_artifacts(Path(__file__).resolve().parent / 'out')
