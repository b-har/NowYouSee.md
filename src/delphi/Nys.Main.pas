unit Nys.Main;

{ Delphi shell. The toolbars, their buttons, the host, and the status panel
  are on the form. SynEdit and TEdgeBrowser are created at runtime.

  The buttons are TSpeedButton. Nys.Chrome, listed after Vcl.Buttons, draws
  them. The colors come from the palette in that unit. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.WebView2,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Buttons,
  Vcl.ComCtrls,
  Vcl.Edge,
  SynEdit,
  SynEditTypes,
  Nys.Settings,
  Nys.Document,
  Nys.Highlighter,
  Nys.Chrome;

const
  AppName = 'NowYouSee.md';

type
  TMainForm = class(TForm)
    Bar: TPanel;
    BtnView: TSpeedButton;
    BtnEdit: TSpeedButton;
    BtnOpen: TSpeedButton;
    BtnSave: TSpeedButton;
    BtnZoomOut: TSpeedButton;
    LblZoom: TLabel;
    BtnZoomIn: TSpeedButton;
    BtnTheme: TSpeedButton;
    BtnClose: TSpeedButton;
    EditBar: TPanel;
    BtnH1: TSpeedButton;
    BtnH2: TSpeedButton;
    BtnH3: TSpeedButton;
    BtnBold: TSpeedButton;
    BtnItalic: TSpeedButton;
    BtnStrike: TSpeedButton;
    BtnCode: TSpeedButton;
    BtnLink: TSpeedButton;
    BtnImage: TSpeedButton;
    BtnQuote: TSpeedButton;
    BtnList: TSpeedButton;
    BtnNumber: TSpeedButton;
    BtnTask: TSpeedButton;
    BtnFence: TSpeedButton;
    BtnTable: TSpeedButton;
    BtnRule: TSpeedButton;
    StatusFrame: TPanel;
    StatusPanel: TPanel;
    LblPath: TLabel;
    LblState: TLabel;
    LblEnc: TLabel;
    LblPos: TLabel;
    Host: TPanel;
    FailLabel: TLabel;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ViewClick(Sender: TObject);
    procedure EditClick(Sender: TObject);
    procedure OpenClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure ThemeClick(Sender: TObject);
    procedure ZoomOutClick(Sender: TObject);
    procedure ZoomInClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure FormatClick(Sender: TObject);
  private
    FView: TEdgeBrowser;
    FEditor: TSynEdit;
    FHighlighter: TNysMarkdownSyn;
    FDoc: TNysDocument;
    FSettings: TNysSettings;
    FEditing: Boolean;
    FLoading: Boolean;
    FWebReady: Boolean;
    FWebFailed: Boolean;
    FRendered: string;
    FPreviewFile: string;
    FPreviewUrl: string;
    FDeleteAfterNav: string;
    FPreviewSeq: Integer;
    FCaretLine: Integer;
    FCaretCol: Integer;
    FTopLine: Integer;
    FPendingScroll: Integer;
    FToken: Integer;
    FPalette: TNysPalette;
    FNormalBounds: TRect;
    FWasMaximized: Boolean;
    FTrackBounds: Boolean;
    { the file on disk as last read or written, and the watch for changes }
    FWatch: TTimer;
    FDiskTime: TDateTime;
    FDiskSize: Int64;
    FSeenTime: TDateTime;
    FSeenSize: Int64;
    FSeenCount: Integer;
    FChecking: Boolean;
    procedure NoteDiskState;
    procedure WatchTick(Sender: TObject);
    procedure ReloadFromDisk;
    procedure CreateViewAndEditor;
    procedure ApplySavedWindow;
    procedure CaptureWindowSettings;
    procedure PersistSettings;
    procedure ApplyChrome;
    procedure ApplyEditorColors;
    procedure ShowMode;
    procedure UpdateStatus;
    procedure ShowCaretPos;
    procedure EditorChanged(Sender: TObject);
    procedure EditorStatus(Sender: TObject; Changes: TSynStatusChanges);
    procedure WebViewCreated(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure WebNavCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
      WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure WebNavStarting(Sender: TCustomEdgeBrowser; Args: TNavigationStartingEventArgs);
    procedure WebZoomChanged(Sender: TCustomEdgeBrowser; AZoomFactor: Double);
    procedure ShowEditor;
    procedure BeginEdit;
    procedure BeginView;
    procedure RefreshView;
    procedure ScrollPreviewTo(Line: Integer);
    procedure SetZoom(Percent: Integer; Persist: Boolean);
    procedure LoadFile(const Path: string; KeepPlace: Boolean = False);
    procedure OpenLinkedFile(const Path: string);
    procedure SaveTo(const Path: string);
    function SaveAs: Boolean;
    procedure ToggleMode;
    function ConfirmDiscard: Boolean;
    procedure RememberCaret;
    function LineCount: Integer;
    procedure PrefixSelection(const Prefix: string);
    procedure ReplaceSelection(const Text: string; CaretBack: Integer);
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
  public
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  System.UITypes,
  System.NetEncoding,
  Winapi.ShellAPI,
  Winapi.DwmApi,
  Winapi.UxTheme,
  SynEditTextBuffer,
  Winapi.ActiveX,
  Winapi.EdgeUtils,
  System.Win.Registry,
  Nys.EditCommands,
  Nys.Render;

function WindowsAppsUseDark: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize') then
      if Reg.ValueExists('AppsUseLightTheme') then
        Result := Reg.ReadInteger('AppsUseLightTheme') = 0;
  finally
    Reg.Free;
  end;
end;

function PathToFileUrl(const APath: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := 'file:///';
  for I := 1 to Length(APath) do
  begin
    C := APath[I];
    if C = '\' then
      Result := Result + '/'
    else if C = ' ' then
      Result := Result + '%20'
    else if C = '#' then
      Result := Result + '%23'
    else if C = '%' then
      Result := Result + '%25'
    else
      Result := Result + C;
  end;
end;

{ file:///C:/dir/name.md#part  ->  C:\dir\name.md.  Empty when it is not a
  local file URL. }
function FileUrlToPath(const Url: string): string;
var
  P: Integer;
begin
  Result := '';
  if not Url.StartsWith('file:///', True) then
    Exit;
  Result := Copy(Url, Length('file:///') + 1, MaxInt);
  P := Pos('#', Result);
  if P > 0 then
    Result := Copy(Result, 1, P - 1);
  P := Pos('?', Result);
  if P > 0 then
    Result := Copy(Result, 1, P - 1);
  try
    Result := TNetEncoding.URL.Decode(Result, []);
  except
    Result := '';
  end;
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
end;

function IsMarkdownFile(const Path: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(Path));
  Result := (Ext = '.md') or (Ext = '.markdown') or (Ext = '.mdown') or (Ext = '.txt');
end;

{ Time and size of a file. False when it is not there. }
function FileStamp(const Path: string; out Time: TDateTime; out Size: Int64): Boolean;
var
  SR: TSearchRec;
begin
  Result := FindFirst(Path, faAnyFile, SR) = 0;
  if Result then
  begin
    Time := SR.TimeStamp;
    Size := SR.Size;
    System.SysUtils.FindClose(SR);
  end;
end;

function JsonInt(const Json: string; Fallback: Integer): Integer;
var
  T: string;
begin
  T := Trim(Json);
  if (Length(T) >= 2) and (T[1] = '"') and (T[Length(T)] = '"') then
    T := Copy(T, 2, Length(T) - 2);
  Result := StrToIntDef(T, Fallback);
end;

procedure TMainForm.CreateViewAndEditor;
var
  Loader: string;
begin
  FEditor := TSynEdit.Create(Self);
  FEditor.Parent := Host;
  FEditor.Align := alClient;
  FEditor.Visible := False;
  FEditor.StyleElements := [];
  FHighlighter := TNysMarkdownSyn.Create(Self);
  FEditor.Highlighter := FHighlighter;
  FEditor.Font.Name := 'Cascadia Mono';
  if FEditor.Font.Name <> 'Cascadia Mono' then
    FEditor.Font.Name := 'Consolas';
  FEditor.Font.Size := 11;
  FEditor.WantTabs := True;
  FEditor.TabWidth := 4;
  FEditor.Options := FEditor.Options + [eoTabsToSpaces, eoTabIndent];
  FEditor.RightEdge := 0;
  FEditor.ScrollBars := ssBoth;
  FEditor.Gutter.ShowLineNumbers := True;
  FEditor.Gutter.AutoSize := True;
  FEditor.WordWrap := True;
  FEditor.OnChange := EditorChanged;
  FEditor.OnStatusChange := EditorStatus;
  FEditor.BorderStyle := bsNone;

  FView := TEdgeBrowser.Create(Self);
  FView.Parent := Host;
  FView.Align := alClient;
  FView.UserDataFolder := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'NowYouSee\WebView2');
  ForceDirectories(FView.UserDataFolder);
  FView.OnCreateWebViewCompleted := WebViewCreated;
  FView.OnNavigationCompleted := WebNavCompleted;
  FView.OnNavigationStarting := WebNavStarting;
  FView.OnZoomFactorChanged := WebZoomChanged;

  Loader := ExtractFilePath(ParamStr(0)) + 'WebView2Loader.dll';
  if FileExists(Loader) then
    SetWebView2Path(Loader);
  FView.CreateWebView;
end;

procedure TMainForm.ApplyEditorColors;
begin
  FEditor.Color := FPalette.Editor;
  FEditor.Font.Color := FPalette.EditorText;
  FEditor.Font.Size := Round(11 * FSettings.ZoomPercent / 100);
  if FEditor.Font.Size < 8 then
    FEditor.Font.Size := 8;
  FEditor.Gutter.Color := FPalette.Gutter;
  FEditor.Gutter.Font.Color := FPalette.Muted;
  FEditor.Gutter.BorderColor := FPalette.Border;
  FEditor.ActiveLineColor := FPalette.ActiveLine;
  FEditor.SelectedColor.Background := FPalette.Selection;
  FEditor.SelectedColor.Foreground := FPalette.EditorText;
  { Markdown syntax in the marker color, prose in the text color. }
  FHighlighter.TextAttr.Foreground := FPalette.EditorText;
  FHighlighter.TextAttr.Background := clNone;
  FHighlighter.HeadingAttr.Foreground := FPalette.EditorText;
  FHighlighter.HeadingAttr.Background := clNone;
  FHighlighter.MarkerAttr.Foreground := FPalette.Marker;
  FHighlighter.MarkerAttr.Background := clNone;
  FHighlighter.UrlAttr.Foreground := FPalette.Marker;
  FHighlighter.UrlAttr.Background := clNone;
  FHighlighter.CodeAttr.Foreground := FPalette.EditorText;
  FHighlighter.CodeAttr.Background := FPalette.CodeBack;
  { dark or light scroll bars }
  FEditor.HandleNeeded;
  if FEditor.HandleAllocated then
  begin
    if FPalette.Dark then
      SetWindowTheme(FEditor.Handle, 'DarkMode_Explorer', nil)
    else
      SetWindowTheme(FEditor.Handle, 'Explorer', nil);
  end;
  FEditor.Invalidate;
end;

procedure TMainForm.ShowMode;
begin
  BtnView.Down := not FEditing;
  BtnEdit.Down := FEditing;
  EditBar.Visible := FEditing;
  Bar.Top := 0;
end;

procedure TMainForm.ApplyChrome;
const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
var
  UseDark: BOOL;

  procedure InkButtons(Panel: TPanel);
  var
    J: Integer;
  begin
    for J := 0 to Panel.ControlCount - 1 do
      if Panel.Controls[J] is TSpeedButton then
        TSpeedButton(Panel.Controls[J]).Font.Color := FPalette.Text;
    Panel.Invalidate;
  end;

begin
  if FSettings.Theme = tkDark then
    FPalette := DarkPalette
  else
    FPalette := LightPalette;
  ChromePalette := FPalette;

  UseDark := FPalette.Dark;
  DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @UseDark, SizeOf(UseDark));

  Color := FPalette.Window;
  Font.Color := FPalette.Text;
  Bar.Color := FPalette.Window;
  EditBar.Color := FPalette.Window;
  { Host and StatusFrame are one pixel larger than what they hold, so their
    own color shows as the border. }
  Host.Color := FPalette.Border;
  FailLabel.Color := FPalette.Editor;
  FailLabel.Font.Color := FPalette.Muted;
  StatusFrame.Color := FPalette.Border;
  StatusPanel.Color := FPalette.Panel;
  LblPath.Font.Color := FPalette.Text;
  LblPos.Font.Color := FPalette.Text;
  LblEnc.Font.Color := FPalette.Muted;
  LblZoom.Font.Color := FPalette.Text;
  LblZoom.Caption := IntToStr(FSettings.ZoomPercent) + '%';
  if FSettings.Theme = tkDark then
    BtnTheme.Caption := 'Light'
  else
    BtnTheme.Caption := 'Dark';
  InkButtons(Bar);
  InkButtons(EditBar);
  ShowMode;
  ApplyEditorColors;
  UpdateStatus;
end;

procedure TMainForm.ShowCaretPos;
begin
  if FEditing then
    LblPos.Caption := 'Ln ' + IntToStr(FEditor.CaretY) + ', Col ' + IntToStr(FEditor.CaretX)
  else
    LblPos.Caption := 'View';
end;

procedure TMainForm.UpdateStatus;
var
  Name: string;
  Dirty: Boolean;
begin
  Dirty := FDoc.IsDirty(FEditor.Text);
  if FDoc.FilePath = '' then
  begin
    Name := 'Untitled';
    LblPath.Caption := 'Untitled.  Open a Markdown file, or drop one onto the window.';
  end
  else
  begin
    Name := ExtractFileName(FDoc.FilePath);
    LblPath.Caption := FDoc.FilePath;
  end;
  LblPath.Hint := FDoc.FilePath;
  LblEnc.Caption := EncodingName(FDoc.Encoding);
  if Dirty then
  begin
    LblState.Caption := 'Edited';
    LblState.Font.Color := FPalette.Dirty;
    BtnSave.Font.Color := FPalette.Dirty;
    Caption := #$25CF'  ' + Name + '  '#$2014'  ' + AppName;
  end
  else
  begin
    LblState.Caption := '';
    BtnSave.Font.Color := FPalette.Text;
    Caption := Name + '  '#$2014'  ' + AppName;
  end;
  ShowCaretPos;
end;

procedure TMainForm.EditorChanged(Sender: TObject);
begin
  if FLoading then
    Exit;
  UpdateStatus;
end;

procedure TMainForm.EditorStatus(Sender: TObject; Changes: TSynStatusChanges);
begin
  if FLoading or not FEditing then
    Exit;
  if (scCaretX in Changes) or (scCaretY in Changes) then
    ShowCaretPos;
end;

function TMainForm.LineCount: Integer;
begin
  Result := TSynEditStringList(FEditor.Lines).CountNative;
end;

procedure TMainForm.RememberCaret;
begin
  FCaretLine := FEditor.CaretY;
  FCaretCol := FEditor.CaretX;
  FTopLine := FEditor.TopLine;
  if FCaretLine < 1 then
    FCaretLine := 1;
  if FCaretCol < 1 then
    FCaretCol := 1;
end;

procedure TMainForm.ShowEditor;
var
  Pos: TBufferCoord;
begin
  FEditing := True;
  FView.Visible := False;
  FailLabel.Visible := False;
  FEditor.Visible := True;
  if FCaretLine > LineCount then
    FCaretLine := LineCount;
  if FCaretLine < 1 then
    FCaretLine := 1;
  Pos.Char := FCaretCol;
  Pos.Line := FCaretLine;
  FEditor.CaretXY := Pos;
  if FTopLine > 0 then
    FEditor.TopLine := FTopLine;
  ShowMode;
  FEditor.SetFocus;
  UpdateStatus;
end;

procedure TMainForm.ScrollPreviewTo(Line: Integer);
begin
  if not FWebReady then
    Exit;
  if Line < 1 then
    Line := 1;
  FView.ExecuteScript('nysScrollTo(' + IntToStr(Line) + ')');
end;

procedure TMainForm.RefreshView;
var
  Html, Dir, Name, Base, Title: string;
begin
  if not FWebReady then
  begin
    { Still starting, or failed. The text is for a failure only. }
    FView.Visible := False;
    FailLabel.Visible := FWebFailed;
    Exit;
  end;
  FailLabel.Visible := False;
  FView.Visible := True;
  if FEditor.Text = FRendered then
  begin
    ScrollPreviewTo(FCaretLine);
    Exit;
  end;
  Dir := TPath.Combine(TPath.GetTempPath, 'NowYouSee');
  ForceDirectories(Dir);
  Inc(FPreviewSeq);
  { the process id keeps two running copies off each other's page }
  Name := TPath.Combine(Dir, 'preview-' + IntToStr(GetCurrentProcessId) + '-' +
    IntToStr(FPreviewSeq) + '.html');
  if FDoc.FilePath = '' then
  begin
    Base := '';
    Title := 'Untitled';
  end
  else
  begin
    Base := PathToFileUrl(IncludeTrailingPathDelimiter(ExtractFilePath(FDoc.FilePath)));
    Title := ExtractFileName(FDoc.FilePath);
  end;
  Html := BuildPreviewPage(RenderMarkdownFragment(FEditor.Text), Title, Base, ThemeName(FSettings.Theme));
  TFile.WriteAllBytes(Name, TEncoding.UTF8.GetBytes(Html));
  FRendered := FEditor.Text;
  FPendingScroll := FCaretLine;
  if (FDeleteAfterNav <> '') and FileExists(FDeleteAfterNav) then
    System.SysUtils.DeleteFile(FDeleteAfterNav);
  FDeleteAfterNav := FPreviewFile;
  FPreviewFile := Name;
  FPreviewUrl := PathToFileUrl(Name);
  FView.Navigate(FPreviewUrl);
end;

procedure TMainForm.BeginView;
begin
  RememberCaret;
  FEditing := False;
  FEditor.Visible := False;
  ShowMode;
  UpdateStatus;
  RefreshView;
end;

procedure TMainForm.BeginEdit;
var
  Token: Integer;
begin
  if FWebReady and (not FEditing) and FView.Visible then
  begin
    Inc(FToken);
    Token := FToken;
    RememberCaret;
    FView.ExecuteScript('nysTopLine()',
      procedure(Sender: TCustomEdgeBrowser; AResult: HRESULT; const AResultObjectAsJson: string)
      begin
        if Token <> FToken then
          Exit;
        if Succeeded(AResult) then
        begin
          FCaretLine := JsonInt(AResultObjectAsJson, FCaretLine);
          FCaretCol := 1;
          FTopLine := FCaretLine;
        end;
        ShowEditor;
      end);
  end
  else
    ShowEditor;
end;

procedure TMainForm.ViewClick(Sender: TObject);
begin
  if not FEditing then
    Exit;
  BeginView;
end;

procedure TMainForm.EditClick(Sender: TObject);
begin
  if FEditing then
    Exit;
  BeginEdit;
end;

procedure TMainForm.ToggleMode;
begin
  if FEditing then
    BeginView
  else
    BeginEdit;
end;

procedure TMainForm.CloseClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.SetZoom(Percent: Integer; Persist: Boolean);
begin
  if Percent < 50 then
    Percent := 50;
  if Percent > 200 then
    Percent := 200;
  FSettings.ZoomPercent := Percent;
  if FWebReady then
    FView.ZoomFactor := Percent / 100;
  if Persist then
    PersistSettings;
  ApplyChrome;
end;

procedure TMainForm.ZoomOutClick(Sender: TObject);
begin
  SetZoom(FSettings.ZoomPercent - 10, True);
end;

procedure TMainForm.ZoomInClick(Sender: TObject);
begin
  SetZoom(FSettings.ZoomPercent + 10, True);
end;

procedure TMainForm.ThemeClick(Sender: TObject);
begin
  if FSettings.Theme = tkDark then
    FSettings.Theme := tkLight
  else
    FSettings.Theme := tkDark;
  PersistSettings;
  FRendered := '';
  ApplyChrome;
  if not FEditing then
    RefreshView;
end;

procedure TMainForm.WebViewCreated(Sender: TCustomEdgeBrowser; AResult: HRESULT);
begin
  FWebReady := Succeeded(AResult);
  FWebFailed := not FWebReady;
  if FWebReady then
    FView.ZoomFactor := FSettings.ZoomPercent / 100
  else if not FEditing then
    FailLabel.Visible := True;
  if FWebReady and not FEditing then
    RefreshView;
end;

procedure TMainForm.WebNavCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
  WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if IsSuccess and (FPendingScroll > 0) then
    ScrollPreviewTo(FPendingScroll);
  FPendingScroll := 0;
  if (FDeleteAfterNav <> '') and FileExists(FDeleteAfterNav) then
    System.SysUtils.DeleteFile(FDeleteAfterNav);
  FDeleteAfterNav := '';
end;

procedure TMainForm.WebNavStarting(Sender: TCustomEdgeBrowser; Args: TNavigationStartingEventArgs);
var
  Uri: PChar;
  Url, Path: string;
begin
  Uri := nil;
  if Failed(Args.ArgsInterface.Get_Uri(Uri)) or (Uri = nil) then
    Exit;
  Url := Uri;
  CoTaskMemFree(Uri);
  if SameText(Url, FPreviewUrl) then
    Exit;
  if (Url = '') or Url.StartsWith('about:') then
    Exit;
  Args.ArgsInterface.Set_Cancel(1);
  if Url.StartsWith('http://') or Url.StartsWith('https://') or Url.StartsWith('mailto:') then
    ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL)
  else
  begin
    { A link to another Markdown file, or a file dropped on the page.
      Open it here, once this event has returned. }
    Path := FileUrlToPath(Url);
    if (Path <> '') and IsMarkdownFile(Path) and FileExists(Path) then
      TThread.ForceQueue(nil,
        procedure
        begin
          OpenLinkedFile(Path);
        end);
  end;
end;

procedure TMainForm.OpenLinkedFile(const Path: string);
begin
  if SameText(Path, FDoc.FilePath) then
    Exit;
  if ConfirmDiscard then
    LoadFile(Path);
end;

procedure TMainForm.WebZoomChanged(Sender: TCustomEdgeBrowser; AZoomFactor: Double);
var
  Percent: Integer;
begin
  Percent := Round(AZoomFactor * 100);
  if Percent < 50 then
    Percent := 50;
  if Percent > 200 then
    Percent := 200;
  if Percent = FSettings.ZoomPercent then
    Exit;
  FSettings.ZoomPercent := Percent;
  PersistSettings;
  ApplyChrome;
end;

function TMainForm.ConfirmDiscard: Boolean;
var
  Answer: Integer;
begin
  Result := True;
  if not FDoc.IsDirty(FEditor.Text) then
    Exit;
  Answer := MessageDlg('Save changes before closing this file?', mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if Answer = mrYes then
  begin
    SaveClick(nil);
    Result := not FDoc.IsDirty(FEditor.Text);
  end
  else
    Result := Answer = mrNo;
end;

{ KeepPlace is for reading the same file again: the caret and the scroll
  position stay where they were. }
procedure TMainForm.LoadFile(const Path: string; KeepPlace: Boolean);
var
  Raw, EditorBreak: string;
  Enc: TNysEncoding;
  Bom: Boolean;
  Line: Integer;
begin
  Raw := DecodeText(TFile.ReadAllBytes(Path), Enc, Bom);
  if KeepPlace then
  begin
    { in View, FCaretLine already holds the line at the top of the page }
    if FEditing then
      RememberCaret;
  end
  else
  begin
    FCaretLine := 1;
    FCaretCol := 1;
    FTopLine := 1;
  end;
  FDoc.FilePath := Path;
  FDoc.Encoding := Enc;
  FDoc.HadBom := Bom;
  FDoc.LineEnding := DetectLineEnding(Raw);
  EditorBreak := FEditor.Lines.LineBreak;
  if EditorBreak = '' then
    EditorBreak := sLineBreak;
  FLoading := True;
  try
    FEditor.Text := ToEditorNewlines(Raw, EditorBreak);
    { Undo must not reach back into the file that was open before. }
    FEditor.ClearUndo;
  finally
    FLoading := False;
  end;
  FDoc.MarkSaved(FEditor.Text);
  NoteDiskState;
  FRendered := '';
  Line := FCaretLine;
  if Line > LineCount then
    Line := LineCount;
  if Line < 1 then
    Line := 1;
  FEditor.CaretXY := BufferCoord(FCaretCol, Line);
  if FEditing then
    ShowEditor
  else
    BeginView;
end;

procedure TMainForm.NoteDiskState;
begin
  FSeenCount := 0;
  if (FDoc.FilePath = '') or not FileStamp(FDoc.FilePath, FDiskTime, FDiskSize) then
  begin
    FDiskTime := 0;
    FDiskSize := -1;
  end;
end;

procedure TMainForm.ReloadFromDisk;
begin
  if (not FEditing) and FWebReady and FView.Visible then
    { stay at the part of the page being read }
    FView.ExecuteScript('nysTopLine()',
      procedure(Sender: TCustomEdgeBrowser; AResult: HRESULT; const AResultObjectAsJson: string)
      begin
        if Succeeded(AResult) then
        begin
          FCaretLine := JsonInt(AResultObjectAsJson, FCaretLine);
          FCaretCol := 1;
          FTopLine := FCaretLine;
        end;
      end);
  try
    LoadFile(FDoc.FilePath, True);
  except
    { the other program may still have it open; the next tick tries again }
  end;
end;

{ Once a second: has another program changed the open file?

  A change is acted on only when the same new time and size have been seen
  twice, so a file that is still being written is left alone. With no
  edits here the file is simply read again. With edits here the user is
  asked, once per change, and only while this program is in front. }
procedure TMainForm.WatchTick(Sender: TObject);
var
  T: TDateTime;
  S: Int64;
begin
  if FChecking or FLoading or (FDoc.FilePath = '') or (Application.ModalLevel > 0) then
    Exit;
  if not FileStamp(FDoc.FilePath, T, S) then
    Exit;
  if (T = FDiskTime) and (S = FDiskSize) then
  begin
    FSeenCount := 0;
    Exit;
  end;
  if (FSeenCount = 0) or (T <> FSeenTime) or (S <> FSeenSize) then
  begin
    FSeenTime := T;
    FSeenSize := S;
    FSeenCount := 1;
    Exit;
  end;
  FChecking := True;
  try
    if not FDoc.IsDirty(FEditor.Text) then
      ReloadFromDisk
    else if Application.Active then
    begin
      { asked once: "No" keeps the edits, and Save will then replace the
        other version, which stays in the .bak file }
      FDiskTime := T;
      FDiskSize := S;
      FSeenCount := 0;
      if MessageDlg(ExtractFileName(FDoc.FilePath) + ' was changed by another program.' +
        sLineBreak + sLineBreak + 'Reload it, and lose the edits made here?',
        mtWarning, [mbYes, mbNo], 0) = mrYes then
        ReloadFromDisk;
    end;
  finally
    FChecking := False;
  end;
end;

procedure TMainForm.OpenClick(Sender: TObject);
begin
  if not ConfirmDiscard then
    Exit;
  if FDoc.FilePath <> '' then
    OpenDialog.InitialDir := ExtractFilePath(FDoc.FilePath);
  if OpenDialog.Execute then
    LoadFile(OpenDialog.FileName);
end;

{ Writes the text the way the file was found: same line endings, same
  encoding, same byte order mark. The version being replaced is kept beside
  it as <name>.bak. }
procedure TMainForm.SaveTo(const Path: string);
var
  EditorBreak, Content: string;
  Enc: TNysEncoding;
  Bom: Boolean;
  Bytes: TBytes;
begin
  EditorBreak := FEditor.Lines.LineBreak;
  if EditorBreak = '' then
    EditorBreak := sLineBreak;
  Content := FromEditorNewlines(FEditor.Text, EditorBreak, FDoc.LineEnding);
  Enc := FDoc.Encoding;
  Bom := FDoc.HadBom;
  if (Enc = neAnsi) and not AnsiCanHold(Content) then
  begin
    if MessageDlg('This file is stored as ANSI, and the text now has characters ANSI cannot hold.' +
      sLineBreak + sLineBreak + 'Save it as UTF-8 instead?',
      mtConfirmation, [mbOK, mbCancel], 0) <> mrOk then
      Exit;
    Enc := neUtf8;
    Bom := False;
  end;
  Bytes := EncodeText(Content, Enc, Bom);
  if FileExists(Path) then
    TFile.Copy(Path, Path + '.bak', True);
  TFile.WriteAllBytes(Path, Bytes);
  { Only after the write worked. }
  FDoc.FilePath := Path;
  FDoc.Encoding := Enc;
  FDoc.HadBom := Bom;
  FDoc.MarkSaved(FEditor.Text);
  NoteDiskState;
  UpdateStatus;
end;

function TMainForm.SaveAs: Boolean;
var
  Path: string;
begin
  Result := False;
  if FDoc.FilePath = '' then
    SaveDialog.FileName := 'Untitled.md'
  else
  begin
    SaveDialog.InitialDir := ExtractFilePath(FDoc.FilePath);
    SaveDialog.FileName := ExtractFileName(FDoc.FilePath);
  end;
  if not SaveDialog.Execute then
    Exit;
  Path := SaveDialog.FileName;
  if ExtractFileExt(Path) = '' then
    Path := Path + '.md';
  SaveTo(Path);
  { relative images and links resolve against the new folder }
  FRendered := '';
  if not FEditing then
    RefreshView;
  Result := True;
end;

procedure TMainForm.SaveClick(Sender: TObject);
begin
  if FDoc.FilePath = '' then
    SaveAs
  else
    SaveTo(FDoc.FilePath);
end;

procedure TMainForm.ReplaceSelection(const Text: string; CaretBack: Integer);
begin
  FEditor.SelText := Text;
  if (CaretBack > 0) and (FEditor.CaretX > CaretBack) then
    FEditor.CaretX := FEditor.CaretX - CaretBack;
  FEditor.SetFocus;
end;

{ Block marks work on whole lines: every line the selection touches, or the
  caret's line. The edit goes in through SelText so one undo takes it back. }
procedure TMainForm.PrefixSelection(const Prefix: string);
var
  Lines: TNysLines;
  First, Last, I, X, OldLen: Integer;
  HadSel: Boolean;
  Text: string;
begin
  if LineCount = 0 then
  begin
    FEditor.SelText := Prefix;
    FEditor.SetFocus;
    Exit;
  end;
  HadSel := FEditor.SelAvail;
  if HadSel then
  begin
    First := FEditor.BlockBegin.Line;
    Last := FEditor.BlockEnd.Line;
    { a selection that ends at the start of a line does not include it }
    if (Last > First) and (FEditor.BlockEnd.Char <= 1) then
      Dec(Last);
  end
  else
  begin
    First := FEditor.CaretY;
    Last := First;
  end;
  if (First < 1) or (Last > LineCount) or (Last < First) then
    Exit;
  X := FEditor.CaretX;
  SetLength(Lines, Last - First + 1);
  for I := 0 to High(Lines) do
    Lines[I] := FEditor.Lines[First - 1 + I];
  OldLen := Length(Lines[0]);
  ApplyLinePrefix(Lines, Prefix);
  Text := '';
  for I := 0 to High(Lines) do
  begin
    if I > 0 then
      Text := Text + sLineBreak;
    Text := Text + Lines[I];
  end;
  FEditor.SetCaretAndSelection(BufferCoord(1, First), BufferCoord(1, First),
    BufferCoord(Length(FEditor.Lines[Last - 1]) + 1, Last));
  FEditor.SelText := Text;
  if HadSel then
    { keep the lines selected, so the next button works on the same block }
    FEditor.SetCaretAndSelection(BufferCoord(Length(Lines[High(Lines)]) + 1, Last),
      BufferCoord(1, First), BufferCoord(Length(Lines[High(Lines)]) + 1, Last))
  else
  begin
    X := X + Length(Lines[0]) - OldLen;
    if X < 1 then
      X := 1;
    FEditor.CaretXY := BufferCoord(X, First);
  end;
  FEditor.SetFocus;
end;

procedure TMainForm.FormatClick(Sender: TObject);
var
  Which: Integer;
  Selected: string;
begin
  if not (Sender is TSpeedButton) then
    Exit;
  Which := TSpeedButton(Sender).Tag;
  Selected := FEditor.SelText;
  case Which of
    0: PrefixSelection('# ');
    1: PrefixSelection('## ');
    2: PrefixSelection('### ');
    3: ReplaceSelection(WrapSelection(Selected, '**', '**'), Length('**'));
    4: ReplaceSelection(WrapSelection(Selected, '*', '*'), 1);
    5: ReplaceSelection(WrapSelection(Selected, '~~', '~~'), 2);
    6: ReplaceSelection(WrapSelection(Selected, '`', '`'), 1);
    7: ReplaceSelection(LinkText(Selected, False), 1);
    8: ReplaceSelection(LinkText(Selected, True), 1);
    9: PrefixSelection('> ');
    10: PrefixSelection('- ');
    11: PrefixSelection('1. ');
    12: PrefixSelection('- [ ] ');
    13: ReplaceSelection(FenceBlock(Selected), 0);
    14: ReplaceSelection(TableSkeleton, 0);
    15: ReplaceSelection(RuleText, 0);
  end;
end;

function IntersectsAnyMonitor(const R: TRect): Boolean;
var
  I: Integer;
  M: TRect;
begin
  Result := False;
  for I := 0 to Screen.MonitorCount - 1 do
  begin
    M := Screen.Monitors[I].BoundsRect;
    if (R.Left < M.Right) and (R.Right > M.Left) and
       (R.Top < M.Bottom) and (R.Bottom > M.Top) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TMainForm.ApplySavedWindow;
var
  R: TRect;
begin
  FNormalBounds := BoundsRect;
  FWasMaximized := False;
  if not FSettings.HasWindow then
    Exit;
  R := Rect(FSettings.WindowLeft, FSettings.WindowTop,
    FSettings.WindowLeft + FSettings.WindowWidth,
    FSettings.WindowTop + FSettings.WindowHeight);
  if not IntersectsAnyMonitor(R) then
    Exit;
  Position := poDesigned;
  SetBounds(R.Left, R.Top, FSettings.WindowWidth, FSettings.WindowHeight);
  FNormalBounds := BoundsRect;
  FWasMaximized := FSettings.WindowMaximized;
  if FSettings.WindowMaximized then
    WindowState := wsMaximized;
end;

procedure TMainForm.CaptureWindowSettings;
var
  R: TRect;
begin
  if (WindowState = wsNormal) and FTrackBounds then
    R := BoundsRect
  else
    R := FNormalBounds;
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
    Exit;
  FSettings.WindowLeft := R.Left;
  FSettings.WindowTop := R.Top;
  FSettings.WindowWidth := R.Right - R.Left;
  FSettings.WindowHeight := R.Bottom - R.Top;
  FSettings.WindowMaximized := FWasMaximized or (WindowState = wsMaximized);
  FSettings.HasWindow := True;
end;

procedure TMainForm.PersistSettings;
begin
  CaptureWindowSettings;
  SaveSettings(FSettings);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if not FTrackBounds then
    Exit;
  if WindowState = wsNormal then
  begin
    FNormalBounds := BoundsRect;
    FWasMaximized := False;
  end
  else if WindowState = wsMaximized then
    FWasMaximized := True;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Loaded: Boolean;
begin
  FDoc := TNysDocument.Create;
  FDoc.LineEnding := sLineBreak;
  FCaretLine := 1;
  FCaretCol := 1;
  FTopLine := 1;
  if not TryLoadSettings(FSettings) then
  begin
    FSettings := DefaultSettings;
    if WindowsAppsUseDark then
      FSettings.Theme := tkDark;
    SaveSettings(FSettings);
  end;

  ApplySavedWindow;
  CreateViewAndEditor;
  Bar.Top := 0;
  ApplyChrome;
  DragAcceptFiles(Handle, True);

  Loaded := False;
  if (ParamCount >= 1) and FileExists(ParamStr(1)) then
    try
      LoadFile(ExpandFileName(ParamStr(1)));
      Loaded := True;
    except
      on E: Exception do
        Application.ShowException(E);
    end;
  if not Loaded then
  begin
    FLoading := True;
    try
      FEditor.Text := '';
    finally
      FLoading := False;
    end;
    FDoc.MarkSaved('');
    NoteDiskState;
    UpdateStatus;
  end;
  FWatch := TTimer.Create(Self);
  FWatch.Interval := 1000;
  FWatch.OnTimer := WatchTick;
  FTrackBounds := True;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  { the rendered copies of the document do not stay in %TEMP% }
  if (FPreviewFile <> '') and FileExists(FPreviewFile) then
    System.SysUtils.DeleteFile(FPreviewFile);
  if (FDeleteAfterNav <> '') and FileExists(FDeleteAfterNav) then
    System.SysUtils.DeleteFile(FDeleteAfterNav);
  FDoc.Free;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmDiscard;
  if CanClose then
    PersistSettings;
end;

{ Which modifier keys are down. When the page has the focus the keys went to
  the WebView2 process, and GetKeyState in this thread does not see them,
  so the hardware state is asked as well. }
function ModifiersDown: TShiftState;

  function Down(Key: Integer): Boolean;
  begin
    Result := (GetKeyState(Key) < 0) or (GetAsyncKeyState(Key) < 0);
  end;

begin
  Result := [];
  if Down(VK_CONTROL) then
    Include(Result, ssCtrl);
  if Down(VK_SHIFT) then
    Include(Result, ssShift);
  if Down(VK_MENU) then
    Include(Result, ssAlt);
end;

{ Shortcuts go through IsShortCut, not KeyDown: the VCL asks it for keys
  typed in the editor, and TEdgeBrowser asks it for keys typed in the page.
  KeyPreview never sees the keys the page has.

  The action runs from the message queue, after this call has returned.
  When the key came from the page we are inside a WebView2 event, and
  TEdgeBrowser.ExecuteScript waits for its answer, which cannot arrive
  until that event is over. Running the action here would wait forever. }
function TMainForm.IsShortCut(var Message: TWMKey): Boolean;
var
  Shift: TShiftState;
  Action: Integer;
begin
  Shift := ModifiersDown;
  Action := 0;
  if (Shift = [ssCtrl]) and (Message.CharCode = Ord('S')) then
    Action := 1
  else if (Shift = [ssCtrl, ssShift]) and (Message.CharCode = Ord('S')) then
    Action := 2
  else if (Shift = [ssCtrl]) and (Message.CharCode = Ord('O')) then
    Action := 3
  else if (Shift = [ssCtrl]) and (Message.CharCode = Ord('E')) then
    Action := 4;
  if Action = 0 then
  begin
    Result := inherited IsShortCut(Message);
    Exit;
  end;
  Result := True;
  TThread.ForceQueue(nil,
    procedure
    begin
      case Action of
        1: SaveClick(nil);
        2: SaveAs;
        3: OpenClick(nil);
        4: ToggleMode;
      end;
    end);
end;

procedure TMainForm.WMDropFiles(var Msg: TWMDropFiles);
var
  Name: array[0..MAX_PATH] of Char;
begin
  if DragQueryFile(Msg.Drop, 0, Name, MAX_PATH) > 0 then
  begin
    if ConfirmDiscard then
      LoadFile(Name);
  end;
  DragFinish(Msg.Drop);
end;

end.
