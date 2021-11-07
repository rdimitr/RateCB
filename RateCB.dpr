program RateCB;

uses
  Vcl.Forms,
  MainUnitRateCB in 'MainUnitRateCB.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
