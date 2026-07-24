# NeurIPS / SCI Journal Review (Updated)
**Paper Title:** flutter_kiwi_nlp: A Native-First, Cross-Platform Korean NLP Plugin for Flutter
**Review Date:** February 18, 2026
**Reviewer Role:** Senior Reviewer (NeurIPS/SCI Systems Track)

---

## 1. Summary
This paper presents `flutter_kiwi_nlp`, a Flutter plugin designed to provide Korean morphological analysis using the Kiwi engine. The work focuses on "systems integration" rather than algorithmic novelty, bridging two distinct runtime environments: a native C++ path (accessed via Dart FFI) for mobile/desktop, and a WebAssembly (WASM) path for the web, all under a unified Dart API.

The revised report includes significantly expanded performance evaluation, introducing boundary-decomposed metrics to isolate FFI cost and adding Linux/Windows CI benchmarks. Notably, it reports a "warm-path throughput reversal" where the Flutter implementation now outperforms the Python baseline in steady-state execution across measured platforms.

## 2. Strong Points (Strengths)

**1. Engineering Depth and "Glass-Box" Profiling:**
The paper goes beyond standard "black-box" benchmarking by introducing **Boundary-Decomposed Measurement**. By distinguishing between "Pure APS" (compute only) and "Full APS" (including bridging), the authors explicitly quantify the JSON serialization overhead (19.95% on Android to 47.93% on iOS). This level of transparency effectively turns a performance limitation into a valuable systems insight.

**2. Improved Performance Profile:**
The updated benchmarks show a significant performance achievement: `flutter_kiwi_nlp` now demonstrates higher warm-path throughput than the Python-native `kiwipiepy` baseline across all primary test targets (Desktop **3.12x**, iOS Simulator **3.87x**, Android Emulator **1.52x**). This effectively counters the common assumption that Flutter/Dart FFI is inherently slower than Python native bindings for this class of workload.

**3. Comprehensive Reproducibility & Gold-Corpus Validation:**
-   **Reproducibility:** A detailed manifest with commit hashes, exact CLI commands for every target, and hardware specifications ensures these results are verifiable.
-   **Correctness:** The addition of a **Gold-Corpus Evaluation** (checking token/POS agreement against separate "Web" and "Written" datasets) adds necessary rigor, confirming that the performance gains do not come at the cost of linguistic accuracy (sub-1pp difference in agreement).

**4. Systems-Level Honesty:**
The paper openly documents "Session-Length Effective Throughput," admitting that despite faster raw execution, cold-start initialization still penalizes short sessions. This honest analysis of the "cold start vs. warm throughput" trade-off adds significant credibility.

## 3. Weaknesses & Areas for Improvement

**1. Simulation vs. Real Device Gap:**
While the benchmark suite is extensive (macOS, iOS Sim, Android Emu, Linux/Windows CI), it still lacks physical mobile device measurements. The "Threats to Validity" section acknowledges this, but for an "On-Device AI" paper, seeing at least one data point from a physical Snapdragon/A-series chip would be preferred to confirm thermal/throttling behavior matches the simulator findings.

**2. Significant JSON Bridge Overhead:**
The quantified "Boundary Loss" (~20-48%) confirms that the current JSON-based transport is a major bottleneck. While the paper justifies this for development velocity and safety, moving to a binary protocol (e.g., FlatBuffers) remains the most obvious path for future optimization. The review accepts this as a documented trade-off rather than a fatal flaw.

**3. Web TTI Quantification:**
The paper discusses Web Time-to-Interactive (TTI) theoretically but does not benchmark it. Given the distinct WASM loading mechanism, empirical TTI data is still missing.

## 4. Overall Assessment
This revision significantly strengthens the paper's contribution. The new benchmark data not only provides a more favorable performance picture (the 1.5x-3.8x warm-path speedup) but effectively justifies the architecture through detailed overhead decomposition.

The work stands out as a rigorous "systems report" that solves a real-world integration problem (Cross-platform Korean NLP) with production-grade engineering (reproducibility, error taxonomy, fail-safe mechanisms). It bridges the gap between academic algorithm design and practical application engineering.

## 5. Decision
**Recommendation:** **Accept** (Strong Accept)

The paper is a high-quality systems contribution. The updated evaluation section transforms what might have been a "slower but useful" wrapper into a "high-performance, transparency-first" integration study.

---
**Confidential Comments to Authors:**
*   *The "Boundary-Decomposed Measurement" section is excellent; it turns the JSON overhead from a liability into an interesting systems measurement.*
*   *The "Warm-Path Throughput Reversal" is a compelling highlight. Make sure this is emphasized in the abstract (as you have done).*
*   *The physical device data remains the only missing piece for a "perfect" score, but the current simulator methodology is sufficient given the detailed reproducibility manifest.*
