unit Nys.Highlighter;

{ Markdown highlighter for the Delphi SynEdit (TurboPack, in no-commit).

  The point is to tell Markdown syntax from prose at a glance. Everything
  that is syntax gets MarkerAttr: hashes, quote and list marks, fences,
  rules, table pipes, emphasis and link punctuation, HTML tags. A link
  target gets UrlAttr. Code gets CodeAttr. Prose stays TextAttr, and the
  words of a heading get HeadingAttr.

  Punctuation that is only punctuation is left as prose: an exclamation
  mark, ordinary parentheses, a lone asterisk, the underscores in
  snake_case, anything after a backslash.

  Written here, MIT, same as the rest of the app. }

interface

uses
  System.Classes,
  Vcl.Graphics,
  SynEditHighlighter;

type
  TNysMarkdownSyn = class(TSynCustomHighlighter)
  private
    FTextAttr: TSynHighlighterAttributes;
    FMarkerAttr: TSynHighlighterAttributes;
    FCodeAttr: TSynHighlighterAttributes;
    FHeadingAttr: TSynHighlighterAttributes;
    FUrlAttr: TSynHighlighterAttributes;
    FKind: Integer;
    FRange: Integer;
    { state inside one line }
    FHeading: Boolean;
    FTable: Boolean;
    FSpanEnd: Integer;
    FSpanKind: Integer;
    FSpanClose: Integer;
    function IsBlank(Index: Integer): Boolean;
    function IsWordChar(Index: Integer): Boolean;
    function Indent: Integer;
    function LineOpensFence(out FenceKind: Integer): Boolean;
    function LineClosesFence: Boolean;
    function LineIsRule: Boolean;
    function LineIsTableRule: Boolean;
    function TakeLineMarker: Boolean;
    procedure TakeInline;
  protected
    function GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes; override;
  public
    constructor Create(AOwner: TComponent); override;
    class function GetLanguageName: string; override;
    class function GetFriendlyLanguageName: string; override;
    function GetEol: Boolean; override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: NativeInt; override;
    procedure Next; override;
    procedure SetRange(Value: Pointer); override;
    procedure ResetRange; override;
    function GetRange: Pointer; override;
    property TextAttr: TSynHighlighterAttributes read FTextAttr;
    property MarkerAttr: TSynHighlighterAttributes read FMarkerAttr;
    property CodeAttr: TSynHighlighterAttributes read FCodeAttr;
    property HeadingAttr: TSynHighlighterAttributes read FHeadingAttr;
    property UrlAttr: TSynHighlighterAttributes read FUrlAttr;
  end;

implementation

uses
  System.SysUtils,
  System.Character;

const
  tkText = 0;
  tkMarker = 1;
  tkCode = 2;
  tkHeading = 3;
  tkUrl = 4;
  rgNone = 0;
  rgBacktick = 1;
  rgTilde = 2;

constructor TNysMarkdownSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCaseSensitive := True;
  FSpanEnd := -1;
  FTextAttr := TSynHighlighterAttributes.Create('Text', 'Text');
  AddAttribute(FTextAttr);
  FMarkerAttr := TSynHighlighterAttributes.Create('Marker', 'Marker');
  FMarkerAttr.Style := [fsBold];
  AddAttribute(FMarkerAttr);
  FCodeAttr := TSynHighlighterAttributes.Create('Code', 'Code');
  AddAttribute(FCodeAttr);
  FHeadingAttr := TSynHighlighterAttributes.Create('Heading', 'Heading');
  FHeadingAttr.Style := [fsBold];
  AddAttribute(FHeadingAttr);
  FUrlAttr := TSynHighlighterAttributes.Create('Url', 'Link target');
  AddAttribute(FUrlAttr);
end;

class function TNysMarkdownSyn.GetLanguageName: string;
begin
  Result := 'NowYouSee Markdown';
end;

class function TNysMarkdownSyn.GetFriendlyLanguageName: string;
begin
  Result := 'Markdown';
end;

function TNysMarkdownSyn.GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := FMarkerAttr;
    SYN_ATTR_STRING: Result := FCodeAttr;
    SYN_ATTR_SYMBOL: Result := FMarkerAttr;
    SYN_ATTR_KEYWORD: Result := FMarkerAttr;
  else
    Result := FTextAttr;
  end;
end;

{ SynEdit reads a token and then asks GetEol, so the end of the line is its
  own empty token: Next steps Run one past the line, and only then is this
  true. Returning true at fLineLen would drop the last token of every line. }
function TNysMarkdownSyn.GetEol: Boolean;
begin
  Result := Run > fLineLen;
end;

function TNysMarkdownSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case FKind of
    tkMarker: Result := FMarkerAttr;
    tkCode: Result := FCodeAttr;
    tkHeading: Result := FHeadingAttr;
    tkUrl: Result := FUrlAttr;
  else
    Result := FTextAttr;
  end;
end;

function TNysMarkdownSyn.GetTokenKind: NativeInt;
begin
  Result := FKind;
end;

function TNysMarkdownSyn.GetRange: Pointer;
begin
  Result := Pointer(NativeInt(FRange));
end;

procedure TNysMarkdownSyn.SetRange(Value: Pointer);
begin
  FRange := Integer(NativeInt(Value));
end;

procedure TNysMarkdownSyn.ResetRange;
begin
  FRange := rgNone;
end;

function TNysMarkdownSyn.IsBlank(Index: Integer): Boolean;
begin
  Result := (Index < 0) or (Index >= fLineLen) or (fLine[Index] = ' ') or (fLine[Index] = #9);
end;

function TNysMarkdownSyn.IsWordChar(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < fLineLen) and fLine[Index].IsLetterOrDigit;
end;

function TNysMarkdownSyn.Indent: Integer;
begin
  Result := 0;
  while (Result < fLineLen) and ((fLine[Result] = ' ') or (fLine[Result] = #9)) do
    Inc(Result);
end;

{ Fences, list marks and quotes are accepted at any indent, so the ones
  nested inside a list are colored too. }

function TNysMarkdownSyn.LineOpensFence(out FenceKind: Integer): Boolean;
var
  I, Count: Integer;
  Ch: WideChar;
begin
  Result := False;
  FenceKind := rgNone;
  I := Indent;
  if I >= fLineLen then
    Exit;
  Ch := fLine[I];
  if (Ch <> '`') and (Ch <> '~') then
    Exit;
  Count := 0;
  while (I < fLineLen) and (fLine[I] = Ch) do
  begin
    Inc(Count);
    Inc(I);
  end;
  if Count < 3 then
    Exit;
  { A backtick fence cannot have a backtick in its info string. That is
    inline code that happens to start the line. }
  if Ch = '`' then
    while I < fLineLen do
    begin
      if fLine[I] = '`' then
        Exit;
      Inc(I);
    end;
  Result := True;
  if Ch = '~' then
    FenceKind := rgTilde
  else
    FenceKind := rgBacktick;
end;

function TNysMarkdownSyn.LineClosesFence: Boolean;
var
  I, Count: Integer;
  Ch: WideChar;
begin
  Result := False;
  if FRange = rgTilde then
    Ch := '~'
  else
    Ch := '`';
  I := Indent;
  Count := 0;
  while (I < fLineLen) and (fLine[I] = Ch) do
  begin
    Inc(Count);
    Inc(I);
  end;
  if Count < 3 then
    Exit;
  while (I < fLineLen) and IsBlank(I) do
    Inc(I);
  Result := I >= fLineLen;
end;

{ A thematic break (three or more of - * _), or a setext underline (=). }
function TNysMarkdownSyn.LineIsRule: Boolean;
var
  I, Count: Integer;
  Ch: WideChar;
begin
  Result := False;
  I := Indent;
  if (I > 3) or (I >= fLineLen) then
    Exit;
  Ch := fLine[I];
  if Ch = '=' then
  begin
    while (I < fLineLen) and (fLine[I] = '=') do
      Inc(I);
    while (I < fLineLen) and IsBlank(I) do
      Inc(I);
    Result := I >= fLineLen;
    Exit;
  end;
  if (Ch <> '-') and (Ch <> '*') and (Ch <> '_') then
    Exit;
  Count := 0;
  while I < fLineLen do
  begin
    if fLine[I] = Ch then
      Inc(Count)
    else if not IsBlank(I) then
      Exit;
    Inc(I);
  end;
  Result := Count >= 3;
end;

{ The | --- | :-: | row under a table header. }
function TNysMarkdownSyn.LineIsTableRule: Boolean;
var
  I: Integer;
  Dash, Pipe: Boolean;
begin
  Result := False;
  Dash := False;
  Pipe := False;
  for I := Indent to fLineLen - 1 do
    case fLine[I] of
      '-': Dash := True;
      '|': Pipe := True;
      ':', ' ', #9: ;
    else
      Exit;
    end;
  Result := Dash and Pipe;
end;

{ Called at the start of a line outside a fence. True when the line opens
  with a block mark; Run is then just past it. }
function TNysMarkdownSyn.TakeLineMarker: Boolean;
var
  I, Start, Hashes, Digits, FenceKind: Integer;
  Ch: WideChar;
begin
  Result := False;
  Start := Indent;
  if Start >= fLineLen then
    Exit;

  if LineOpensFence(FenceKind) then
  begin
    Run := fLineLen;
    FKind := tkMarker;
    FRange := FenceKind;
    Result := True;
    Exit;
  end;

  if LineIsRule or LineIsTableRule then
  begin
    Run := fLineLen;
    FKind := tkMarker;
    Result := True;
    Exit;
  end;

  Ch := fLine[Start];

  if (Ch = '#') and (Start <= 3) then
  begin
    Hashes := 0;
    I := Start;
    while (I < fLineLen) and (fLine[I] = '#') do
    begin
      Inc(Hashes);
      Inc(I);
    end;
    if (Hashes <= 6) and IsBlank(I) then
    begin
      if I < fLineLen then
        Inc(I);
      Run := I;
      FKind := tkMarker;
      FHeading := True;
      Result := True;
    end;
    Exit;
  end;

  if Ch = '>' then
  begin
    I := Start;
    while (I < fLineLen) and ((fLine[I] = '>') or (fLine[I] = ' ')) do
      Inc(I);
    Run := I;
    FKind := tkMarker;
    Result := True;
    Exit;
  end;

  if Ch = '|' then
  begin
    FTable := True;
    Exit;
  end;

  I := -1;
  if ((Ch = '-') or (Ch = '*') or (Ch = '+')) and (Start + 1 < fLineLen) and IsBlank(Start + 1) then
    I := Start + 2
  else
  begin
    Digits := 0;
    while (Start + Digits < fLineLen) and (fLine[Start + Digits] >= '0') and
      (fLine[Start + Digits] <= '9') do
      Inc(Digits);
    if (Digits > 0) and (Digits <= 9) and (Start + Digits + 1 < fLineLen) and
      ((fLine[Start + Digits] = '.') or (fLine[Start + Digits] = ')')) and
      IsBlank(Start + Digits + 1) then
      I := Start + Digits + 2;
  end;
  if I < 0 then
    Exit;
  { a task box belongs to the list mark }
  if (I + 2 < fLineLen) and (fLine[I] = '[') and (fLine[I + 2] = ']') and
    ((fLine[I + 1] = ' ') or (fLine[I + 1] = 'x') or (fLine[I + 1] = 'X')) and IsBlank(I + 3) then
  begin
    Inc(I, 3);
    if I < fLineLen then
      Inc(I);
  end;
  Run := I;
  FKind := tkMarker;
  Result := True;
end;

{ One inline token starting at Run. }
procedure TNysMarkdownSyn.TakeInline;
const
  Special = ['\', '`', '!', '[', ']', '*', '_', '~', '<', '|'];
var
  Ch: WideChar;
  I, N, M, Depth: Integer;
  Prose: Integer;
begin
  if FHeading then
    Prose := tkHeading
  else
    Prose := tkText;
  FKind := Prose;
  Ch := fLine[Run];

  if not CharInSet(Ch, Special) then
  begin
    while (Run < fLineLen) and not CharInSet(fLine[Run], Special) do
      Inc(Run);
    Exit;
  end;

  case Ch of
    '\':
      begin
        Inc(Run);
        if Run < fLineLen then
          Inc(Run);
      end;

    '`':
      begin
        N := 0;
        while (Run + N < fLineLen) and (fLine[Run + N] = '`') do
          Inc(N);
        { the code span ends at the next run of exactly N backticks }
        I := Run + N;
        while I < fLineLen do
        begin
          if fLine[I] <> '`' then
          begin
            Inc(I);
            Continue;
          end;
          M := 0;
          while (I + M < fLineLen) and (fLine[I + M] = '`') do
            Inc(M);
          if M = N then
            Break;
          Inc(I, M);
        end;
        Inc(Run, N);
        if I < fLineLen then
        begin
          FKind := tkMarker;
          FSpanEnd := I;
          FSpanKind := tkCode;
          FSpanClose := N;
        end;
      end;

    '!':
      begin
        Inc(Run);
        if (Run < fLineLen) and (fLine[Run] = '[') then
        begin
          Inc(Run);
          FKind := tkMarker;
        end;
      end;

    '[':
      begin
        Inc(Run);
        FKind := tkMarker;
      end;

    ']':
      begin
        Inc(Run);
        FKind := tkMarker;
        if (Run < fLineLen) and (fLine[Run] = '(') then
        begin
          { ](target) : find the parenthesis that closes the target }
          Depth := 1;
          I := Run + 1;
          while I < fLineLen do
          begin
            if fLine[I] = '(' then
              Inc(Depth)
            else if fLine[I] = ')' then
            begin
              Dec(Depth);
              if Depth = 0 then
                Break;
            end;
            Inc(I);
          end;
          if I < fLineLen then
          begin
            Inc(Run);
            FSpanEnd := I;
            FSpanKind := tkUrl;
            FSpanClose := 1;
          end;
        end;
      end;

    '*', '_':
      begin
        I := Run;
        while (Run < fLineLen) and (fLine[Run] = Ch) do
          Inc(Run);
        if IsBlank(I - 1) and IsBlank(Run) then
          Exit;
        if (Ch = '_') and IsWordChar(I - 1) and IsWordChar(Run) then
          Exit;
        FKind := tkMarker;
      end;

    '~':
      begin
        I := Run;
        while (Run < fLineLen) and (fLine[Run] = '~') do
          Inc(Run);
        if Run - I >= 2 then
          FKind := tkMarker;
      end;

    '<':
      begin
        { an HTML tag, a comment, or an autolink }
        I := Run + 1;
        if (I < fLineLen) and (fLine[I].IsLetter or (fLine[I] = '/') or (fLine[I] = '!')) then
        begin
          while (I < fLineLen) and (fLine[I] <> '>') and (fLine[I] <> '<') do
            Inc(I);
          if (I < fLineLen) and (fLine[I] = '>') then
          begin
            Run := I + 1;
            FKind := tkMarker;
            Exit;
          end;
        end;
        Inc(Run);
      end;

    '|':
      begin
        Inc(Run);
        if FTable then
          FKind := tkMarker;
      end;
  end;
end;

procedure TNysMarkdownSyn.Next;
begin
  fTokenPos := Run;
  if Run = 0 then
  begin
    FHeading := False;
    FTable := False;
    FSpanEnd := -1;
  end;
  if Run >= fLineLen then
  begin
    FKind := tkText;
    Run := fLineLen + 1;
    Exit;
  end;

  if FRange <> rgNone then
  begin
    if (Run = 0) and LineClosesFence then
    begin
      FKind := tkMarker;
      FRange := rgNone;
    end
    else
      FKind := tkCode;
    Run := fLineLen;
    Exit;
  end;

  if FSpanEnd >= 0 then
  begin
    if Run < FSpanEnd then
    begin
      Run := FSpanEnd;
      FKind := FSpanKind;
    end
    else
    begin
      Run := FSpanEnd + FSpanClose;
      FKind := tkMarker;
      FSpanEnd := -1;
    end;
    Exit;
  end;

  if (Run = 0) and TakeLineMarker then
  begin
    if Run = fTokenPos then
      Inc(Run);
    Exit;
  end;

  TakeInline;
  if Run = fTokenPos then
    Inc(Run);
end;

end.
