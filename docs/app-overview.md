# App Overview

## What PDFly is

PDFly is an Android (and, later, iOS) utility app for four common PDF tasks:

- **Compress PDF** — reduce file size, with a Low/Medium/High quality tradeoff
- **Merge PDFs** — combine two or more PDFs into one
- **Split PDF** — extract a page range from a PDF into a new file
- **Images to PDF** — turn a set of photos into a single PDF

All processing happens **entirely on-device**. Nothing is uploaded anywhere, there's
no account or sign-in, and the app works with no internet connection.

## Who it's for

Anyone who hits a "compress this PDF," "combine these PDFs," or "turn these photos
into a PDF" moment and wants it done in a few taps without installing a bloated
office suite or trusting a random website with their files. The search intent behind
this ("compress pdf app", "merge pdf free") is high-volume and consistent, which is
why this niche was chosen over a more original idea.

## How it makes money

Google AdMob, via:
- A banner ad on the Home screen only (never on the processing/result screens, so it
  doesn't interrupt the core task)
- An interstitial shown after export, capped to at most once every 3 exports, never
  on the very first export a user makes

There's no account system, no subscription, and no in-app purchases in the current
version — a "Remove ads" settings entry exists as a placeholder for a future IAP.

## What's deliberately *not* in scope (v1)

Cloud sync, login/accounts, OCR, e-signatures, and in-app PDF text editing. These are
all things that would meaningfully increase complexity and maintenance burden for a
solo-maintained app; the bet is that the four core tools cover the vast majority of
real search intent on their own.

## Current status

- Core app, all four tools, AdMob (test + real ad units), app icon, dark mode: done
- On-device integration tests covering the PDF pipeline: done
- Play Store listing setup (in progress) — see [release-checklist.md](release-checklist.md)
- iOS: project is scaffolded and builds, but AdMob/App Store setup for iOS hasn't
  been done yet (Android is the primary target)
