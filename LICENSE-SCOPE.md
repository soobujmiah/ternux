# Ternux license scope

## Current project material

Original Ternux code, scripts, configuration, documentation, and first-party visual material authored by Sobuj Miah are offered under the [PolyForm Noncommercial License 1.0.0](LICENSE), with the additional [commercial-use condition](LICENSE-COMMERCIAL-ADDENDUM.md). Personal, hobby, research, education, and other noncommercial use and modification are allowed under those combined terms. For-profit company or business-capacity use requires a separate written commercial license, even if that use does not directly earn money. Royalty and other commercial terms are agreed in that separate license; this repository does not set a royalty rate. The combined terms are project-specific and are not the unmodified PolyForm license.

This includes `tools/repo_knowledge/`, originally developed by Sobuj Miah for his SKB project and vendored into Ternux. `.repo/` is machine-generated repository metadata and is outside the first-party code/documentation grant; any embedded source text remains subject to its originating rights.

Contributors retain copyright in their own contributions. New contributions are accepted for distribution under the same PolyForm Noncommercial terms only when the contributor has authority to grant those rights. Third-party and contributor-owned work identified below is excluded from the first-party grant.

## Excluded material and exceptions

- Fonts in `assets/fonts/` remain under their individual SIL Open Font License 1.1 terms. Their copyright holders and notices are listed in `assets/fonts/LICENSES.md` and `assets/fonts/ATMA-OFL.txt`.
- llama.cpp build inputs and vendored dependencies remain under their upstream licenses. Release workflows copy their license and notice files into each package under `upstream-licenses/`.
- Model, dataset, runtime, and binary terms are specific to each item. The Bengali short-film experiment uses an MMS TTS model marked CC-BY-NC-4.0; Qualcomm QNN runtimes are separately licensed and are not granted by Ternux's license. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and the experiment documentation.
- The `ternux` name, logo, and marks remain subject to [TRADEMARKS.md](TRADEMARKS.md). The software license does not grant trademark rights.
- Releases and commits published before the license transition were offered under Apache-2.0. Their existing grants continue; `LICENSE-APACHE-2.0` preserves the historical text. This transition does not revoke those grants.

## Required notice

When redistributing first-party material covered by these combined terms, include both `LICENSE` and `LICENSE-COMMERCIAL-ADDENDUM.md` (or their URLs) and preserve this required notice:

> Required Notice: Copyright (c) 2026 Sobuj Miah (https://github.com/soobujmiah/ternux)

For third-party redistribution, include the applicable upstream notices and license texts as well.
