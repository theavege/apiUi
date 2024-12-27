program apiUi;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, FrameViewer09, tachartlazaruspkg, abbrevia, virtualtreeview_package,
  FakeActiveX, IdExceptionCore, IdSync, IdStack, IdHTTP, WsdlStubMainUnit,
  snapshotz, exceptionUtils, htmlXmlUtilz, htmlreportz, junitunit,
  StringListListUnit, wiremockmapping, pegasimul8rmapping;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

