{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit yamlTestUnit ;


interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, VirtualTrees, yamlAnalyser, YAMLSCANNER, YAMLPARSER,
  ParserClasses, CustScanner, Xmlz;

const InternalStackSize = 256;
const InitState = 2; {taken from Scanner.pas}

type

  vtColumnType = (vtToken, vtValue, vtName, vtOffset, vtLength, vtFB, vtText);
  { TForm1 }

  TForm1 = class(TForm )
    Button1: TButton;
    Button2: TButton;
    Panel1: TPanel;
    SynEdit : TSynEdit ;
    TreeView : TVirtualStringTree ;
    procedure Button1Click (Sender : TObject );
    procedure Button2Click (Sender : TObject );
    procedure FormCreate (Sender : TObject );
    procedure FormDestroy (Sender : TObject );
    procedure FormShow (Sender : TObject );
    procedure SynEditChange (Sender : TObject );
    procedure TreeViewFocusChanged (Sender : TBaseVirtualTree ;
      Node : PVirtualNode ; Column : TColumnIndex );
    procedure TreeViewGetText (Sender : TBaseVirtualTree ;
      Node : PVirtualNode ; Column : TColumnIndex ; TextType : TVSTTextType ;
      var CellText : String );
  private
    procedure fOnAnalyserError ( Sender:TObject
                               ; LineNumber: Integer
                               ; ColumnNumber: Integer
                               ; Offset: Integer
                               ; TokenString: String
                               ; Data: String
                               );
    procedure PopulateTreeview;
    procedure ScannerNeedsData(Sender: TObject; var MoreData: Boolean; var Data: String);
  public
    LineNumber: Integer;
    analyser: TyamlAnalyser;
  end;

var
  Form1 : TForm1 ;

implementation

uses xmlUtilz
   ;

{$R *.lfm}

{ TForm1 }
type
  PBindTreeRec = ^TBindTreeRec;

  TBindTreeRec = record
    lex: YYSType;

  end;

procedure TForm1 .FormShow (Sender : TObject );
begin
  TreeView.Clear;
  LineNumber := 0;
  if not Assigned (analyser.Xml) then
    analyser.Xml := TXml.Create;
  analyser.Xml.Items.Clear;
  analyser.StartState := InitState;
  analyser.OnNeedData := ScannerNeedsData;
  analyser.Prepare;
  analyser.Execute;
  PopulateTreeview;
  TreeView.SetFocus;
  TreeView.FocusedNode := TreeView.GetFirst;
end;

procedure TForm1.SynEditChange(Sender : TObject );
begin

end;

procedure TForm1 .TreeViewFocusChanged (Sender : TBaseVirtualTree ;
  Node : PVirtualNode ; Column : TColumnIndex );
var
  Lex: YYSType;
  Data: PBindTreeRec;
begin
  Data := TreeView.GetNodeData(Node);
  Lex := Data.lex;
  SynEdit.SelStart:=lex.Offset;
  SynEdit.SelEnd := lex.Offset + Length (lex.TokenString);
end;

procedure TForm1 .TreeViewGetText (Sender : TBaseVirtualTree ;
  Node : PVirtualNode ; Column : TColumnIndex ; TextType : TVSTTextType ;
  var CellText : String );
var
  Lex: YYSType;
  Data: PBindTreeRec;
begin
  CellText := '';
  Data := TreeView.GetNodeData(Node);
  if Assigned (Data) then
  begin
    Lex := Data.lex;
    case vtColumnType (Column) of
      vtToken: CellText := IntToStr (Lex.Token);
      vtValue: CellText := IntToStr (Lex.yy.yyInteger);
      vtName: CellText := analyser.TokenNames [Lex.Token];
      vtOffset: CellText := IntToStr(Lex.Offset);
      vtLength: CellText := IntToStr(Length (Lex.TokenString));
      vtFB: If Length (Lex.TokenString) > 0 then CellText := IntToStr(Ord (Lex.TokenString[1]));
      vtText: CellText := Lex.yyString;
    end;
  end;
end;

procedure TForm1 .fOnAnalyserError (Sender : TObject ; LineNumber : Integer ;
  ColumnNumber : Integer ; Offset : Integer ; TokenString : String ;
  Data : String );
begin
  ShowMessage (Format( 'Error at %d %d %d: %s'
                     , [         LineNumber
                       ,            ColumnNumber
                       ,               Offset
                       ,                   TokenString
                       ]
                     )
              );
end;

procedure TForm1 .PopulateTreeview;
var
  l: YYSType;
  ChildNode: PVirtualNode;
  Data: PBindTreeRec;
begin
  l := analyser.ScannedItems;
  while Assigned(l) do
  begin
    ChildNode := TreeView.AddChild(nil);
    Data := TreeView.GetNodeData(ChildNode);
    Data.lex := l;
    l := l.NextToken;
  end;
end;

procedure TForm1 .ScannerNeedsData (Sender : TObject ; var MoreData : Boolean ;
  var Data : String );
begin
  if LineNumber >= SynEdit.Lines.Count then
    MoreData := False
  else
  begin
    Data := SynEdit.Lines.Strings[LineNumber];
    Inc(LineNumber);
  end;
end;

procedure TForm1 .FormCreate (Sender : TObject );
begin
  analyser := TyamlAnalyser.Create(nil);
  analyser.OnError := fOnAnalyserError;
  TreeView.NodeDataSize := SizeOf(TBindTreeRec);
end;

procedure TForm1 .Button1Click (Sender : TObject );
begin
  FormShow(nil);
end;

procedure TForm1 .Button2Click (Sender : TObject );
begin
  ShowXml ('yaml', analyser.Xml);
end;

procedure TForm1 .FormDestroy (Sender : TObject );
begin
  if Assigned (analyser.Xml) then
    analyser.Xml.Free;
  analyser.Free;
end;

end.

