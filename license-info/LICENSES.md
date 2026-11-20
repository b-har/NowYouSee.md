# Licenses

The rules this repository follows for third-party code. The program itself stays MIT (see `LICENSE` at the root, copyright 2026 b-har). Third-party code keeps its own license. This file is the rule we follow. `CREDITS.md` is the notice that travels with the program. `DEPENDENCIES.md` is how to fetch what is not committed.

Nothing in here is legal advice. It is the list of what we use, what we copy, and what we refuse to commit.

## What is committed

Our units under `src/core` and `src/delphi`, the stylesheet inside the renderer, and this documentation are MIT.

`src/markdown` is an unmodified copy of the `source` folder of Ethea MarkdownProcessor, commit `46498e7d778c8c26583933be873c28a7aa79af52` (version 2.1.3, 11 Nov 2026). Upstream has no `NOTICE` file. The library license is Apache 2.0, copyright Ethea S.r.l. The Apache text is `src/markdown/LICENSE`. Those files stay Apache. We do not relicense them, we do not strip the copyright headers, and we keep the upstream credits below.

That library already carries these upstream notices. We did not add those projects as separate dependencies:

| Work | Who | License | Why it is in the tree |
| --- | --- | --- | --- |
| delphi-markdown | Grahame Grieve, Health Intersections Pty Ltd, 2011+ | BSD-3-Clause | The legacy dialect units. The non-endorsement line names HL7. Leave it as written. |
| fpc-markdown | Miguel A. Risco-Castillo | Apache 2.0 | Fork of Grieve. The BSD-3-Clause terms still cover his portions. |
| txtmark | René Jeschke | Apache 2.0 | The Daring Fireball dialect is a Pascal translation of it. |
| commonmark.js | John MacFarlane, 2014 | BSD-2-Clause | The new engine follows its structure. The text is `src/markdown/third-party/LICENSE-commonmark.js.txt`. We do not copy the JavaScript. |
| cmark-gfm | John MacFarlane and GitHub | BSD-2-Clause | The GFM extensions follow it. We do not copy the C. |
| Markdown4D | GDK Software | MIT | Math, alert, and test rules used by Ethea. We do not take the Markdown4D viewer or editor. |

The CommonMark specification text is CC-BY-SA 4.0. It is not in this repository. Do not vendor `spec.txt`.

## What is copied locally and never committed

`no-commit/` is gitignored. `tools/fetch-nocommit.ps1` fills it. Deleting the folder does not change the repo.

**TurboPack SynEdit**, commit `4f9aaa3ec804b6ad551897c9de0ce730019f7682`.

Mozilla Public License 1.1, or GPL 2.0 or later, file by file, at the recipient's choice. Copyrights start with Martin Waldenburg, 1998, plus the contributors in that project. We use the MPL side. We do not delete the MPL terms, and we do not choose the GPL. MPL covers SynEdit's own files only. It does not relicense our units or the MIT repo. We do not modify SynEdit. If a binary is shipped, the MPL source of the SynEdit version that was compiled has to stay available. The unmodified TurboPack commit above is that source.

**WebView2Loader.dll**, from the Microsoft Edge WebView2 SDK NuGet package `Microsoft.Web.WebView2` version `1.0.3240.44`, copied to `no-commit/webview2/x64` and `x86`. The project's post-build step copies the DLL for the platform next to `NowYouSee.exe`.

BSD-3-Clause, copyright Microsoft Corporation. The notice is in `CREDITS.md`. Do not use the name Microsoft to endorse the app. The DLL is not committed.

The Evergreen WebView2 Runtime is a separate Microsoft component, already on Windows 11, running as its own process (`msedgewebview2.exe`). Edge's own credits include GPL and LGPL pieces inside that process. Those are not linked into `NowYouSee.exe`. The only Microsoft file we ship beside the exe is the BSD-3-Clause loader.

## What we do not use

- `mas3/SynEditHighlighterMarkdown`. It is MPL 1.1 or GPL 2.0-or-later, and it uses VCL units. The highlighter in `src/delphi/Nys.Highlighter.pas` is ours, under the MIT license. It is written against the `TSynCustomHighlighter` interface and copies no SynEdit code.
- The GPL alternative on SynEdit.
- VCL source. `TEdgeBrowser` (`Vcl.Edge`) ships with RAD Studio. It is Embarcadero's, not open source, and it is not copied into the repo. Compiling needs a Delphi license. The exe is distributable under that product's terms.
- HtmlViewer, WebView4Delphi, and the Lazarus LCL. Those are for a later sister project, not this build.

## Later, for a Lazarus sister

Not compiled now.

- Lazarus LCL and the FPC RTL: LGPL 2.1 with the static-linking exception used by Lazarus and Free Pascal. A static link is allowed. Changes to LCL or RTL units would be published.
- Lazarus SynEdit: the same MPL 1.1 / GPL 2.0-or-later split. Stay on MPL. Do not commit it; use the same `no-commit` rule, or the copy that ships with Lazarus.
- WebView4Delphi, Salvador Díaz Fau: MIT. Same WebView2 loader terms as above.

`src/core` is written so that sister can share it: no VCL, no LCL, no inline variables. The form is Delphi-only and will be written again for Lazarus.
