# Third-party notices

This file records third-party material included in the repository or its published packages. It does not replace the upstream license terms. The current source pin and exact notice-file paths for compiled llama.cpp packages are recorded in each package's `upstream-licenses/INDEX.txt`.

`tools/repo_knowledge/` is not third-party software: it was authored by Sobuj Miah for his SKB project and is included as first-party Ternux code.

The Ternux files in a llama.cpp package are governed by both `TERNUX-LICENSE` and `TERNUX-LICENSE-SCOPE.txt`, including the company-use restriction in `LICENSE-COMMERCIAL-ADDENDUM.md`; these terms do not replace llama.cpp's or any dependency's license.

| Material | Source / version | License and handling |
| --- | --- | --- |
| Atma, Caveat, Space Grotesk, JetBrains Mono, Noto Sans Bengali fonts | See `assets/fonts/LICENSES.md` and `assets/fonts/ATMA-OFL.txt` | SIL Open Font License 1.1; retain the individual copyright and license text. |
| Astro site build dependencies and transitive npm packages | Versions and SPDX license expressions in `package-lock.json` | Build-time dependencies are not included in the static site as runtime packages. Preserve each upstream license when distributing dependency artifacts or modified build tools. |
| Optional `@emnapi/core` and `@emnapi/runtime` npm packages | `package-lock.json`, version 1.11.3 | The lock entries omit SPDX metadata; the npm package records identify both as MIT. They are optional build dependencies and are not shipped as site runtime code. [core](https://www.npmjs.com/package/%40emnapi/core) · [runtime](https://www.npmjs.com/package/%40emnapi/runtime). |
| llama.cpp and vendored dependencies in Vulkan/HTP release artifacts | Pinned llama.cpp commit recorded in the workflows | Preserve upstream `LICENSE`, `COPYING`, and `NOTICE` files copied under `upstream-licenses/`; Ternux's first-party package helpers are covered separately by `LICENSE`. |
| Qualcomm QNN SDK/runtime | External, separately licensed SDK/runtime; not covered by the Ternux license | Use only under Qualcomm's applicable SDK / AI Stack terms. Do not redistribute standalone runtime binaries unless those terms allow it. |
| `facebook/mms-tts-ben` model used by the Bengali short-film experiment | Model card linked from `experiments/bengali-short-film/README.md` | Marked CC-BY-NC-4.0 by the experiment documentation; do not treat it as commercially reusable under Ternux's license. |

## Inventory limits

`artifacts/` is ignored by Git and is not part of the Ternux repository release. Local SDK caches, QNN runtimes, model weights, and generated outputs found there do not receive a license grant from this repository. Before publishing a new model, data set, or binary, record its exact source, version, license, and redistribution permission here.

ADT is a separate repository with its own scope and notices; its AOSP-derived files and bundled ARM64 artifacts are not relicensed by this document.
