# Credits

NowYouSee.md is MIT, copyright 2026 b-har. See `LICENSE`.

This file is the third-party notice for the program. Give it, together with `LICENSE` and
`src/markdown/LICENSE` (the Apache License 2.0 text), to anyone you give `NowYouSee.exe` to.

## MarkdownProcessor

The view is rendered from Markdown by MarkdownProcessor, copyright Ethea S.r.l., Apache License 2.0. A copy of that license is in `src/markdown/LICENSE`.

MarkdownProcessor includes, and these notices stay with it:

- delphi-markdown, copyright 2011+, Health Intersections Pty Ltd. BSD-3-Clause. The full notice is below.
- fpc-markdown, copyright Miguel A. Risco-Castillo. Apache License 2.0. It is a fork of delphi-markdown, so the BSD-3-Clause notice above still applies to those portions.
- The Daring Fireball dialect descends from txtmark, copyright René Jeschke, Apache License 2.0.
- The CommonMark / GFM engine follows the structure of commonmark.js, copyright 2014 John MacFarlane, BSD-2-Clause. The full notice is below, and in `src/markdown/third-party/LICENSE-commonmark.js.txt`.
- The GFM extensions follow cmark-gfm, copyright John MacFarlane and GitHub, BSD-2-Clause, the same terms as commonmark.js.
- Math syntax, its test corpus, and the alert rules come from Markdown4D by GDK Software, MIT.

delphi-markdown:

> Copyright (c) 2011+, Health Intersections Pty Ltd (http://www.healthintersections.com.au)
> All rights reserved.
>
> Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
>
> * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
> * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
> * Neither the name of HL7 nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

commonmark.js:

> Copyright (c) 2014, John MacFarlane
> All rights reserved.
>
> Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
>
> * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
> * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## SynEdit

The editor control is TurboPack SynEdit. Its files are Mozilla Public License 1.1, or GPL 2.0 or later, at the recipient's choice. NowYouSee.md uses them under the MPL only. Original work copyright 1998 Martin Waldenburg, with later contributors listed in that project. SynEdit is not modified and is not part of this git tree.

The source of the SynEdit code compiled into the program is commit `4f9aaa3ec804b6ad551897c9de0ce730019f7682` of https://github.com/TurboPack/SynEdit. The MPL 1.1 text is the `LICENSE` file there, and at https://www.mozilla.org/MPL/1.1/.

## WebView2

WebView2Loader.dll is copyright Microsoft Corporation, BSD-3-Clause:

> Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
>
> * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
> * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
> * The name of Microsoft Corporation, or the names of its contributors, may not be used to endorse or promote products derived from this software without specific prior written permission.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The Edge WebView2 Runtime is a separate Microsoft component on the machine. It is not part of this program.

## Delphi

`TEdgeBrowser` and the rest of the VCL are part of Embarcadero RAD Studio. They are not open source and are not included in this repository.
