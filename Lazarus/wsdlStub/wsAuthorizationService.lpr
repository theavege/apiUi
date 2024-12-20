Program wsAuthorizationService;

Uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
  CThreads,
{$ENDIF}{$ENDIF}
  DaemonApp , lazdaemonapp , HashUtilz ;

begin
  Application.Initialize;
  Application.Run;
end.
