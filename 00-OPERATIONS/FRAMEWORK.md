# Tabung Haji RCI — Parliamentary Impact Assessment

## Workstream Overview

**Designation:** TH-RCI-PARL
**Classification:** TLP:AMBER
**Created:** 2026-08-04
**Authority:** Head of Intelligence, Aras Integrasi

## Mission

Monitor and assess how the 222 current sitting Members of the 16th Parliament of Malaysia engage with the Tabung Haji Royal Commission of Inquiry (RCI) report in the lead-up to, during, and following the special Dewan Rakyat sitting on 11 August 2026.

## Background

The Tabung Haji RCI report was declassified on 29 July 2026. The 211-page document examines governance, financial management, investment decisions, and political influence affecting Tabung Haji during 2014–2020. The government states the report contains 25 recommendations, ~75% reportedly implemented. A special Dewan Rakyat sitting has been announced for 11 August 2026 to debate the report.

## Scope

- **Focus:** 222 current sitting MPs only — their statements, positions, questions, and party dynamics related to the RCI
- **NOT in scope:** The RCI content itself (already declassified), Tabung Haji internal operations, non-parliamentary commentary
- **Parliamentary session:** 16th Parliament (GE15, elected November 2022)

## Intelligence Lifecycle

```
Collection (Cronjob, every 6h)
  → Raw scrapes (04-DATA-AND-SOURCES/)
  → MP position mapping (02-CONSTITUENCY-INTELLIGENCE/mp-dossiers/)
  → Party/coalition position tracking (02-CONSTITUENCY-INTELLIGENCE/party-positions/)
  → Narrative alert assessment (01-DAILY-INTELLIGENCE/narrative-alerts/)
  → Parliamentary brief generation (01-DAILY-INTELLIGENCE/parliamentary-briefs/)
  → PIR resolution tracking (07-AUDIT/)
```

## PIR Architecture

10 Priority Intelligence Requirements (PIR-TH-01 through PIR-TH-10) adapted from the RCI PIR document, reframed for parliamentary monitoring. Each PIR tracks how MPs engage with the corresponding RCI intelligence gap.

See: `07-AUDIT/pir-th-rci-parliamentary-top10-20260804.md`

## Cronjob Architecture

| CJ | Name | Function | Schedule | Deliver |
|----|------|----------|----------|---------|
| CJ-TH-01 | Parliamentary Impact Watch | MP position collection, PIR mapping, narrative alert, daily brief | Every 6h | Telegram |

## Operational Phases

| Phase | Window | Focus |
|-------|--------|-------|
| Pre-Debate | Aug 4–10 | MP statements, party positioning, anticipated lines of inquiry |
| Debate Day | Aug 11 | Real-time speech tracking, questions, voting positions |
| Post-Debate | Aug 12+ | Reactions, follow-up, implementation monitoring, residual narratives |
