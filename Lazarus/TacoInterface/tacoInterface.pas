unit tacoInterface;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType,
{$ENDIF}
  Classes
   , Controls
   , StrUtils
   , Xmlz
   , IdTCPClient
   , IdSync
   , ExtCtrls
   ;

type
  TRtReturnType = (rtUndefined, rtReply, rtError);
  TTacoInterface = class;
  TOnHaveTacoMessage = procedure ( aTacoInterface: TTacoInterface
                                 ; aClientId, aMessage: AnsiString
                                 ) of Object;
  TOnNeedTacoInterfaceData = procedure (aTacoInterface: TTacoInterface) of Object;

  { TTacoInterface }

  TTacoInterface = class
  private
    fAuthorized: Boolean;
    fAuthorisation : String ;
    fClient: TIdTCPClient;
    fPingPongTimer: TTimer;
    fHost: String;
    fNeedHostData : TOnNeedTacoInterfaceData ;
    fPort: Integer;
    fOnHaveTacoMessage: TOnHaveTacoMessage;
    fReqTime: TDateTime;
    fRspTime: TDateTime;
    fTacoReply: AnsiString;
    fReady: Boolean;
    fReturnType: TRtReturnType;
    fReply: AnsiString;
    procedure OnPingPongTimer (Sender: TObject);
    procedure clientConnected(Sender: TObject);
    procedure clientDisconnected(Sender: TObject);
    procedure setAuthorized (AValue : boolean );
    procedure syncDoAuthorize;
    procedure doAuthorize;
    function tacoString (aString: AnsiString): AnsiString;
    function tacoRequest (aRequest: AnsiString; aConfig: TXml): AnsiString;
    function tacoCopy (aString: AnsiString; var x: Integer): AnsiString;
    procedure EvaluateResponse;
  public
    UserName, Password: AnsiString;
    property Host: String read fHost write fHost;
    property Port: Integer read fPort write fPort;
    property Authorized: boolean read fAuthorized write setAuthorized;
    property Authorisation: String read fAuthorisation write fAuthorisation;
    property ReturnType: TRtReturnType read fReturnType;
    property NeedHostData: TOnNeedTacoInterfaceData write fNeedHostData;
    procedure doTerminate;
    procedure Connect;
    procedure Disconnect;
    constructor Create(Owner: TComponent; aOnHaveTacoMessage: TOnHaveTacoMessage);
    constructor CreateFromXml(aXml: TXml; aOnHaveTacoMessage: TOnHaveTacoMessage);
    destructor Destroy; override;
    function RequestReply ( aRequest: AnsiString
                          ; aTimeOut: Integer
                          ; aConfigAsXml: TXml
                          ): AnsiString; Virtual;
    function AsXml: TXml;
  published
    property RequestTimestamp: TDateTime read fReqTime;
    property ReplyTimestamp: TDateTime read fRspTime;
  end;

implementation

uses SysUtils
   ;
{ TTacoInterface }

function TTacoInterface.AsXml: TXml;
begin
  result := nil;
end;

procedure TTacoInterface.Connect;
begin

end;

constructor TTacoInterface.Create(Owner: TComponent;
  aOnHaveTacoMessage: TOnHaveTacoMessage);
begin
  fOnHaveTacoMessage := aOnHaveTacoMessage;
  fClient := TIdTCPClient.Create(nil);
  fClient.OnDisconnected := clientDisconnected;
  fPingPongTimer := TTimer.Create(nil);
  fPingPongTimer.OnTimer := OnPingPongTimer;
  fPingPongTimer.Enabled := False;
  fPingPongTimer.Interval := 5 * 1000;
  Authorized := False;
end;

constructor TTacoInterface.CreateFromXml(aXml: TXml;
  aOnHaveTacoMessage: TOnHaveTacoMessage);
begin

end;

destructor TTacoInterface.Destroy;
begin
  fClient.Disconnect;
  fClient.Free;
  fPingPongTimer.Free;
  inherited;
end;

procedure TTacoInterface.Disconnect;
begin
  fClient.Disconnect;
end;

procedure TTacoInterface.doTerminate;
begin

end;


procedure TTacoInterface.EvaluateResponse;
var
  x: Integer;
begin
  fReply := '';
  if fTacoReply = '<PONG><END-OF-DATA>' then
  begin
    fReturnType := rtReply;
    Exit;
  end;
  if fTacoReply = '<AUTHORISE-CLOSED><END-OF-DATA>' then
  begin
    fClient.Disconnect;
    Authorized := False;
    Raise Exception.Create('Authorisation failed.' + LineEnding +
        'For security reasons, the server has stopped running;' + LineEnding +
        'Restart the server and supply the new authorisation string');
  end;
  if AnsiStartsStr ('<REPLY>', fTacoReply) then
  begin
    fReturnType := rtReply;
    x := 8;
    fReply := tacoCopy(fTacoReply, x);
    Exit;
  end;
  if AnsiStartsStr ('<ERR>', fTacoReply) then
  begin
    fReturnType := rtError;
    x := 6;
    fReply := tacoCopy(fTacoReply, x);
    raise Exception.Create('Taco server error: ' + fReply);
  end;
  raise Exception.Create('tacoInterface: Illegal Taco response: ' + fTacoReply);
end;

function TTacoInterface.RequestReply(aRequest: AnsiString; aTimeOut: Integer;
  aConfigAsXml: TXml): AnsiString;
var
  xHost: String;
  xPort: Integer;
begin
  doAuthorize;
  if not Authorized then
    Exit;
  fPingPongTimer.Enabled := False;
  try
    fReturnType := rtUndefined;
    fReady := False;
    fTacoReply := '';
    fClient.IOHandler.WriteLn(tacoRequest(aRequest, aConfigAsXml));
    while not fReady do
    begin
      fTacoReply := fTacoReply + fClient.IOHandler.ReadString(1);
      fReady := (system.Length(fTacoReply) > 12)
            and (Copy (fTacoReply, Length (fTacoReply) - 12, 13) = '<END-OF-DATA>')
              ;
    end;
    EvaluateResponse;
    result := fReply;
  finally
    fPingPongTimer.Enabled := Authorized;
  end;
end;

function TTacoInterface.tacoCopy(aString: AnsiString;
  var x: Integer): AnsiString;
var
  L, S: Integer;
begin
  if aString[x] <> '<' then
    raise Exception.Create('tacoInterface: Illegal Taco response: ' + aString);
  L := x;
  while (x <= Length (aString))
  and (aString [x] <> '>') do
    Inc (x);
  if x > Length (aString) then
    raise Exception.Create('tacoInterface: Illegal Taco response: ' + aString);
  S := StrToInt (Copy (aString, L + 1, x - L - 1));
  result := Copy (aString, x + 1, S);
  x := x + 1 + S;
end;

function TTacoInterface.tacoRequest(aRequest: AnsiString; aConfig: TXml): AnsiString;
var
  xXml, mqXml: TXml;
  s: String;
  x: Integer;
begin
  result := '';
  xXml := aConfig.FindUQXml('Taco.messageBroker.Pathsend');
  if Assigned (xXml)
  and (xXml.Checked) then
  begin
    result := result + '<SEND-S';
    s := xXml.Items.XmlValueByTag['TMF'];
    if s = 'Commit' then
      result := result + 'T';
    if s = 'Abort' then
      result := result + 'A';
    result := result + '>';
    result := result + tacoString (xXml.Items.XmlValueByTag['Monitor'])
                     + tacoString (xXml.Items.XmlValueByTag['Server'])
                     ;
 {}
  end
  else
  begin
    xXml := aConfig.FindUQXml('Taco.messageBroker.Mq');
    if Assigned (xXml)
    and xXml.Checked then
    begin
      mqXml := nil;
      for x := 0 to xXml.Items.Count - 1 do
        if xXml.Items.XmlItems[x].Checked then
          mqXml := xXml.Items.XmlItems[x];
      if not Assigned (mqXml) then
        raise Exception.Create('tacoInterface: Illegal MQ config');
      result := result
              + '<MQSEND>'
              + tacoString (mqXml.Items.XmlValueByTag['Manager'])
              + tacoString (mqXml.Items.XmlValueByTag['GetQueue'])
              + tacoString (mqXml.Items.XmlValueByTag['PutQueue'])
              + tacoString (mqXml.Items.XmlValueByTag['ReplyToQueue'])
              + tacoString (mqXml.Items.XmlValueByTag['TimeOut'])
              ;
    end;
  end;
  result := result + tacoString (aRequest) + '<END-OF-DATA>';
end;

procedure TTacoInterface .OnPingPongTimer (Sender : TObject );
begin
  if not Authorized then
    Exit;
  fReady := False;
  fTacoReply := '';
  fClient.IOHandler.WriteLn ( '<PING><END-OF-DATA>');
  while not fReady do
  begin
    fTacoReply := fTacoReply + fClient.IOHandler.ReadString(1);
    fReady := (system.Length(fTacoReply) > 12)
          and (Copy (fTacoReply, Length (fTacoReply) - 12, 13) = '<END-OF-DATA>')
            ;
  end;
  EvaluateResponse;
end;

procedure TTacoInterface .clientConnected (Sender : TObject );
begin
  Authorized := False;
end;

procedure TTacoInterface .clientDisconnected (Sender : TObject );
begin
  Authorized := False;
end;

procedure TTacoInterface .setAuthorized (AValue : boolean );
begin
  if fAuthorized = AValue then Exit ;
  fAuthorized := AValue ;
  fPingPongTimer.Enabled := AValue;
end;

procedure TTacoInterface .syncDoAuthorize ;
begin
  fNeedHostData(Self);
end;

procedure TTacoInterface .doAuthorize ;
begin
  if Authorized then
    Exit;
  if not Assigned (fNeedHostData) then
    raise Exception.Create('TTacoInterface: no OnNeedHostData assigned');
  Authorisation := '';
  fClient.Disconnect;
  with TIdSync.Create do
  begin
    try
      SynchronizeMethod (syncDoAuthorize);
    finally
      free;
    end;
  end;
  if Authorisation = '' then
    raise Exception.Create('TacoInterface: aborted due to user action');
  fClient.Host := Host;
  fClient.Port := Port;
  fClient.Connect;
  fReady := False;
  fTacoReply := '';
  fClient.IOHandler.WriteLn ( '<AUTHORISE>'
                            + tacoString(Authorisation)
                            + tacoString(UserName)
                            + '<END-OF-DATA>'
                            );
  while not fReady do
  begin
    fTacoReply := fTacoReply + fClient.IOHandler.ReadString(1);
    fReady := (system.Length(fTacoReply) > 12)
          and (Copy (fTacoReply, Length (fTacoReply) - 12, 13) = '<END-OF-DATA>')
            ;
  end;
  if fTacoReply = '<NOT-AUTHORISED><END-OF-DATA>' then
  begin
    Authorized := False;
    Raise Exception.Create('Not authorised');
  end;
  if fTacoReply = '<AUTHORISE-FAILED><END-OF-DATA>' then
  begin
    Authorized := False;
    Raise Exception.Create(
      'Authorisation failed; Please supply correct authorisation string');
  end;
  if fTacoReply = '<AUTHORISE-CLOSED><END-OF-DATA>' then
  begin
    Authorized := False;
    Raise Exception.Create('Authorisation failed.' + LineEnding +
        'For security reasons, the server has stopped running;' + LineEnding +
        'Restart the server and supply the new authorisation string');
  end;
  if fTacoReply = '<AUTHORISE-SUCCESSFUL><END-OF-DATA>' then
  begin
    Authorized := True;
    exit;
  end;
end;

function TTacoInterface.tacoString(aString: AnsiString): AnsiString;
begin
  result := '<'
          + IntToStr (Length (aString))
          + '>'
          + aString
          ;
end;

end.
