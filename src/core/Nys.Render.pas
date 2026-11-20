unit Nys.Render;

{ Markdown to a full HTML page. Uses the vendored GFM engine and stamps
  data-line on block tags so the view can scroll back to a source line.
  No VCL and no LCL. The HTML is a fragment plus one stylesheet. }

interface

function RenderMarkdownFragment(const Markdown: string): string;
function BuildPreviewPage(const Fragment, PageTitle, BaseHref, ThemeName: string): string;

implementation

uses
  System.SysUtils,
  MarkdownProcessor,
  MarkdownUtils,
  MarkdownAST,
  MarkdownTextUtils,
  MarkdownHtmlRenderer,
  MarkdownCommonMark;

type
  TNysHtmlRenderer = class(TMarkdownHtmlRenderer)
  protected
    function LineAttr(Node: TMarkdownNode): string;
    procedure RenderBlockQuote(Node: TMarkdownNode; Entering: Boolean); override;
    procedure RenderList(Node: TMarkdownNode; Entering: Boolean); override;
    procedure RenderListItem(Node: TMarkdownNode; Entering: Boolean); override;
    procedure RenderParagraph(Node: TMarkdownNode; Entering: Boolean); override;
    procedure RenderHeading(Node: TMarkdownNode; Entering: Boolean); override;
    procedure RenderThematicBreak(Node: TMarkdownNode); override;
    procedure RenderCodeBlock(Node: TMarkdownNode); override;
    procedure RenderHtmlBlock(Node: TMarkdownNode); override;
    procedure RenderTable(Node: TMarkdownNode; Entering: Boolean); override;
  end;

  TNysMarkdown = class(TMarkdownGFM)
  protected
    function RenderDocument(ADocument: TMarkdownNode): string; override;
  end;

function TNysHtmlRenderer.LineAttr(Node: TMarkdownNode): string;
begin
  if Node.StartLine > 0 then
    Result := ' data-line="' + IntToStr(Node.StartLine) + '"'
  else
    Result := '';
end;

procedure TNysHtmlRenderer.RenderBlockQuote(Node: TMarkdownNode; Entering: Boolean);
begin
  Cr;
  if Entering then
  begin
    Tag('<blockquote' + LineAttr(Node) + '>');
    Cr;
  end
  else
  begin
    Tag('</blockquote>');
    Cr;
  end;
end;

procedure TNysHtmlRenderer.RenderList(Node: TMarkdownNode; Entering: Boolean);
var
  TagName: string;
begin
  if Node.ListType = mltBullet then
    TagName := 'ul'
  else
    TagName := 'ol';
  Cr;
  if Entering then
  begin
    if (Node.ListType = mltOrdered) and (Node.ListStart <> 1) then
      Tag('<' + TagName + LineAttr(Node) + ' start="' + IntToStr(Node.ListStart) + '">')
    else
      Tag('<' + TagName + LineAttr(Node) + '>');
  end
  else
    Tag('</' + TagName + '>');
  Cr;
end;

procedure TNysHtmlRenderer.RenderListItem(Node: TMarkdownNode; Entering: Boolean);
begin
  if Entering then
    Tag('<li' + LineAttr(Node) + '>')
  else
  begin
    Tag('</li>');
    Cr;
  end;
end;

procedure TNysHtmlRenderer.RenderParagraph(Node: TMarkdownNode; Entering: Boolean);
var
  GrandParent: TMarkdownNode;
begin
  if Node.Parent <> nil then
  begin
    GrandParent := Node.Parent.Parent;
    if (GrandParent <> nil) and (GrandParent.Kind = nkList) and GrandParent.ListTight then
      Exit;
  end;
  if Entering then
  begin
    Cr;
    Tag('<p' + LineAttr(Node) + '>');
  end
  else
  begin
    Tag('</p>');
    Cr;
  end;
end;

procedure TNysHtmlRenderer.RenderHeading(Node: TMarkdownNode; Entering: Boolean);
var
  IdAttr: string;
begin
  if Entering then
  begin
    Cr;
    IdAttr := '';
    if Node.Id <> '' then
      IdAttr := ' id="' + EscapeHtml(Node.Id) + '"';
    Tag('<h' + IntToStr(Node.Level) + LineAttr(Node) + IdAttr + '>');
  end
  else
  begin
    Tag('</h' + IntToStr(Node.Level) + '>');
    Cr;
  end;
end;

procedure TNysHtmlRenderer.RenderThematicBreak(Node: TMarkdownNode);
begin
  Cr;
  Tag('<hr' + LineAttr(Node) + ' />');
  Cr;
end;

procedure TNysHtmlRenderer.RenderCodeBlock(Node: TMarkdownNode);
var
  Info: string;
  P: Integer;
begin
  if Assigned(CodeBlockEmitter) then
  begin
    inherited RenderCodeBlock(Node);
    Exit;
  end;
  Info := Node.Info;
  P := 1;
  while (P <= Length(Info)) and not CharInSet(Info[P], [' ', #9, #10, #13]) do
    Inc(P);
  Info := Copy(Info, 1, P - 1);
  Cr;
  if Info <> '' then
    Tag('<pre' + LineAttr(Node) + '><code class="language-' + EscapeHtml(Info) + '">')
  else
    Tag('<pre' + LineAttr(Node) + '><code>');
  Esc(Node.Literal);
  Tag('</code></pre>');
  Cr;
end;

procedure TNysHtmlRenderer.RenderHtmlBlock(Node: TMarkdownNode);
begin
  Cr;
  Tag('<div' + LineAttr(Node) + '>');
  inherited RenderHtmlBlock(Node);
  Tag('</div>');
  Cr;
end;

procedure TNysHtmlRenderer.RenderTable(Node: TMarkdownNode; Entering: Boolean);
begin
  Cr;
  if Entering then
    Tag('<table' + LineAttr(Node) + '>')
  else
    Tag('</table>');
  Cr;
end;

function TNysMarkdown.RenderDocument(ADocument: TMarkdownNode): string;
var
  Renderer: TNysHtmlRenderer;
begin
  Renderer := TNysHtmlRenderer.Create;
  try
    Renderer.AllowUnsafe := AllowUnsafe;
    Renderer.TagFilter := mexTagFilter in Config.Extensions;
    Renderer.Mermaid := False;
    Renderer.Video := False;
    Result := Renderer.Render(ADocument);
  finally
    Renderer.Free;
  end;
end;

function RenderMarkdownFragment(const Markdown: string): string;
var
  Proc: TNysMarkdown;
begin
  Proc := TNysMarkdown.Create;
  try
    Proc.AllowUnsafe := False;
    Result := Proc.Process(Markdown);
  finally
    Proc.Free;
  end;
end;

function HtmlEscape(const S: string): string;
begin
  Result := EscapeHtml(S);
end;

function PreviewCss: string;
begin
  Result :=
    ':root { color-scheme: light; --bg: #ffffff; --fg: #1b1b1b; --muted: #606060;' +
    '--accent: #0054d2; --rule: #d9d9d9; --code-bg: #eff1f4; }' +
    'html[data-theme="dark"] { color-scheme: dark; --bg: #1e1e1e; --fg: #e8e8e8;' +
    '--muted: #a6a6a6; --accent: #6cb6ff; --rule: #404040; --code-bg: #2d2f33; }' +
    'html, body { margin: 0; background: var(--bg); color: var(--fg); }' +
    'body { font-family: "Segoe UI", sans-serif; font-size: 17px; line-height: 1.65; }' +
    'article { max-width: 68ch; margin: 0 auto; padding: 48px 28px 80px; }' +
    'h1, h2, h3, h4, h5, h6 { line-height: 1.25; font-weight: 640; letter-spacing: -0.02em; margin: 1.4em 0 0.45em; }' +
    'h1 { font-size: 1.85em; } h2 { font-size: 1.4em; } h3 { font-size: 1.15em; }' +
    'p { margin: 0.7em 0; } a { color: var(--accent); }' +
    'blockquote { margin: 1em 0; padding: 0 0 0 1em; border-left: 3px solid var(--accent); color: var(--muted); }' +
    'code { font-family: "Cascadia Mono", Consolas, monospace; font-size: 0.9em;' +
    ' background: var(--code-bg); padding: 0.1em 0.35em; border-radius: 4px; }' +
    'pre { background: var(--code-bg); padding: 14px 16px; overflow: auto; border-radius: 6px; }' +
    'pre code { background: none; padding: 0; }' +
    'hr { border: 0; border-top: 1px solid var(--rule); margin: 1.6em 0; }' +
    'img { max-width: 100%; }' +
    'table { border-collapse: collapse; width: 100%; margin: 1em 0; }' +
    'th, td { border: 1px solid var(--rule); padding: 6px 10px; text-align: left; vertical-align: top; }' +
    'ul, ol { padding-left: 1.4em; } li { margin: 0.2em 0; }' +
    'input[type="checkbox"] { margin-right: 0.45em; }' +
    '::selection { background: color-mix(in srgb, var(--accent) 35%, transparent); }';
end;

function PreviewScript: string;
begin
  Result :=
    'function nysScrollTo(line){' +
    'var nodes=document.querySelectorAll("[data-line]");' +
    'var best=null,bestLine=-1,i,n;' +
    'for(i=0;i<nodes.length;i++){' +
    'n=parseInt(nodes[i].getAttribute("data-line"),10);' +
    'if(n<=line&&n>=bestLine){best=nodes[i];bestLine=n;}}' +
    'if(best)best.scrollIntoView({block:"start"});}' +
    'function nysTopLine(){' +
    'var nodes=document.querySelectorAll("[data-line]");' +
    'var i,r;' +
    'for(i=0;i<nodes.length;i++){' +
    'r=nodes[i].getBoundingClientRect();' +
    'if(r.bottom>8)return parseInt(nodes[i].getAttribute("data-line"),10);}' +
    'return 1;}' +
    // <base> points at the document's folder, so a bare #anchor link would
    // leave the page. Scroll to the heading instead.
    'document.addEventListener("click",function(e){' +
    'var a=e.target.closest?e.target.closest("a"):null;if(!a)return;' +
    'var h=a.getAttribute("href");if(!h||h.charAt(0)!=="#")return;' +
    'e.preventDefault();var t=null;' +
    'try{t=document.getElementById(decodeURIComponent(h.slice(1)));}catch(x){}' +
    'if(t)t.scrollIntoView({block:"start"});});';
end;

function BuildPreviewPage(const Fragment, PageTitle, BaseHref, ThemeName: string): string;
var
  Theme, Base, Title: string;
begin
  Theme := ThemeName;
  if (Theme <> 'dark') and (Theme <> 'light') then
    Theme := 'light';
  Title := HtmlEscape(PageTitle);
  Base := '';
  if BaseHref <> '' then
    Base := '<base href="' + HtmlEscape(BaseHref) + '">';
  Result :=
    '<!DOCTYPE html><html data-theme="' + Theme + '"><head><meta charset="utf-8">' +
    Base + '<title>' + Title + '</title><style>' + PreviewCss + '</style></head><body>' +
    '<article>' + Fragment + '</article><script>' + PreviewScript + '</script></body></html>';
end;

end.
