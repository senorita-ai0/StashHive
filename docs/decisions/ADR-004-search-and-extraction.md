# ADR-004: Metadata search first; extraction is gated

- **Status:** Proposed; approval pending
- **Date:** 2026-10-21

## Context

Search is central to the product. OCR and PDF extraction can improve discovery but may raise binary size, memory, latency, and accuracy concerns, especially for Urdu/Nastaleeq.

## Proposed decision

MVP search must cover saved metadata and user-entered text. Treat OCR/PDF extraction as a separate proof of concept and add it only if offline behavior, platform support, tested accuracy, and package-size cost are acceptable.

## Trade-offs

The first version cannot find words that exist only inside images/PDFs unless users add text manually. This is preferable to falsely promising unreliable extraction or silently relying on cloud processing.

## POC acceptance

Create a labelled sample set containing English screenshots, Urdu script/Nastaleeq samples, Roman Urdu, mixed-language screenshots, scanned PDFs, and digital PDFs. Measure exact/near text quality, failures, file size change, latency, memory, and whether processing occurs fully offline. Document licensing and platform compatibility.
