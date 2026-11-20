# Dependencies

`no-commit/` is a local build folder. It is listed in `.gitignore`. Nothing under it is part of the repository, and a fresh clone does not contain it.

The Delphi project compiles against that folder. `src/delphi/NowYouSee.dproj` searches `no-commit/SynEdit/Source` and `no-commit/SynEdit/Source/Highlighters`. Its post-build step then copies `no-commit/webview2/x64/WebView2Loader.dll` next to `NowYouSee.exe` (the `x86` one for a Win32 build). Without SynEdit the project does not compile. Without the DLL the build reports a failed copy, and the view does not start.

You need the folder when you compile or run the Delphi app. You do not need it to read `src/core` or the vendored Markdown units.

## Why it is not committed

We are allowed to download, compile, and ship both pieces. They are kept out of git on purpose.

SynEdit is Mozilla Public License 1.1 (GPL 2.0 or later is the other choice on those files; we use the MPL only). MPL stays on SynEdit’s own files. Committing that tree would put a second license, and a large unmodified upstream project, into this MIT repo. We do not edit SynEdit. The commit below is the source that was compiled. If a binary is shipped, that unmodified commit is the MPL source to point at.

`WebView2Loader.dll` is a Microsoft binary, BSD-3-Clause. Binaries do not belong in this repo. The notice that has to travel with a shipped copy is already in `CREDITS.md`.

Deleting `no-commit/` does not change git. The next fetch recreates it.

The legal write-up, including what we refuse to take, is `license-info/LICENSES.md`.

## What is in it

| Path | What it is | Pinned to |
| --- | --- | --- |
| `no-commit/SynEdit/` | [TurboPack SynEdit](https://github.com/TurboPack/SynEdit), the edit control. Full git clone, then detached at one commit. | `4f9aaa3ec804b6ad551897c9de0ce730019f7682` |
| `no-commit/webview2/x64/WebView2Loader.dll` | 64-bit loader from the [Microsoft.Web.WebView2](https://www.nuget.org/packages/Microsoft.Web.WebView2) NuGet package. This is the one the Win64 build copies beside the exe. | package `1.0.3240.44` |
| `no-commit/webview2/x86/WebView2Loader.dll` | 32-bit loader from the same package. Used only if you build Win32. | same package |
| `no-commit/webview2/LICENSE.txt` | The SDK license file from that package, when the package contains one. | same package |

The loader is not the Edge runtime. Windows 11 already has the Evergreen WebView2 Runtime. The DLL is the small loader Delphi calls by name from `Winapi.EdgeUtils`. It has to sit beside the exe. The fetch keeps a copy here so the build can place it there without committing the binary.

## What is not in it

`src/markdown/` is Ethea MarkdownProcessor, Apache 2.0. That source is committed, with `src/markdown/LICENSE` and `src/markdown/third-party/`. It is a dependency, and it is not part of `no-commit/`.

`TEdgeBrowser` comes with RAD Studio. It is not copied anywhere in this tree.

## How to get it

From the repo root:

```
powershell -ExecutionPolicy Bypass -File tools\fetch-nocommit.ps1
```

That clones SynEdit if `no-commit/SynEdit/Source/SynEdit.pas` is missing, checks out the pinned commit if HEAD is not already that commit, and downloads the WebView2 package if `no-commit/webview2/x64/WebView2Loader.dll` is missing. Running it again leaves a matching tree alone.

`tools\build-delphi.ps1` runs the fetch first, then compiles. The project's post-build step puts the x64 DLL in the output folder, `src\delphi\Win64\Release\` by default.

Needs git, and network the first time the DLL is missing. The NuGet package is unpacked from `%TEMP%`.

## When you need to refresh

- A new clone, or you deleted `no-commit/`.
- The pins in `tools/fetch-nocommit.ps1` change. Update this file in the same change.
- You are about to build Win32 and only the x64 DLL is present. Run the fetch again; it writes both DLLs when the x64 one is absent. If x64 is already there and x86 is not, delete `no-commit/webview2/` and run the fetch.

Do not patch files under `no-commit/`. A local edit would be an unpublished fork of MPL or Microsoft code, and the next checkout can wipe it. Change the pin, or change our code in `src/`.
