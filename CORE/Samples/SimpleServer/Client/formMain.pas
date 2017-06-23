unit formMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, System.JSON,
  DB, memds, Grids, DBGrids, uRESTDWBase, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, uDWConsts, Vcl.ExtCtrls, Vcl.Imaging.pngimage;

type

  { TForm2 }

  TForm2 = class(TForm)
    btnPut: TButton;
    btnGet: TButton;
    btnPost: TButton;
    btnDelete: TButton;
    eHost: TEdit;
    ePort: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Label1: TLabel;
    Memo2: TMemo;
    Label2: TLabel;
    DBGrid1: TDBGrid;
    Label3: TLabel;
    DataSource1: TDataSource;
    btnIDHttpGetTest: TButton;
    btnIDHttpPostTeste: TButton;
    RESTClientPooler1: TRESTClientPooler;
    MemDataset1: TFDMemTable;
    Image1: TImage;
    Bevel1: TBevel;
    Label7: TLabel;
    edPasswordDW: TEdit;
    Label6: TLabel;
    edUserNameDW: TEdit;
    Label8: TLabel;
    procedure btnPutClick(Sender: TObject);
    procedure btnGetClick(Sender: TObject);
    procedure btnPostClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnIDHttpGetTestClick(Sender: TObject);
    procedure btnIDHttpPostTesteClick(Sender: TObject);
  private
    { Private declarations }
    procedure ListAlunos(Value : String);
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.ListAlunos(Value : String);
Var
 s, lResponse : String;
 JSonValue    : TJSonValue;
 I            : Integer;
begin
 Try
  Try
   lResponse := RESTClientPooler1.SendEvent('GetListaAlunos/' + Value);
  Except
   Exit;
  End;
  Memo1.Lines.Clear;
  Memo1.Lines.add(lResponse);
 Finally
  If lResponse <> '' Then
   Begin
    JSonValue   := TJsonObject.ParseJSONValue(lResponse);
    JSonValue   := (JsonValue as TJSONObject).Get('Alunos').JSONValue;
    MemDataset1.DisableControls;
    MemDataset1.Close;
    MemDataset1.CreateDataSet;
    MemDataset1.Open;
    If (JSONValue is TJSONArray) Then
     Begin
      For I := 0 To (JSONValue as TJSONArray).Count -1 Do
       Begin
        MemDataset1.Append;
        s := ((JSONValue as TJSONArray).Items[I] as TJSonObject).Get('NomeAluno').JSONValue.Value;
        MemDataset1.FieldByName('Alunos').AsString := s;
        MemDataset1.Post;
       End;
     End;
    MemDataset1.EnableControls;
    MemDataset1.First;
   End;
 end;
end;


procedure TForm2.btnGetClick(Sender: TObject);
Var
 lResponse,
 Aluno : String;
Begin
 RESTClientPooler1.Host     := eHost.Text;
 RESTClientPooler1.Port     := StrToInt(ePort.Text);
 RESTClientPooler1.UserName := edUserNameDW.Text;
 RESTClientPooler1.Password := edPasswordDW.Text;
 Aluno := InputBox('Rest Client', 'Nome do aluno', '');
 If Aluno <> '' Then
  Begin
   Try
    RESTClientPooler1.Host := eHost.Text;
    RESTClientPooler1.Port := StrToInt(ePort.Text);
    lResponse := RESTClientPooler1.SendEvent('ConsultaAluno/' + Aluno);
    Memo2.Lines.Clear;
    Memo2.Lines.add(lResponse);
    ListAlunos(Aluno);
   Except
   End;
  End;
End;

procedure TForm2.btnPostClick(Sender: TObject);
Var
 eventData,
 lResponse,
 Aluno,
 NomeNovo  : String;
 RBody     : TStringList;
 SendEvent : TSendEvent;
Begin
 RESTClientPooler1.Host     := eHost.Text;
 RESTClientPooler1.Port     := StrToInt(ePort.Text);
 RESTClientPooler1.UserName := edUserNameDW.Text;
 RESTClientPooler1.Password := edPasswordDW.Text;
 RBody := TStringList.Create;
 RBody.Add('json');
 Aluno := InputBox('Rest Client', 'Nome do aluno', '');
 If Aluno <> '' Then
  Begin
   NomeNovo := InputBox('Rest Client', 'Alterar Nome para', '');
   If NomeNovo <> '' Then
    Begin
     Try
      RESTClientPooler1.Host := eHost.Text;
      RESTClientPooler1.Port := StrToInt(ePort.Text);
      eventData              := 'AtualizaAluno/' + Aluno + '/' + NomeNovo;
      SendEvent              := sePost;
      lResponse              := RESTClientPooler1.SendEvent(eventData, RBody, SendEvent);
      ListAlunos(lResponse);
     Except
     End;
    End;
  End;
 RBody.Free;
End;

procedure TForm2.btnPutClick(Sender: TObject);
Var
 lResponse,
 Aluno : String;
 RBody : TStringList;
Begin
 RESTClientPooler1.Host     := eHost.Text;
 RESTClientPooler1.Port     := StrToInt(ePort.Text);
 RESTClientPooler1.UserName := edUserNameDW.Text;
 RESTClientPooler1.Password := edPasswordDW.Text;
 RBody := TStringList.Create;
 RBody.Add('json');
 Aluno := InputBox('Rest Client', 'Nome do aluno', '');
 If Aluno <> '' Then
  Begin
   Try
    RESTClientPooler1.Host := eHost.Text;
    RESTClientPooler1.Port := StrToInt(ePort.Text);
    lResponse := RESTClientPooler1.SendEvent('InsereAluno/' + Aluno, RBody, sePut);
    ListAlunos(lResponse);
   Except
   End;
  End;
 RBody.Free;
End;


procedure TForm2.btnDeleteClick(Sender: TObject);
Var
 lResponse,
 Aluno : String;
Begin
 RESTClientPooler1.Host     := eHost.Text;
 RESTClientPooler1.Port     := StrToInt(ePort.Text);
 RESTClientPooler1.UserName := edUserNameDW.Text;
 RESTClientPooler1.Password := edPasswordDW.Text;
 Aluno := InputBox('Rest Client', 'Nome do aluno', '');
 If Aluno <> '' Then
  Begin
   Try
    RESTClientPooler1.Host := eHost.Text;
    RESTClientPooler1.Port := StrToInt(ePort.Text);
    lResponse       := RESTClientPooler1.SendEvent('ExcluiAluno/' + Aluno, Nil, seDelete);
    ListAlunos(lResponse);
   Except
   End;
  End;
End;

procedure TForm2.btnIDHttpGetTestClick(Sender: TObject);
Var
 Response : String;
Begin
 RESTClientPooler1.Host     := eHost.Text;
 RESTClientPooler1.Port     := StrToInt(ePort.Text);
 RESTClientPooler1.UserName := edUserNameDW.Text;
 RESTClientPooler1.Password := edPasswordDW.Text;
 Memo2.Lines.Clear;
 Try
  // Passando par�metros no formato antigo (QueryString)
  RESTClientPooler1.Host := eHost.Text;
  RESTClientPooler1.Port := StrToInt(ePort.Text);
  Response        := RESTClientPooler1.SendEvent('ConsultaAluno?Nome=AlunoTeste');
  Memo2.Lines.Add(Response);
  // Passando par�metros no formato novo (REST URL)
  Response        := RESTClientPooler1.SendEvent('ConsultaAluno/AlunoTeste');
  Memo2.Lines.Add(Response);
  ListAlunos(Response);
 Finally
 End;
End;

procedure TForm2.btnIDHttpPostTesteClick(Sender: TObject);
Var
 Response : String;
 lParams  : TStringList;
Begin
 RESTClientPooler1.Host     := eHost.Text;
 RESTClientPooler1.Port     := StrToInt(ePort.Text);
 RESTClientPooler1.UserName := edUserNameDW.Text;
 RESTClientPooler1.Password := edPasswordDW.Text;
 Memo2.Lines.Clear;
 lParams := TStringList.Create;
 Try
  //Aqui o par�metro � passado no header da requisi��o e n�o na URL
  //da mesma forma que todos os navegadores o fazem
  //ou seja � possivel que voce tenha um client em HTML puro
  //dando POST no navegador num WebService em Lazarus
  lParams.Add('NomeAtual=Fulano');
  lParams.Add('NomeNovo=Cicrano');
  RESTClientPooler1.Host := eHost.Text;
  RESTClientPooler1.Port := StrToInt(ePort.Text);
  Response        := RESTClientPooler1.SendEvent('AtualizaAluno', lParams, sePOST);
  Memo2.Lines.Add(Response);
  ListAlunos(Response);
 Finally
  lParams.Free;
 End;
End;

end.