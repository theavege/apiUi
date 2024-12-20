program nsSql;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazrichview , nsSqlMainUnit , QueryScanner , virtualtreeview_package ,
  AboutUnit, jsnAnalyser, yamlAnalyser, indylaz, FrameViewer09
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application .CreateForm (TMainForm , MainForm );
  Application.Run;
end.

