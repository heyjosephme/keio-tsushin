---
name: distill-knowledge
description: Distill a page range of a Keio correspondence-program PDF (履修案内, 学習のしおり, レポート課題集) into reviewed markdown knowledge files under knowledge/. Run by the user, who chooses the pages and confirms every file.
argument-hint: <pdf-path> <pages, e.g. 45-52> [topic or what to capture]
disable-model-invocation: true
---

# Distill knowledge from a Keio PDF

Turn the pages the user names into small markdown files that a search agent can later
grep and quote from. The user decides what is worth keeping; you draft, they confirm.
Nothing is knowledge until its front matter says `status: confirmed`.

Arguments: `$ARGUMENTS` — a PDF path, a page range, and optionally a topic or a note
about what to capture. If the path or the page range is missing, ask for it. Do not
pick pages yourself and do not read pages outside the range to "be thorough".

## Steps

1. **Read the pages.** Use the Read tool with `pages` (at most 20 pages per call; split
   longer ranges). Check `knowledge/INDEX.md` and grep `knowledge/` for the same pages or
   topic, so you extend an existing file instead of creating a duplicate.

2. **Propose an outline and stop.** List the files you would write: path, title, pages,
   and one line on what each will contain. Also list what you plan to leave out (greetings,
   repeated boilerplate, form layouts) and anything you could not read reliably. Wait for
   the user to approve or change the outline before writing anything.

3. **Write drafts** following `template.md` in this directory, with `status: draft`.
   One topic per file, usually 30–150 lines. Path: `knowledge/<document>/<nn>-<slug>.md`,
   where `<document>` is the PDF's key (`syllabus`, `handbook`, `reports_humanities`, …;
   the keys are listed in CLAUDE.md under Document storage), `<nn>` keeps the files in
   PDF order, and `<slug>` is short lowercase English.

4. **Ask for review.** Tell the user which files to read and call out every `要確認` note
   and every judgment call you made (something merged, shortened or left out). Apply
   their corrections. Do not mark anything confirmed on your own initiative.

5. **Confirm.** When the user approves a file, set `status: confirmed` and `confirmed_on`
   to today's date, then add or update its line in `knowledge/INDEX.md`
   (`- [title](path) — pages, one-line summary`). Files they have not approved stay `draft`.

## Rules for the content

- **Language:** write in Japanese, as in the source. Keep official terms exactly as
  printed (科目名, 試験群, 手続き名); do not translate or normalize them.
- **Only what is on the pages.** No background knowledge, no inferences, no advice. If the
  text refers to another section you were not given, say so rather than filling it in.
- **Numbers, dates, deadlines, fees, credit counts and conditions are copied exactly**,
  including qualifiers such as 以上, 未満, 原則として and ただし. Shorten prose freely; never
  shorten a condition.
- **Every heading and every standalone fact carries its page**, as `[p.45]` or
  `[p.45-46]`. Answers will link to the PDF by these numbers, so use the PDF's page index
  (the number the Read tool uses), and note the printed page number in the front matter
  when it differs.
- **Tables stay tables** (markdown). Do not flatten a table into sentences.
- **Unclear means flagged, not guessed.** For a blurry scan, an ambiguous table cell or
  apparently contradictory text, add a line `> 要確認: <what is unclear> [p.N]`.
- **Exam-season dates:** the app's source of truth is `config/seasons.yml`. Record the
  dates the PDF prints, and if they differ from that file, tell the user; do not edit
  `seasons.yml` as part of this skill.
- **Search terms:** fill `keywords` with the words a student would actually type,
  including synonyms and English equivalents (試験申込, 受験申込, exam application).

## Do not

- Commit or push anything under `knowledge/` or any PDF. The repository is public and the
  material is Keio's; both paths are in `.gitignore`.
- Rewrite or delete a `confirmed` file without the user asking. To change one, show the
  diff you intend, and set it back to `draft` until they confirm again.
