---
name: aoneahsan-cccs-social-post-cards
description: 'Custom LinkedIn post images and PDF carousels for the owner''s production products: one card per post, designed from that product''s own tokens, fonts, mark, art and fresh real captures, with an in-image CTA and the main link; never a shared template or an AI look. Use when making or reviewing any social post image, LinkedIn card, carousel or document post, a linkedin-social-content assets folder, or when a post image looks generic.'
---

# Social post cards

🔴 **Floor:** `aoneahsan-cccs-custom-made`.

## Overview

A post image is the product's own poster for one idea. It must look like the product's design team made it for
this exact post: the product's palette, type, mark and illustrations, around a real screen of the live app. The
owner judged the June shared-template cards (dark panel, bullet rows, footer URL) "rubbish" and AI-looking
(2026-11-02); every one was deleted. Rent Party's 2026-11-01 set (`linkedin-social-content/rent-party/assets/`) is
the reference for the system, not a layout to copy.

## When to use

- Making the images for a project's `linkedin-posts.md` series (`linkedin-social-content/_shared/POST-SPEC.md`).
- Reviewing a card, a carousel, or a whole set before it is queued.
- Any social image for a product: LinkedIn, WhatsApp or Facebook status, a document post.

**Not for:** store graphics (`aoneahsan-cccs-store-listing-assets`), OG images (`aoneahsan-cccs-postbuild-seo-html`),
post words (`linkedin-social-content/_shared/POST-SPEC.md` + `aoneahsan-cccs-story-personal-voice`).

## Before acting: the product brief

Read the product's **own repo**, never the old portfolio text alone:
- tokens (`tokens.css` / `@theme` / theme file): every colour the card uses comes from here;
- font files (`public/fonts`, `@fontsource`, the CSS `font-family`), outlined to paths;
- the mark as the product's header component draws it (a favicon can be an older mark), mascots, illustrations, icon set, button and chip styles;
- what the product does **today** (routes, features, recent commits) and the live URL (`PROJECT-LINKS-IDENTIFIERS-CONTACT.json`, main link);
- the screens worth capturing for each post.

Write the brief to the scratchpad, then design. Never ask the owner a visual question: decide, record why.

## The deliverables (per post)

| Post kind | File | Size |
|---|---|---|
| Single image (7 of 10) | `<slug>-<series>-<nn>.svg` master + `.png` | 1080 × 1350 (4:5), 24-bit, no alpha |
| Carousel (posts 3, 6, 9) | `<slug>-<series>-<nn>-p<k>.svg` pages + one `<slug>-<series>-<nn>.pdf` | 6–8 pages, 1080 × 1350 each |

Carousel: page 1 is the hook (big, few words), middle pages carry one point each with a real capture or the
product's own art, the last page is the CTA. Every page carries the mark and `k / n`.

## 🔴 The hard lines

- 🔴 **One idea per card, from its post.** The headline is a phrase from that post's approved body; no new claims,
  numbers, "best/#1/new/free".
- 🔴 **Ten different compositions per set** (screen-led, type-led, art-led, a before/after, a detail crop, a quote
  card with a real attribution…), and no layout shared with another product.
- 🔴 **An in-image CTA on every single card and every carousel's last page**: an action phrase drawn as the
  product's own button style plus the main link as text (e.g. "Play a round → rentparty.aoneahsan.com").
- 🔴 **Real screens only**: fresh captures of the live app with the automation browser (`ahsan-automation`
  profile), as a non-admin test account, no email or real name visible, never edited inside. Recapture when stale.
- 🔴 **Anti-AI checklist — any one fails the card:** generic gradient blobs or glow orbs not in the product's own
  UI · a stock icon grid or "What's inside" bullet rows · emoji as decoration · a system/unbranded font · invented UI
  or placeholder text · symmetric centred-everything with no focal point · text under 28 px at 1080 wide · contrast
  under 4.5:1 · decoration over the screen · another company's trademark · a footer band identical across cards.
- 🔴 **Safety surfaces** (mental health, pregnancy, medical, legal, money): calm, no jokes, no urgency art.
- 🔴 **No script files**: heredocs and one-line commands; tools live in a scratchpad venv.

## Capture lessons (from the 2026-11 sets)

- Drive the shared automation browser's tabs by id, never index; never close a tab you did not open.
- Turn on reduced motion in background tabs, or scroll-reveal sections capture blank; element clips use page
  coordinates (add the scroll offset); touch emulation switches some apps into their phone view.
- Check every claim on a card against the code: several products' marketing pages over-claimed. Crop out any
  over-claim, and file it in that product's `docs/REPORTED-ISSUES.md` through the main session.
- Never create, edit or delete production data to stage a screen; never capture as an admin (draw admin UI from code).
- A background tab in a shared headed browser stops answering screenshots and never runs scroll-triggered effects: open
  your own window (`Target.createTarget` with `newWindow: true`), drive it by target id over the CDP port, close only it.
- Phone-emulated full-page captures can hang: scroll and take viewport shots. Sticky headers cover full-page clips
  unless the page is at the top. Linked "static" font files may all point at one variable font: set weights explicitly.
- A CLI that runs only on another OS is typeset from its source strings in its own colours and labelled "typeset",
  never shown as a screenshot. A feature that is broken live is never posted: hold that post and file the issue.

## Export

Use `~/.claude/skills/aoneahsan-cccs-store-listing-assets/references/export-pipeline.md` (font outlining with
fontTools, balanced wrap, inlined captures, `sharp-cli@6.1.0`). Single image:
`npx -y sharp-cli@6.1.0 --density 72 -i card.svg -o card.png resize 1080 1350 -- flatten "<page bg>"`.
Carousel PDF: export each page to PNG, then one PDF: `rsvg-convert -f pdf -o deck.pdf p1.svg p2.svg …` when
present, else `"$S/venv/bin/python" -c` with `img2pdf` (pip in the venv) over the page PNGs (`engine=img2pdf.Engine.internal, nodate=True` for byte-identical output). Keep the PDF under 8 MB.

## Done means

1. Every PNG and every PDF page was opened full size and passed the checklist; a contact sheet of the set was viewed.
2. `assets/CARDS.md` lists per card: post number, words + source line, captures (URL, build hash, date), and the
   export command, which regenerates the PNGs pixel-identically (checked).
3. `file` reports 1080 × 1350 RGB for each PNG; each PDF opens with the right page count.

Details and the review rubric: `references/composition.md`.

## Related skills

`aoneahsan-cccs-store-listing-assets` (export, capture) · `-frontend-design` · `-design-process` ·
`-story-personal-voice` · `-copywriting`.

<!-- Law: ../../rules/portfolio-and-social.md · ../../rules-detail/portfolio-and-social.md -->
