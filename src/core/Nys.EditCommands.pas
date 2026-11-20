unit Nys.EditCommands;

{ String edits for the format bar. The shell applies the result with SelText.
  No VCL and no LCL. }

interface

type
  TNysLines = array of string;

{ Puts a block mark (heading, quote, list, task) on whole lines, or takes it
  off again. See the comment at the implementation. }
procedure ApplyLinePrefix(var Lines: TNysLines; const Prefix: string);
function WrapSelection(const Selected, OpenMark, CloseMark: string): string;
function FenceBlock(const Selected: string): string;
function LinkText(const Selected: string; Image: Boolean): string;
function TableSkeleton: string;
function RuleText: string;

implementation

uses
  System.SysUtils;

function IndentLength(const Line: string): Integer;
begin
  Result := 0;
  while (Result < Length(Line)) and ((Line[Result + 1] = ' ') or (Line[Result + 1] = #9)) do
    Inc(Result);
end;

{ Length of the mark of the same family already at the start of Rest, or 0.
  Same is true when it is exactly the mark Prefix would add. }
function ExistingMark(const Rest, Prefix: string; out Same: Boolean): Integer;
var
  N: Integer;
  IsTask: Boolean;
begin
  Result := 0;
  Same := False;
  if Rest = '' then
    Exit;
  if Prefix[1] = '#' then
  begin
    N := 0;
    while (N < Length(Rest)) and (Rest[N + 1] = '#') do
      Inc(N);
    if (N = 0) or (N > 6) then
      Exit;
    if N < Length(Rest) then
    begin
      if Rest[N + 1] <> ' ' then
        Exit;
      Result := N + 1;
    end
    else
      Result := N;
    Same := N = Length(Trim(Prefix));
    Exit;
  end;
  if Prefix = '1. ' then
  begin
    N := 0;
    while (N < Length(Rest)) and CharInSet(Rest[N + 1], ['0'..'9']) do
      Inc(N);
    if (N > 0) and (Copy(Rest, N + 1, 2) = '. ') then
    begin
      Result := N + 2;
      Same := True;
    end;
    Exit;
  end;
  IsTask := (Copy(Rest, 1, 6) = '- [ ] ') or (Copy(Rest, 1, 6) = '- [x] ') or
    (Copy(Rest, 1, 6) = '- [X] ');
  if Prefix = '- [ ] ' then
  begin
    if IsTask then
    begin
      Result := 6;
      Same := True;
    end
    else if Copy(Rest, 1, 2) = '- ' then
      Result := 2;
    Exit;
  end;
  if (Prefix = '- ') and IsTask then
  begin
    Result := 6;
    Exit;
  end;
  if Copy(Rest, 1, Length(Prefix)) = Prefix then
  begin
    Result := Length(Prefix);
    Same := True;
  end;
end;

{ The mark always goes at the start of the line, after any indent, wherever
  the caret or the selection was.

  If every line already has this mark, it is taken off: the button toggles.
  Otherwise each line gets it, replacing a mark of the same family, so
  Heading 2 on a Heading 1 line gives "## " and not "## # ". Numbered lines
  count up from 1. Blank lines inside a block of several lines are left
  blank. }
procedure ApplyLinePrefix(var Lines: TNysLines; const Prefix: string);
var
  I, Ind, Len, Number: Integer;
  Same, AllSame, Skip, AnyText: Boolean;
  Rest, Mark: string;
begin
  if (Length(Lines) = 0) or (Prefix = '') then
    Exit;
  AnyText := False;
  for I := 0 to High(Lines) do
    if Trim(Lines[I]) <> '' then
      AnyText := True;
  AllSame := True;
  for I := 0 to High(Lines) do
  begin
    if AnyText and (Trim(Lines[I]) = '') then
      Continue;
    Ind := IndentLength(Lines[I]);
    ExistingMark(Copy(Lines[I], Ind + 1, MaxInt), Prefix, Same);
    if not Same then
      AllSame := False;
  end;
  Number := 0;
  for I := 0 to High(Lines) do
  begin
    Skip := AnyText and (Trim(Lines[I]) = '');
    if Skip then
      Continue;
    Ind := IndentLength(Lines[I]);
    Rest := Copy(Lines[I], Ind + 1, MaxInt);
    Len := ExistingMark(Rest, Prefix, Same);
    { a line that already has the mark keeps it as written, so a ticked
      task stays ticked; numbers are still counted again }
    if Same and (not AllSame) and (Prefix <> '1. ') then
      Continue;
    Delete(Rest, 1, Len);
    if AllSame then
      Mark := ''
    else if Prefix = '1. ' then
    begin
      Inc(Number);
      Mark := IntToStr(Number) + '. ';
    end
    else
      Mark := Prefix;
    Lines[I] := Copy(Lines[I], 1, Ind) + Mark + Rest;
  end;
end;

function WrapSelection(const Selected, OpenMark, CloseMark: string): string;
begin
  Result := OpenMark + Selected + CloseMark;
end;

function FenceBlock(const Selected: string): string;
var
  Body: string;
begin
  Body := Selected;
  if Body = '' then
    Body := 'code';
  Result := '```' + sLineBreak + Body + sLineBreak + '```';
end;

function LinkText(const Selected: string; Image: Boolean): string;
var
  LabelText: string;
begin
  LabelText := Selected;
  if LabelText = '' then
  begin
    if Image then
      LabelText := 'image'
    else
      LabelText := 'text';
  end;
  Result := '[';
  if Image then
    Result := '!' + Result;
  Result := Result + LabelText + '](https://)';
end;

function TableSkeleton: string;
begin
  Result :=
    '| Column | Column |' + sLineBreak +
    '| --- | --- |' + sLineBreak +
    '|  |  |' + sLineBreak;
end;

function RuleText: string;
begin
  Result := sLineBreak + '---' + sLineBreak;
end;

end.
