unit Nys.Document;

{ The open file, as the editor holds it. No VCL and no LCL.
  The line endings, the encoding, and the byte order mark of the file on
  disk are remembered, so Save writes the file back the way it was found. }

interface

uses
  System.SysUtils;

type
  { neAnsi is the Windows code page of this machine. A file is read as ANSI
    only when it has no byte order mark and is not valid UTF-8. }
  TNysEncoding = (neUtf8, neAnsi, neUtf16LE, neUtf16BE);

  TNysDocument = class
  public
    FilePath: string;
    SavedText: string;
    LineEnding: string;
    Encoding: TNysEncoding;
    HadBom: Boolean;
    function IsDirty(const EditorText: string): Boolean;
    procedure MarkSaved(const EditorText: string);
  end;

function DecodeText(const Bytes: TBytes; out Encoding: TNysEncoding; out HadBom: Boolean): string;
function EncodeText(const Text: string; Encoding: TNysEncoding; WithBom: Boolean): TBytes;
function AnsiCanHold(const Text: string): Boolean;
function EncodingName(Encoding: TNysEncoding): string;
function DetectLineEnding(const Content: string): string;
function ToEditorNewlines(const Content, EditorBreak: string): string;
function FromEditorNewlines(const EditorText, EditorBreak, FileBreak: string): string;

implementation

{ Strict check: no stray continuation bytes, no overlong forms, no
  surrogates, nothing above U+10FFFF. Text in a Windows code page with any
  accented letter in it fails this, which is how it is told from UTF-8. }
function IsValidUtf8(const Bytes: TBytes; Start: Integer): Boolean;
var
  I, N, Need: Integer;
  B, Lo, Hi: Byte;
begin
  Result := False;
  I := Start;
  N := Length(Bytes);
  while I < N do
  begin
    B := Bytes[I];
    Inc(I);
    if B < $80 then
      Continue;
    Lo := $80;
    Hi := $BF;
    if (B >= $C2) and (B <= $DF) then
      Need := 1
    else if (B >= $E0) and (B <= $EF) then
    begin
      Need := 2;
      if B = $E0 then
        Lo := $A0
      else if B = $ED then
        Hi := $9F;
    end
    else if (B >= $F0) and (B <= $F4) then
    begin
      Need := 3;
      if B = $F0 then
        Lo := $90
      else if B = $F4 then
        Hi := $8F;
    end
    else
      Exit;
    if I + Need > N then
      Exit;
    if (Bytes[I] < Lo) or (Bytes[I] > Hi) then
      Exit;
    Inc(I);
    Dec(Need);
    while Need > 0 do
    begin
      if (Bytes[I] < $80) or (Bytes[I] > $BF) then
        Exit;
      Inc(I);
      Dec(Need);
    end;
  end;
  Result := True;
end;

function DecodeText(const Bytes: TBytes; out Encoding: TNysEncoding; out HadBom: Boolean): string;
var
  N: Integer;
begin
  N := Length(Bytes);
  HadBom := True;
  if (N >= 3) and (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
  begin
    Encoding := neUtf8;
    Result := TEncoding.UTF8.GetString(Bytes, 3, N - 3);
  end
  else if (N >= 2) and (Bytes[0] = $FF) and (Bytes[1] = $FE) then
  begin
    Encoding := neUtf16LE;
    Result := TEncoding.Unicode.GetString(Bytes, 2, N - 2);
  end
  else if (N >= 2) and (Bytes[0] = $FE) and (Bytes[1] = $FF) then
  begin
    Encoding := neUtf16BE;
    Result := TEncoding.BigEndianUnicode.GetString(Bytes, 2, N - 2);
  end
  else
  begin
    HadBom := False;
    if IsValidUtf8(Bytes, 0) then
    begin
      Encoding := neUtf8;
      Result := TEncoding.UTF8.GetString(Bytes);
    end
    else
    begin
      Encoding := neAnsi;
      Result := TEncoding.ANSI.GetString(Bytes);
    end;
  end;
end;

function EncodeText(const Text: string; Encoding: TNysEncoding; WithBom: Boolean): TBytes;
var
  Enc: TEncoding;
  Body, Mark: TBytes;
begin
  case Encoding of
    neAnsi: Enc := TEncoding.ANSI;
    neUtf16LE: Enc := TEncoding.Unicode;
    neUtf16BE: Enc := TEncoding.BigEndianUnicode;
  else
    Enc := TEncoding.UTF8;
  end;
  Body := Enc.GetBytes(Text);
  SetLength(Mark, 0);
  { UTF-16 is not readable without its mark, so it always gets one. }
  if (WithBom and (Encoding = neUtf8)) or (Encoding = neUtf16LE) or (Encoding = neUtf16BE) then
    Mark := Enc.GetPreamble;
  SetLength(Result, Length(Mark) + Length(Body));
  if Length(Mark) > 0 then
    Move(Mark[0], Result[0], Length(Mark));
  if Length(Body) > 0 then
    Move(Body[0], Result[Length(Mark)], Length(Body));
end;

{ False when the text has a character the Windows code page cannot store. }
function AnsiCanHold(const Text: string): Boolean;
begin
  Result := TEncoding.ANSI.GetString(TEncoding.ANSI.GetBytes(Text)) = Text;
end;

function EncodingName(Encoding: TNysEncoding): string;
begin
  case Encoding of
    neAnsi: Result := 'ANSI';
    neUtf16LE: Result := 'UTF-16 LE';
    neUtf16BE: Result := 'UTF-16 BE';
  else
    Result := 'UTF-8';
  end;
end;

function DetectLineEnding(const Content: string): string;
begin
  if Pos(#13#10, Content) > 0 then
    Result := #13#10
  else if Pos(#10, Content) > 0 then
    Result := #10
  else if Pos(#13, Content) > 0 then
    Result := #13
  else
    Result := #13#10;
end;

function ToEditorNewlines(const Content, EditorBreak: string): string;
begin
  Result := StringReplace(Content, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  if EditorBreak <> #10 then
    Result := StringReplace(Result, #10, EditorBreak, [rfReplaceAll]);
end;

function FromEditorNewlines(const EditorText, EditorBreak, FileBreak: string): string;
begin
  if (EditorBreak = '') or (EditorBreak = FileBreak) then
    Result := EditorText
  else
    Result := StringReplace(EditorText, EditorBreak, FileBreak, [rfReplaceAll]);
end;

function TNysDocument.IsDirty(const EditorText: string): Boolean;
begin
  Result := EditorText <> SavedText;
end;

procedure TNysDocument.MarkSaved(const EditorText: string);
begin
  SavedText := EditorText;
end;

end.
