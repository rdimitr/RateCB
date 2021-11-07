unit MainUnitRateCB;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.Grids, System.ImageList, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  Vcl.Samples.Gauges, VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs,
  VCLTee.Chart, VCLTee.Series, REST.Types, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, XMLIntf, XMLDoc, System.Math, Vcl.Imaging.jpeg;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    MainCurrTab: TTabSheet;
    AllCurrTab: TTabSheet;
    DynDollTab: TTabSheet;
    DateTimePicker1: TDateTimePicker;
    DateTimePicker2: TDateTimePicker;
    RefreshBitBtn: TBitBtn;
    CloseBitBtn: TBitBtn;
    AllStringGrid: TStringGrid;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    CodeUSLabel: TLabel;
    AbbrUSLabel: TLabel;
    NomUSLabel: TLabel;
    RateUSLabel: TLabel;
    CodeEurLabel: TLabel;
    AbbrEurLabel: TLabel;
    NomEurLabel: TLabel;
    RateEurLabel: TLabel;
    CodePndLabel: TLabel;
    AbbrPndLabel: TLabel;
    NomPndLabel: TLabel;
    RatePndLabel: TLabel;
    CodeYLabel: TLabel;
    AbbrYLabel: TLabel;
    NomYLabel: TLabel;
    RateYLabel: TLabel;
    DynChart: TChart;
    Series1: TFastLineSeries;
    Date1Label: TLabel;
    Date2Label: TLabel;
    RESTResponse1: TRESTResponse;
    RESTRequest1: TRESTRequest;
    RESTClient1: TRESTClient;
    Bevel1: TBevel;
    Bevel2: TBevel;
    RESTClient2: TRESTClient;
    RESTRequest2: TRESTRequest;
    RESTResponse2: TRESTResponse;
    procedure CloseBitBtnClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AllStringGridFixedCellClick(Sender: TObject; ACol, ARow: Integer);
    procedure RefreshBitBtnClick(Sender: TObject);
  private
    { Private declarations }
    sortFlagsArray: array[0..3] of integer;
    procedure GetRateByDate(d: TDateTime);
    procedure GetDynamicByDate(d1, d2: TDateTime);
    procedure AddToGrid(i: integer; col0, col1, col2, col3, col4: string);
    procedure InitChart;
    procedure AddToChart(f: real; txtLabel: string);
    procedure SortGrid(Column: integer);
  public
    { Public declarations }
  end;



var
  Form1: TForm1;

const
  NO_ORDER   = 0;
  ASC_ORDER  = 1;
  DESC_ORDER = 2;

implementation

{$R *.dfm}

function CompareInteger(x1, x2: integer): integer;
begin
  if (x1>x2) then Result:=1 else if (x1<x2) then Result:=-1 else Result:=0
end;


procedure TForm1.AllStringGridFixedCellClick(Sender: TObject; ACol,
  ARow: Integer);
var sortCol: integer;
begin
     if ARow = 0 then begin
        sortCol:=ACol;
        SortGrid(sortCol);
     end;
end;


procedure TForm1.CloseBitBtnClick(Sender: TObject);
begin
     Close;
end;


procedure TForm1.AddToGrid(i: integer; col0, col1, col2, col3, col4: string);
var currRow: integer;
begin
    with AllStringGrid do begin
      RowCount:=i+2;
      currRow:=i+1;
      Cells[0,currRow]:=col0;
      Cells[1,currRow]:=col1;
      Cells[2,currRow]:=col2;
      Cells[3,currRow]:=col3;
      Cells[4,currRow]:=col4;

      case StrToInt(col0) of
           840: begin
                     CodeUSLabel.Caption:='Код: ' + col0; AbbrUSLabel.Caption:='Аббревиатура: ' + col1;
                     NomUSLabel.Caption:=col2 + ' ' + col3;
                     RateUSLabel.Caption:=FloatToStr(SimpleRoundTo(StrToFLoat(col4), -2)) + ' руб';
                end;
           978: begin
                     CodeEurLabel.Caption:='Код: ' + col0; AbbrEurLabel.Caption:='Аббревиатура: ' + col1;
                     NomEurLabel.Caption:=col2 + ' ' + col3;
                     RateEurLabel.Caption:=FloatToStr(SimpleRoundTo(StrToFLoat(col4), -2)) + ' руб';
                end;
           826: begin
                     CodePndLabel.Caption:='Код: ' + col0; AbbrPndLabel.Caption:='Аббревиатура: ' + col1;
                     NomPndLabel.Caption:=col2 + ' ' + Copy(col3,1,15);
                     RatePndLabel.Caption:=FloatToStr(SimpleRoundTo(StrToFLoat(col4), -2)) + ' руб';
                end;
           392: begin
                     CodeYLabel.Caption:='Код: ' + col0; AbbrYLabel.Caption:='Аббревиатура: ' + col1;
                     NomYLabel.Caption:=col2 + ' ' + col3;
                     RateYLabel.Caption:=FloatToStr(SimpleRoundTo(StrToFLoat(col4), -2)) + ' руб';
                end;
      end;
    end;
end;


procedure TForm1.SortGrid(Column: integer);
var
  i, j: integer;
  tmpRow: TStringList;
  resCompare: integer;
begin
  if AllStringGrid.RowCount < 3 then exit;

  if (sortFlagsArray[Column] =  NO_ORDER) or (sortFlagsArray[Column] =  DESC_ORDER) then
     sortFlagsArray[Column]:=ASC_ORDER
  else
     sortFlagsArray[Column]:=DESC_ORDER;

  tmpRow:= TStringList.Create;
  try
    for i:=1 to AllStringGrid.RowCount-1 do begin    //i:=0
      for j:=i+1 to AllStringGrid.RowCount-1 do begin

        if Column in [1,3] then
           resCompare:=AnsiCompareStr(AllStringGrid.Cells[Column, i], AllStringGrid.Cells[Column, j])
        else if Column in [0,2] then
                resCompare:=CompareInteger(StrToInt(AllStringGrid.Cells[Column, i]),
                                           StrToInt(AllStringGrid.Cells[Column, j]));

        if sortFlagsArray[Column]=DESC_ORDER then resCompare:=-resCompare;

        if resCompare>0 then
          begin
              tmpRow.Assign(AllStringGrid.Rows[i]);
              AllStringGrid.Rows[i]:=AllStringGrid.Rows[j];
              AllStringGrid.Rows[j]:=tmpRow;
          end;
      end;
    end;
  finally
    tmpRow.Free;
  end;
end;


procedure TForm1.GetRateByDate(d: TDateTime);
var sValDate: string;
    formatSettings : TFormatSettings;
    CrbDoc: IXMLDocument;
    RootNode: IXMLNode;
    i: integer;
begin
    formatSettings:=TFormatSettings.Create(LOCALE_SYSTEM_DEFAULT);
    formatSettings.DateSeparator:='/';
    sValDate:=DateToStr(d, formatSettings);

    RESTClient1.Params[0].Value:=sValDate;
    RESTRequest1.Params[0].Value:=sValDate;
    RESTRequest1.Execute();

    CrbDoc:=TXMLDocument.Create(nil);
    CrbDoc.LoadFromXML(RESTResponse1.Content);
    CrbDoc.Active:=TRUE;

    AllStringGrid.RowCount:=2;
    RootNode := CrbDoc.DocumentElement;
    for i := 0 to RootNode.ChildNodes.Count - 1 do begin
        AddToGrid(i,
                  RootNode.ChildNodes[i].ChildNodes['NumCode'].Text,
                  RootNode.ChildNodes[i].ChildNodes['CharCode'].Text,
                  RootNode.ChildNodes[i].ChildNodes['Nominal'].Text,
                  RootNode.ChildNodes[i].ChildNodes['Name'].Text,
                  RootNode.ChildNodes[i].ChildNodes['Value'].Text);
    end;
    SortGrid(3);
end;


procedure TForm1.GetDynamicByDate(d1, d2: TDateTime);
var formatSettings : TFormatSettings;
    DynDoc: IXMLDocument;
    RootNode: IXMLNode;
    i: integer;
begin
    InitChart;
    formatSettings:=TFormatSettings.Create(LOCALE_SYSTEM_DEFAULT);
    formatSettings.DateSeparator:='/';

    RESTClient2.Params[0].Value:=DateToStr(DateTimePicker1.Date, formatSettings);
    RESTRequest2.Params[0].Value:=DateToStr(DateTimePicker1.Date, formatSettings);
    RESTClient2.Params[1].Value:=DateToStr(DateTimePicker2.Date, formatSettings);
    RESTRequest2.Params[1].Value:=DateToStr(DateTimePicker2.Date, formatSettings);
    RESTRequest2.Execute();

    DynDoc:=TXMLDocument.Create(nil);
    DynDoc.LoadFromXML(RESTResponse2.Content);
    DynDoc.Active:=TRUE;

    RootNode := DynDoc.DocumentElement;
    for i := 0 to RootNode.ChildNodes.Count - 1 do begin
        AddToChart( StrToFloat(RootNode.ChildNodes[i].ChildNodes['Value'].Text),
                    RootNode.ChildNodes[i].Attributes['Date'] );
    end;
end;

procedure TForm1.InitChart;
begin
   with DynChart do begin
        Series1.LinePen.Color:=clBlue;
        Title.Text.Clear;
        Title.Text.Add(DateToStr(DateTimePicker1.Date) + ' - ' + DateToStr(DateTimePicker2.Date));
        Series[0].Clear;
   end;
end;


procedure TForm1.AddToChart(f: real; txtLabel: string);
begin
        DynChart.Series[0].Add(f, txtLabel);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
   with AllStringGrid do begin
      Cells[0,0] := 'Код';
      Cells[1,0] := 'Аббр.';
      Cells[2,0] := 'Номинал';
      Cells[3,0] := 'Название валюты';
      Cells[4,0] := 'Курс (в руб)';
   end;

   DateTimePicker1.Date:=Date;
   DateTimePicker2.Date:=Date;
   GetRateByDate(Date);
end;


procedure TForm1.PageControl1Change(Sender: TObject);
begin
     if PageControl1.ActivePageIndex=2 then begin
        DateTimePicker2.Visible:=TRUE; Date2Label.Visible:=TRUE;
     end
     else begin
        DateTimePicker2.Visible:=FALSE; Date2Label.Visible:=FALSE;
     end;

end;

procedure TForm1.RefreshBitBtnClick(Sender: TObject);
begin
      GetRateByDate(DateTimePicker1.Date);

      if PageControl1.ActivePageIndex = 2 then begin
          GetDynamicByDate(DateTimePicker1.Date, DateTimePicker2.Date);
      end;
end;

end.
