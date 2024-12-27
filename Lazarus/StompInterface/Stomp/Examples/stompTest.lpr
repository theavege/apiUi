program stompTest;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, indylaz, IdSync, MainFormClient, Xmlz, IpmAnalyser, yamlAnalyser,
  jsnAnalyser, ParserClasses, igGlobals ;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application .CreateForm (TForm5 , Form5 );
  Application.Run;
end.

