unit Nys.Settings;

{ App settings. Plain Pascal on purpose: no VCL, no LCL, no inline variables,
  so a later Lazarus shell can use this unit as it stands.

  The file is %APPDATA%\NowYouSee\settings.json.
  theme, zoom, and the main window's restored bounds and state. }

interface

type
  TNysThemeKind = (tkLight, tkDark);

  TNysSettings = record
    Theme: TNysThemeKind;
    ZoomPercent: Integer;
    HasWindow: Boolean;
    WindowLeft: Integer;
    WindowTop: Integer;
    WindowWidth: Integer;
    WindowHeight: Integer;
    WindowMaximized: Boolean;
  end;

function SettingsFilePath: string;
function TryLoadSettings(out Settings: TNysSettings): Boolean;
procedure SaveSettings(const Settings: TNysSettings);
function DefaultSettings: TNysSettings;
function ThemeName(Kind: TNysThemeKind): string;

implementation

uses
  System.SysUtils,
  System.Classes;

function ClampZoom(Value: Integer): Integer;
begin
  if Value < 50 then
    Result := 50
  else if Value > 200 then
    Result := 200
  else
    Result := Value;
end;

function DefaultSettings: TNysSettings;
begin
  Result.Theme := tkLight;
  Result.ZoomPercent := 100;
  Result.HasWindow := False;
  Result.WindowLeft := 0;
  Result.WindowTop := 0;
  Result.WindowWidth := 0;
  Result.WindowHeight := 0;
  Result.WindowMaximized := False;
end;

function WindowStateName(Maximized: Boolean): string;
begin
  if Maximized then
    Result := 'maximized'
  else
    Result := 'normal';
end;

function ThemeName(Kind: TNysThemeKind): string;
begin
  if Kind = tkDark then
    Result := 'dark'
  else
    Result := 'light';
end;

function SettingsFilePath: string;
var
  Root: string;
begin
  Root := GetEnvironmentVariable('APPDATA');
  if Root = '' then
    Root := GetEnvironmentVariable('TEMP');
  Result := IncludeTrailingPathDelimiter(Root) + 'NowYouSee' + PathDelim +
    'settings.json';
end;

function QuotedValue(const Json, Key: string): string;
var
  Marker: string;
  P, I: Integer;
begin
  Result := '';
  Marker := '"' + Key + '"';
  P := Pos(Marker, Json);
  if P = 0 then
    Exit;
  I := P + Length(Marker);
  while (I <= Length(Json)) and (Json[I] <> '"') do
    Inc(I);
  if I > Length(Json) then
    Exit;
  Inc(I);
  P := I;
  while (I <= Length(Json)) and (Json[I] <> '"') do
    Inc(I);
  Result := Copy(Json, P, I - P);
end;

function NumberValue(const Json, Key: string; Fallback: Integer): Integer;
var
  Marker: string;
  P, I: Integer;
  Digits: string;
begin
  Result := Fallback;
  Marker := '"' + Key + '"';
  P := Pos(Marker, Json);
  if P = 0 then
    Exit;
  I := P + Length(Marker);
  while (I <= Length(Json)) and not CharInSet(Json[I], ['0'..'9', '-']) do
    Inc(I);
  if I > Length(Json) then
    Exit;
  Digits := '';
  if Json[I] = '-' then
  begin
    Digits := '-';
    Inc(I);
  end;
  while (I <= Length(Json)) and CharInSet(Json[I], ['0'..'9']) do
  begin
    Digits := Digits + Json[I];
    Inc(I);
  end;
  if (Digits = '') or (Digits = '-') then
    Exit;
  Result := StrToIntDef(Digits, Fallback);
end;

function TryLoadSettings(out Settings: TNysSettings): Boolean;
var
  List: TStringList;
  Json, Name: string;
begin
  Settings := DefaultSettings;
  Result := FileExists(SettingsFilePath);
  if not Result then
    Exit;
  List := TStringList.Create;
  try
    try
      List.LoadFromFile(SettingsFilePath, TEncoding.UTF8);
    except
      Result := False;
      Exit;
    end;
    Json := List.Text;
  finally
    List.Free;
  end;
  Name := LowerCase(QuotedValue(Json, 'theme'));
  if Name = 'dark' then
    Settings.Theme := tkDark
  else if Name = 'light' then
    Settings.Theme := tkLight;
  Settings.ZoomPercent := ClampZoom(NumberValue(Json, 'zoom', Settings.ZoomPercent));
  if (Pos('"windowWidth"', Json) > 0) and (Pos('"windowHeight"', Json) > 0) then
  begin
    Settings.WindowLeft := NumberValue(Json, 'windowLeft', 0);
    Settings.WindowTop := NumberValue(Json, 'windowTop', 0);
    Settings.WindowWidth := NumberValue(Json, 'windowWidth', 0);
    Settings.WindowHeight := NumberValue(Json, 'windowHeight', 0);
    Settings.WindowMaximized := LowerCase(QuotedValue(Json, 'windowState')) = 'maximized';
    Settings.HasWindow := (Settings.WindowWidth >= 480) and (Settings.WindowHeight >= 320);
  end;
end;

procedure SaveSettings(const Settings: TNysSettings);
var
  List: TStringList;
  Path, Body: string;
begin
  Path := SettingsFilePath;
  ForceDirectories(ExtractFilePath(Path));
  Body :=
    '{' + sLineBreak +
    '  "theme": "' + ThemeName(Settings.Theme) + '",' + sLineBreak +
    '  "zoom": ' + IntToStr(ClampZoom(Settings.ZoomPercent));
  if Settings.HasWindow then
    Body := Body + ',' + sLineBreak +
      '  "windowLeft": ' + IntToStr(Settings.WindowLeft) + ',' + sLineBreak +
      '  "windowTop": ' + IntToStr(Settings.WindowTop) + ',' + sLineBreak +
      '  "windowWidth": ' + IntToStr(Settings.WindowWidth) + ',' + sLineBreak +
      '  "windowHeight": ' + IntToStr(Settings.WindowHeight) + ',' + sLineBreak +
      '  "windowState": "' + WindowStateName(Settings.WindowMaximized) + '"';
  Body := Body + sLineBreak + '}' + sLineBreak;
  List := TStringList.Create;
  try
    List.Text := Body;
    List.SaveToFile(Path, TEncoding.UTF8);
  finally
    List.Free;
  end;
end;

end.
