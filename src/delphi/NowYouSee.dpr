program NowYouSee;

uses
  Vcl.Forms,
  Nys.Main in 'Nys.Main.pas' {MainForm},
  Nys.Settings in '..\core\Nys.Settings.pas',
  Nys.Document in '..\core\Nys.Document.pas',
  Nys.EditCommands in '..\core\Nys.EditCommands.pas',
  Nys.Render in '..\core\Nys.Render.pas',
  Nys.Highlighter in 'Nys.Highlighter.pas',
  Nys.Chrome in 'Nys.Chrome.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'NowYouSee.md';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
