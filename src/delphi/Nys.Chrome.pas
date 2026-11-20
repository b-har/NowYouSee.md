unit Nys.Chrome;

{ The look of the shell: the light and dark palettes, and how a toolbar
  button is drawn.

  TSpeedButton here is an interposer. The form file still says TSpeedButton,
  so the form opens in the IDE with no package installed. At runtime every
  speed button on a form that lists this unit after Vcl.Buttons is drawn by
  Paint below: a rounded face with a thin border, like the buttons in
  TrackMender. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Buttons;

type
  TNysPalette = record
    Dark: Boolean;
    { window and panels }
    Window: TColor;
    Panel: TColor;
    Border: TColor;
    Text: TColor;
    Muted: TColor;
    Dirty: TColor;
    { buttons }
    BtnFace: TColor;
    BtnBorder: TColor;
    BtnHotFace: TColor;
    BtnHotBorder: TColor;
    BtnDownFace: TColor;
    BtnOnFace: TColor;
    BtnOnBorder: TColor;
    BtnOffText: TColor;
    { editor }
    Editor: TColor;
    EditorText: TColor;
    ActiveLine: TColor;
    Gutter: TColor;
    Marker: TColor;
    CodeBack: TColor;
    Selection: TColor;
  end;

  TSpeedButton = class(Vcl.Buttons.TSpeedButton)
  private
    FHot: Boolean;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
  end;

function LightPalette: TNysPalette;
function DarkPalette: TNysPalette;

var
  { The palette the buttons paint with. The form sets it, then invalidates. }
  ChromePalette: TNysPalette;

implementation

uses
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ;

function LightPalette: TNysPalette;
begin
  Result.Dark := False;
  Result.Window := RGB(240, 240, 240);
  Result.Panel := RGB(246, 246, 246);
  Result.Border := RGB(204, 204, 204);
  Result.Text := RGB(27, 27, 27);
  Result.Muted := RGB(96, 96, 96);
  Result.Dirty := RGB(180, 83, 9);
  Result.BtnFace := RGB(253, 253, 253);
  Result.BtnBorder := RGB(204, 204, 204);
  Result.BtnHotFace := RGB(229, 241, 251);
  Result.BtnHotBorder := RGB(0, 120, 212);
  Result.BtnDownFace := RGB(204, 228, 247);
  Result.BtnOnFace := RGB(204, 228, 247);
  Result.BtnOnBorder := RGB(0, 120, 212);
  Result.BtnOffText := RGB(160, 160, 160);
  Result.Editor := RGB(255, 255, 255);
  Result.EditorText := RGB(0, 0, 0);
  Result.ActiveLine := RGB(245, 248, 252);
  Result.Gutter := RGB(246, 246, 246);
  Result.Marker := RGB(0, 84, 210);
  Result.CodeBack := RGB(236, 239, 243);
  Result.Selection := RGB(173, 214, 255);
end;

function DarkPalette: TNysPalette;
begin
  Result.Dark := True;
  Result.Window := RGB(32, 32, 32);
  Result.Panel := RGB(39, 39, 39);
  Result.Border := RGB(64, 64, 64);
  Result.Text := RGB(240, 240, 240);
  Result.Muted := RGB(166, 166, 166);
  Result.Dirty := RGB(240, 170, 90);
  Result.BtnFace := RGB(51, 51, 51);
  Result.BtnBorder := RGB(74, 74, 74);
  Result.BtnHotFace := RGB(60, 66, 74);
  Result.BtnHotBorder := RGB(76, 163, 240);
  Result.BtnDownFace := RGB(38, 66, 96);
  Result.BtnOnFace := RGB(38, 66, 96);
  Result.BtnOnBorder := RGB(76, 163, 240);
  Result.BtnOffText := RGB(112, 112, 112);
  Result.Editor := RGB(30, 30, 30);
  Result.EditorText := RGB(232, 232, 232);
  Result.ActiveLine := RGB(38, 40, 44);
  Result.Gutter := RGB(36, 36, 36);
  Result.Marker := RGB(108, 182, 255);
  Result.CodeBack := RGB(48, 50, 54);
  Result.Selection := RGB(38, 79, 120);
end;

function GdipColor(Color: TColor): Cardinal;
var
  C: Cardinal;
begin
  C := ColorToRGB(Color);
  Result := MakeColor(255, GetRValue(C), GetGValue(C), GetBValue(C));
end;

procedure RoundRectPath(Path: TGPGraphicsPath; X, Y, W, H, R: Single);
var
  D: Single;
begin
  D := R * 2;
  Path.AddArc(X, Y, D, D, 180, 90);
  Path.AddArc(X + W - D, Y, D, D, 270, 90);
  Path.AddArc(X + W - D, Y + H - D, D, D, 0, 90);
  Path.AddArc(X, Y + H - D, D, D, 90, 90);
  Path.CloseFigure;
end;

procedure TSpeedButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if not FHot then
  begin
    FHot := True;
    Invalidate;
  end;
end;

procedure TSpeedButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot then
  begin
    FHot := False;
    Invalidate;
  end;
end;

procedure TSpeedButton.Paint;
var
  G: TGPGraphics;
  Path: TGPGraphicsPath;
  Brush: TGPSolidBrush;
  Pen: TGPPen;
  Face, Edge, Ink: TColor;
  R: TRect;
  Text: string;
begin
  Face := ChromePalette.BtnFace;
  Edge := ChromePalette.BtnBorder;
  Ink := Font.Color;
  if not Enabled then
    Ink := ChromePalette.BtnOffText
  else if FState = bsDown then
  begin
    Face := ChromePalette.BtnDownFace;
    Edge := ChromePalette.BtnOnBorder;
  end
  else if Down then
  begin
    Face := ChromePalette.BtnOnFace;
    Edge := ChromePalette.BtnOnBorder;
  end
  else if FHot then
  begin
    Face := ChromePalette.BtnHotFace;
    Edge := ChromePalette.BtnHotBorder;
  end;

  G := TGPGraphics.Create(Canvas.Handle);
  Path := TGPGraphicsPath.Create;
  Brush := TGPSolidBrush.Create(GdipColor(Face));
  Pen := TGPPen.Create(GdipColor(Edge), 1);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    RoundRectPath(Path, 0.5, 0.5, Width - 1, Height - 1, MulDiv(4, CurrentPPI, 96));
    G.FillPath(Brush, Path);
    G.DrawPath(Pen, Path);
  finally
    Pen.Free;
    Brush.Free;
    Path.Free;
    G.Free;
  end;

  Text := Caption;
  R := ClientRect;
  Canvas.Font := Font;
  Canvas.Font.Color := Ink;
  Canvas.Brush.Style := bsClear;
  DrawText(Canvas.Handle, PChar(Text), Length(Text), R,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

end.
