unit logChartzUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes , SysUtils , TASources , TASeries , TAGraph , CheckLst , Spin ,
  ExtCtrls , StdCtrls , FileUtil , Forms , Controls , Graphics , Dialogs ,
  ComCtrls , ActnList , TAChartListbox , TACustomSeries , TALegend ,
  FormIniFilez, Logz, Wsdlz;

type

  { TlogChartForm }

  TlogChartForm = class(TForm)
    CloseAction : TAction ;
    MainActionList : TActionList ;
    Chart: TChart;
    ChartListbox: TChartListbox;
    ColorDialog: TColorDialog;
    MainImageList : TImageList ;
    ListboxPanel: TPanel;
    Splitter: TSplitter;
    ToolBar1 : TToolBar ;
    ToolButton1 : TToolButton ;
    procedure CloseActionExecute (Sender : TObject );
    procedure BtnAddPointClick (Sender : TObject );
    procedure BtnDeleteSeriesClick(Sender: TObject);
    procedure BtnToggleCOSClick(Sender: TObject);
    procedure BtnToggleChartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ChartListboxSeriesIconDblClick(Sender: TObject; Index: Integer);
    procedure FormDestroy (Sender : TObject );
    procedure FormShow (Sender : TObject );
  private
    fChanged : Boolean ;
    IniFile: TFormIniFile;
    procedure CreateData;
  public
    Operations: TWsdlOperations;
    Logs: TLogList;
    property Changed: Boolean read fChanged;
  end;

var
  logChartForm: TlogChartForm;

implementation

{$R *.lfm}

uses
  TATypes;

{ TlogChartForm }

procedure TlogChartForm.CreateData;
const
  n = 100;
var
  x, f: Integer;
  ser: TLineSeries;
begin
  for x := 0 to Operations.Count - 1 do
  begin
    ser := TLineSeries.Create(Chart);
    ser.SeriesColor := rgbToColor(Random(255), Random(255), Random(255));
    ser.Title := Operations.Operations[x].reqTagName;
    ser.Pointer.Brush.Color := ser.SeriesColor;
{
    ser.ShowPoints := Odd(i);
    ser.Pointer.Style :=
      TSeriesPointerStyle(Random(Ord(High(TSeriesPointerStyle))));
}
    Chart.AddSeries(ser);
  end;
  for x := 0 to Logs.Count - 1 do with Logs.LogItems[x] do
  begin
    if PassesFilter then
    begin
      if Assigned(Operation) then
      begin
        if Operations.Find(Operation.reqTagName, f) then
        begin
          ser := Chart.Series.Items[f] as TLineSeries;
          ser.AddXY(x, StrToFloatX(DurationAsString));
        end;
      end;
    end;
  end;
end;

procedure TlogChartForm.ChartListboxSeriesIconDblClick(Sender: TObject; Index: Integer);
begin
  if ChartListbox.Series[Index] is TLineSeries then
    with ColorDialog do begin
      Color := TLineSeries(ChartListbox.Series[Index]).SeriesColor;
      if Execute then with TLineSeries(ChartListbox.Series[Index]) do
      begin
        SeriesColor := Color;
        Pointer.Brush.Color := Color;
      end;
    end;
end;

procedure TlogChartForm .FormDestroy (Sender : TObject );
begin
  IniFile.Save;
  IniFile.Free;
end;

procedure TlogChartForm .FormShow (Sender : TObject );
begin
  CreateData;
end;

procedure TlogChartForm.FormCreate(Sender: TObject);
begin
  IniFile := TFormIniFile.Create (Self);
  IniFile.Restore;
end;

procedure TlogChartForm .BtnAddPointClick (Sender : TObject );
begin

end;

procedure TlogChartForm .CloseActionExecute (Sender : TObject );
begin
  Close;
end;

procedure TlogChartForm .BtnDeleteSeriesClick (Sender : TObject );
begin

end;

procedure TlogChartForm .BtnToggleCOSClick (Sender : TObject );
begin

end;

procedure TlogChartForm .BtnToggleChartClick (Sender : TObject );
begin

end;

end.

