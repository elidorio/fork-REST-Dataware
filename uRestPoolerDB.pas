{
 Esse pacote de Componentes foi desenhado com o Objetivo de ajudar as pessoas a desenvolverem
com WebServices REST o mais pr�ximo poss�vel do desenvolvimento local DB, com componentes de
f�cil configura��o para que todos tenham acesso as maravilhas dos WebServices REST/JSON DataSnap.

Desenvolvedor Principal : Gilberto Rocha da Silva (XyberX)
Empresa : XyberPower Desenvolvimento
}

unit uRestPoolerDB;

interface

uses System.SysUtils,         System.Classes,
     FireDAC.Stan.Intf,       FireDAC.Stan.Option,     FireDAC.Stan.Param,
     FireDAC.Stan.Error,      FireDAC.DatS,            FireDAC.Stan.Async,
     FireDAC.DApt,            FireDAC.UI.Intf,         FireDAC.Stan.Def,
     FireDAC.Stan.Pool,       FireDAC.Comp.Client,     FireDAC.Comp.UI,
     FireDAC.Comp.DataSet,    System.JSON,             FireDAC.DApt.Intf,
     Data.DB,                 Data.FireDACJSONReflect, Data.DBXJSONReflect,
     IPPeerClient,            Datasnap.DSClientRest,   System.SyncObjs,
     uPoolerMethod,           FireDAC.Stan.StorageBin, Data.DBXPlatform,
     FireDAC.Stan.StorageJSON {$IFDEF MSWINDOWS},      Datasnap.DSServer,
     Datasnap.DSAuth,         Datasnap.DSProxyRest{$ENDIF},
     Soap.EncdDecd,           System.NetEncoding,      uMasterDetailData;

Type
 TEncodeSelect            = (esASCII, esUtf8);
 TOnEventDB               = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterScroll           = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterOpen             = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterClose            = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterInsert           = Procedure (DataSet : TDataSet)         of Object;
 TOnBeforeDelete          = Procedure (DataSet : TDataSet)         of Object;
 TOnBeforePost            = Procedure (DataSet : TDataSet)         of Object;
 TExecuteProc             = Reference to Procedure;
 TOnEventConnection       = Procedure (Sucess  : Boolean;
                                       Const Error : String)       of Object;
 TOnEventBeforeConnection = Procedure (Sender  : TComponent)       of Object;
 TOnEventTimer            = Procedure of Object;
 TBeforeGetRecords        = Procedure (Sender  : TObject;
                                       Var OwnerData : OleVariant) of Object;

Type
 TTimerData = Class(TThread)
 Private
  FValue : Integer;          //Milisegundos para execu��o
  FLock  : TCriticalSection; //Se��o cr�tica
  vEvent : TOnEventTimer;    //Evento a ser executado
 Public
  Property OnEventTimer : TOnEventTimer Read vEvent Write vEvent; //Evento a ser executado
 Protected
  Constructor Create(AValue: Integer; ALock: TCriticalSection);   //Construtor do Evento
  Procedure   Execute; Override;                                  //Procedure de Execu��o autom�tica
End;

Type
 TAutoCheckData = Class(TPersistent)
 Private
  vAutoCheck : Boolean;                            //Se tem Autochecagem
  vInTime    : Integer;                            //Em milisegundos o timer
  Timer      : TTimerData;                         //Thread do temporizador
  vEvent     : TOnEventTimer;                      //Evento a executar
  FLock      : TCriticalSection;                   //CriticalSection para execu��o segura
  Procedure  SetState(Value : Boolean);            //Ativa ou desativa a classe
  Procedure  SetInTime(Value : Integer);           //Diz o Timeout
  Procedure  SetEventTimer(Value : TOnEventTimer); //Seta o Evento a ser executado
 Public
  Constructor Create; //Cria o Componente
  Destructor  Destroy;Override;//Destroy a Classe
  Procedure   Assign(Source : TPersistent); Override;
 Published
  Property AutoCheck    : Boolean       Read vAutoCheck Write SetState;      //Se tem Autochecagem
  Property InTime       : Integer       Read vInTime    Write SetInTime;     //Em milisegundos o timer
  Property OnEventTimer : TOnEventTimer Read vEvent     Write SetEventTimer; //Evento a executar
End;

Type
 TProxyOptions = Class(TPersistent)
 Private
  vServer,              //Servidor Proxy na Rede
  vLogin,               //Login do Servidor Proxy
  vPassword : String;   //Senha do Servidor Proxy
  vPort     : Integer;  //Porta do Servidor Proxy
 Public
  Constructor Create;
  Procedure   Assign(Source : TPersistent); Override;
 Published
  Property Server   : String  Read vServer   Write vServer;   //Servidor Proxy na Rede
  Property Port     : Integer Read vPort     Write vPort;     //Porta do Servidor Proxy
  Property Login    : String  Read vLogin    Write vLogin;    //Login do Servidor Proxy
  Property Password : String  Read vPassword Write vPassword; //Senha do Servidor Proxy
End;

Type
 TRESTDataBase = Class(TComponent)
 Private
  Owner                : TComponent;                 //Proprietario do Componente
  vLogin,                                            //Login do Usu�rio caso haja autentica��o
  vPassword,                                         //Senha do Usu�rio caso haja autentica��o
  vRestWebService,                                   //Rest WebService para consultas
  vRestURL,                                          //URL do WebService REST
  vRestModule,                                       //Classe Principal do Servidor a ser utilizada
  vMyIP,                                             //Meu IP vindo do Servidor
  vRestPooler          : String;                     //Qual o Pooler de Conex�o do DataSet
  vPoolerPort          : Integer;                    //A Porta do Pooler
  vProxy               : Boolean;                    //Diz se tem servidor Proxy
  vProxyOptions        : TProxyOptions;              //Se tem Proxy diz quais as op��es
  vCompression,                                      //Se Vai haver compress�o de Dados
  vConnected           : Boolean;                    //Diz o Estado da Conex�o
  vOnEventConnection   : TOnEventConnection;         //Evento de Estado da Conex�o
  vOnBeforeConnection  : TOnEventBeforeConnection;   //Evento antes de Connectar o Database
  vAutoCheckData       : TAutoCheckData;             //Autocheck de Conex�o
  vTimeOut             : Integer;
  VEncondig            : TEncodeSelect;              //Enconding se usar CORS usar UTF8 - Alexandre Abade
  vContentex           : String ;                    //Contexto - Alexandre Abade
  vRESTContext         : String ;                    //RestContexto - Alexandre Abade
  Procedure SetConnection(Value : Boolean);          //Seta o Estado da Conex�o
  Procedure SetRestPooler(Value : String);           //Seta o Restpooler a ser utilizado
  Procedure SetPoolerPort(Value : Integer);          //Seta a Porta do Pooler a ser usada
  Procedure CheckConnection;                         //Checa o Estado automatico da Conex�o
  Function  TryConnect : Boolean;                    //Tenta Conectar o Servidor para saber se posso executar comandos
  Procedure SetConnectionOptions(Var Value : TDSRestConnection); //Seta as Op��es de Conex�o
  Function ExecuteCommand(Var SQL    : TStringList;
                          Var Params : TParams;
                          Var Error  : Boolean;
                          Var MessageError : String;
                          Execute    : Boolean = False) : TFDJSONDataSets;
  Procedure ApplyUpdates(Var SQL          : TStringList;
                         Var Params       : TParams;
                         ADeltaList       : TFDJSONDeltas;
                         TableName        : String;
                         Var Error        : Boolean;
                         Var MessageError : String);
  Function InsertMySQLReturnID(Var SQL          : TStringList;
                               Var Params       : TParams;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;
 Public
  Function    GetRestPoolers : TStringList;          //Retorna a Lista de DataSet Sources do Pooler
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
 Published
  Property OnConnection       : TOnEventConnection       Read vOnEventConnection  Write vOnEventConnection; //Evento relativo a tudo que acontece quando tenta conectar ao Servidor
  Property OnBeforeConnect    : TOnEventBeforeConnection Read vOnBeforeConnection Write vOnBeforeConnection; //Evento antes de Connectar o Database
  Property Active             : Boolean                  Read vConnected          Write SetConnection;      //Seta o Estado da Conex�o
  Property Compression        : Boolean                  Read vCompression        Write vCompression;       //Compress�o de Dados
  Property MyIP               : String                   Read vMyIP;
  Property Login              : String                   Read vLogin              Write vLogin;             //Login do Usu�rio caso haja autentica��o
  Property Password           : String                   Read vPassword           Write vPassword;          //Senha do Usu�rio caso haja autentica��o
  Property Proxy              : Boolean                  Read vProxy              Write vProxy;             //Diz se tem servidor Proxy
  Property ProxyOptions       : TProxyOptions            Read vProxyOptions       Write vProxyOptions;      //Se tem Proxy diz quais as op��es
  Property PoolerService      : String                   Read vRestWebService     Write vRestWebService;    //Host do WebService REST
  Property PoolerURL          : String                   Read vRestURL            Write vRestURL;           //URL do WebService REST
  Property PoolerPort         : Integer                  Read vPoolerPort         Write SetPoolerPort;      //A Porta do Pooler do DataSet
  Property PoolerName         : String                   Read vRestPooler         Write SetRestPooler;      //Qual o Pooler de Conex�o ligado ao componente
  Property RestModule         : String                   Read vRestModule         Write vRestModule;        //Classe do Servidor REST Principal
  Property StateConnection    : TAutoCheckData           Read vAutoCheckData      Write vAutoCheckData;     //Autocheck da Conex�o
  Property RequestTimeOut     : Integer                  Read vTimeOut            Write vTimeOut;           //Timeout da Requisi��o
  Property Encoding           : TEncodeSelect            Read VEncondig           write VEncondig ;         //Encoding da string
  Property Context            : string                   Read vContentex          write vContentex ;        //Contexto
  Property RESTContext        : string                   Read vRESTContext        write vRESTContext ;      //Rest Contexto
End;

Type
 TRESTClientSQL   = Class(TFDMemTable)                    //Classe com as funcionalidades de um DBQuery
 Private
  vOldStatus           : TDatasetState;
  vDataSource          : TDataSource;
  vOnAfterScroll       : TOnAfterScroll;
  vOnAfterOpen         : TOnAfterOpen;
  vOnAfterClose        : TOnAfterClose;
  vOnAfterInsert       : TOnAfterInsert;
  vOnBeforeDelete      : TOnBeforeDelete;
  vOnBeforePost        : TOnBeforePost;
  Owner                : TComponent;
  OldData              : TMemoryStream;
  vActualRec           : Integer;
  vAutoIncFields,
  vMasterFields,
  vUpdateTableName     : String;                          //Tabela que ser� feito Update no Servidor se for usada Reflex�o de Dados
  vCascadeDelete,
  vBeforeClone,
  vDataCache,                                             //Se usa cache local
  vConnectedOnce,                                         //Verifica se foi conectado ao Servidor
  vCommitUpdates,
  vCreateDS,
  vErrorBefore,
  vActive              : Boolean;                         //Estado do Dataset
  vSQL                 : TStringList;                     //SQL a ser utilizado na conex�o
  vParams              : TParams;                         //Parametros de Dataset
  vCacheDataDB         : TFDDataset;                      //O Cache de Dados Salvo para utiliza��o r�pida
  vOnGetDataError      : TOnEventConnection;              //Se deu erro na hora de receber os dados ou n�o
  vRESTDataBase        : TRESTDataBase;                   //RESTDataBase do Dataset
  vOnAfterDelete,
  vOnAfterPost         : TDataSetNotifyEvent;
  FieldDefsUPD         : TFieldDefs;
  vMasterDataSet       : TRESTClientSQL;
  vMasterDetailList    : TMasterDetailList;               //DataSet MasterDetail Function
  Procedure SetMasterFields(Value : String);
  Procedure CloneDefinitions(Source : TFDMemTable;
                             aSelf  : TRESTClientSQL);    //Fields em Defini��es
  Procedure OnChangingSQL(Sender: TObject);               //Quando Altera o SQL da Lista
  Procedure SetActiveDB(Value : Boolean);                 //Seta o Estado do Dataset
  Procedure SetSQL(Value : TStringList);                  //Seta o SQL a ser usado
  Procedure CreateParams;                                 //Cria os Parametros na lista de Dataset
  Procedure SetDataBase(Value : TRESTDataBase);           //Diz o REST Database
  Function  GetData : Boolean;                            //Recebe os Dados da Internet vindo do Servidor REST
  Procedure SetUpdateTableName(Value : String);           //Diz qual a tabela que ser� feito Update no Banco
  Procedure OldAfterPost(DataSet: TDataSet);              //Eventos do Dataset para realizar o AfterPost
  Procedure OldAfterDelete(DataSet: TDataSet);            //Eventos do Dataset para realizar o AfterDelete
  Procedure SetMasterDataSet(Value : TRESTClientSQL);
  Procedure PrepareDetails(ActiveMode : Boolean);
  Procedure PrepareDetailsNew;
  Property  LocalSQL;
  Property  DataSetField;
  Property  DetailFields;
  Property  Adapter;
  Property  ChangeAlerter;
  Property  ChangeAlertName;
  Property  ObjectView;
  Property  StoreDefs;
  Property  CachedUpdates;
  Property  MasterSource;
  Procedure ProcAfterScroll (DataSet : TDataSet);
  Procedure ProcAfterOpen   (DataSet : TDataSet);
  Procedure ProcAfterClose  (DataSet : TDataSet);
  Procedure ProcAfterInsert (DataSet : TDataSet);
  Procedure ProcBeforeDelete(DataSet : TDataSet);
  Procedure ProcBeforePost  (DataSet : TDataSet);
 Protected
  Function  CanObserve(const ID: Integer): Boolean; Override;
 Public
  //M�todos
  Procedure   Open; Virtual;                              //M�todo Open que ser� utilizado no Componente
  Procedure   Close;Virtual;                              //M�todo Close que ser� utilizado no Componente
  Procedure   CreateDataSet; Virtual;
  Procedure   ExecSQL;                                    //M�todo ExecSQL que ser� utilizado no Componente
  Function    InsertMySQLReturnID : Integer;              //M�todo de ExecSQL com retorno de Incremento
  Function    ParamByName(Value : String) : TParam;       //Retorna o Parametro de Acordo com seu nome
  Function    ApplyUpdates(var Error : String) : Boolean; //Aplica Altera��es no Banco de Dados
  Constructor Create(AOwner : TComponent);Override;       //Cria o Componente
  Destructor  Destroy;Override;                           //Destroy a Classe
  Procedure   Loaded; Override;
  procedure   OpenCursor(InfoQuery: Boolean); Override;   //Subscrevendo o OpenCursor para n�o ter erros de ADD Fields em Tempo de Design
  Procedure   GotoRec(Const RecNo : Integer);
 Published
  Property MasterDataSet   : TRESTClientSQL      Read vMasterDataSet            Write SetMasterDataSet;
  Property MasterCascadeDelete : Boolean         Read vCascadeDelete            Write vCascadeDelete;
  Property AfterDelete     : TDataSetNotifyEvent Read vOnAfterDelete            Write vOnAfterDelete;
  Property AfterPost       : TDataSetNotifyEvent Read vOnAfterPost              Write vOnAfterPost;
  Property OnGetDataError  : TOnEventConnection  Read vOnGetDataError           Write vOnGetDataError;         //Recebe os Erros de ExecSQL ou de GetData
  Property AfterScroll     : TOnAfterScroll      Read vOnAfterScroll            Write vOnAfterScroll;
  Property AfterOpen       : TOnAfterOpen        Read vOnAfterOpen              Write vOnAfterOpen;
  Property AfterClose      : TOnAfterClose       Read vOnAfterClose             Write vOnAfterClose;
  Property AfterInsert     : TOnAfterInsert      Read vOnAfterInsert            Write vOnAfterInsert;
  Property BeforeDelete    : TOnBeforeDelete     Read vOnBeforeDelete           Write vOnBeforeDelete;
  Property BeforePost      : TOnBeforePost       Read vOnBeforePost             Write vOnBeforePost;
  Property Active          : Boolean             Read vActive                   Write SetActiveDB;             //Estado do Dataset
  Property DataCache       : Boolean             Read vDataCache                Write vDataCache;              //Diz se ser� salvo o �ltimo Stream do Dataset
  Property Params          : TParams             Read vParams                   Write vParams;                 //Parametros de Dataset
  Property DataBase        : TRESTDataBase       Read vRESTDataBase             Write SetDataBase;             //Database REST do Dataset
  Property SQL             : TStringList         Read vSQL                      Write SetSQL;                  //SQL a ser Executado
  Property UpdateTableName : String              Read vUpdateTableName          Write SetUpdateTableName;      //Tabela que ser� usada para Reflex�o de Dados
//  Property AutoIncFields   : String              Read vAutoIncFields            Write vAutoIncFields;
End;


Type
 TRESTPoolerList = Class(TComponent)
 Private
  Owner                : TComponent;                 //Proprietario do Componente
  vPoolerPrefix,                                     //Prefixo do WS
  vLogin,                                            //Login do Usu�rio caso haja autentica��o
  vPassword,                                         //Senha do Usu�rio caso haja autentica��o
  vRestWebService,                                   //Rest WebService para consultas
  vRestURL             : String;                     //Qual o Pooler de Conex�o do DataSet
  vPoolerPort          : Integer;                    //A Porta do Pooler
  vConnected,
  vProxy               : Boolean;                    //Diz se tem servidor Proxy
  vProxyOptions        : TProxyOptions;              //Se tem Proxy diz quais as op��es
  vPoolerList          : TStringList;
  Procedure SetConnection(Value : Boolean);          //Seta o Estado da Conex�o
  Procedure SetPoolerPort(Value : Integer);          //Seta a Porta do Pooler a ser usada
  Function  TryConnect : Boolean;                    //Tenta Conectar o Servidor para saber se posso executar comandos
  Procedure SetConnectionOptions(Var Value : TDSRestConnection); //Seta as Op��es de Conex�o
 Public
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
 Published
  Property Active             : Boolean                  Read vConnected          Write SetConnection;      //Seta o Estado da Conex�o
  Property Login              : String                   Read vLogin              Write vLogin;             //Login do Usu�rio caso haja autentica��o
  Property Password           : String                   Read vPassword           Write vPassword;          //Senha do Usu�rio caso haja autentica��o
  Property Proxy              : Boolean                  Read vProxy              Write vProxy;             //Diz se tem servidor Proxy
  Property ProxyOptions       : TProxyOptions            Read vProxyOptions       Write vProxyOptions;      //Se tem Proxy diz quais as op��es
  Property PoolerService      : String                   Read vRestWebService     Write vRestWebService;    //Host do WebService REST
  Property PoolerURL          : String                   Read vRestURL            Write vRestURL;           //URL do WebService REST
  Property PoolerPort         : Integer                  Read vPoolerPort         Write SetPoolerPort;      //A Porta do Pooler do DataSet
  Property PoolerPrefix       : String                   Read vPoolerPrefix       Write vPoolerPrefix;      //Prefixo do WebService REST
  Property Poolers            : TStringList              Read vPoolerList;
End;

{$IFDEF MSWINDOWS}
Type
 TRESTPoolerDBP = ^TComponent;
 TRESTPoolerDB  = Class(TComponent)
 Private
  Owner          : TComponent;
  FLock          : TCriticalSection;
  vFDConnectionBack,
  vFDConnection  : TFDConnection;
  vCompression   : Boolean;
  vEncoding      : TEncodeSelect;
  Procedure SetConnection(Value : TFDConnection);
  Function  GetConnection : TFDConnection;
 Public
  Procedure ApplyChanges(TableName,
                         SQL               : String;
                         Params            : TParams;
                         Var Error         : Boolean;
                         Var MessageError  : String;
                         Const ADeltaList  : TFDJSONDeltas);Overload;
  Procedure ApplyChanges(TableName,
                         SQL               : String;
                         Var Error         : Boolean;
                         Var MessageError  : String;
                         Const ADeltaList  : TFDJSONDeltas);Overload;
  Function ExecuteCommand(SQL        : String;
                          Var Error  : Boolean;
                          Var MessageError : String;
                          Execute    : Boolean = False) : TFDJSONDataSets;Overload;
  Function ExecuteCommand(SQL              : String;
                          Params           : TParams;
                          Var Error        : Boolean;
                          Var MessageError : String;
                          Execute          : Boolean = False) : TFDJSONDataSets;Overload;
  Function InsertMySQLReturnID(SQL              : String;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;
  Function InsertMySQLReturnID(SQL              : String;
                               Params           : TParams;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;
 Published
  Property    Database    : TFDConnection Read GetConnection Write SetConnection;
  Property    Compression : Boolean       Read vCompression  Write vCompression;
  Property    Encoding    : TEncodeSelect Read vEncoding     Write vEncoding;

  Constructor Create(AOwner : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                     //Destroy a Classe
End;
{$ENDIF}

implementation

Function GetEncoding(Avalue : TEncodeSelect) : TEncoding;
Begin
 Case Avalue of
  esUtf8  : Result := TEncoding.utf8;
  esASCII : Result := TEncoding.ASCII;
 End;
End;

Function EncodeStrings(Value : String) : String;
Var
 Input,
 Output : TStringStream;
Begin
 Input := TStringStream.Create(Value, TEncoding.ASCII);
 Try
  Input.Position := 0;
  Output := TStringStream.Create('', TEncoding.ASCII);
  Try
   Soap.EncdDecd.EncodeStream(Input, Output);
   Result := Output.DataString;
  Finally
   Output.Free;
  End;
 Finally
  Input.Free;
 End;
End;

Function DecodeStrings(Value : String;Encoding:TEncoding) : String;
Var
 Input,
 Output : TStringStream;
Begin
 If Length(Value) > 0 Then
  Begin
   Input := TStringStream.Create(Value, Encoding);
   Try
    Output := TStringStream.Create('', Encoding);
    Try
     Soap.EncdDecd.DecodeStream(Input, Output);
     Output.Position := 0;
     Try
      Result := Output.DataString;
     Except
      Raise;
     End;
    Finally
     Output.Free;
    End;
   Finally
    Input.Free;
   End;
  End;
End;

Procedure TAutoCheckData.Assign(Source: TPersistent);
Var
 Src : TAutoCheckData;
Begin
 If Source is TAutoCheckData Then
  Begin
   Src        := TAutoCheckData(Source);
   vAutoCheck := Src.AutoCheck;
   vInTime    := Src.InTime;
//   vEvent     := Src.OnEventTimer;
  End
 Else
  Inherited;
End;

Procedure TProxyOptions.Assign(Source: TPersistent);
Var
 Src : TProxyOptions;
Begin
 If Source is TProxyOptions Then
  Begin
   Src := TProxyOptions(Source);
   vServer := Src.Server;
   vLogin  := Src.Login;
   vPassword := Src.Password;
   vPort     := Src.Port;
  End
 Else
  Inherited;
End;

{$IFDEF MSWINDOWS}
Function  TRESTPoolerDB.GetConnection : TFDConnection;
Begin
 Result := vFDConnectionBack;
End;

Procedure TRESTPoolerDB.SetConnection(Value : TFDConnection);
Begin
 vFDConnectionBack := Value;
 If Value <> Nil Then
  vFDConnection     := vFDConnectionBack
 Else
  Begin
   If vFDConnection <> Nil Then
    vFDConnection.Close;
  End;
End;

Function TRESTPoolerDB.InsertMySQLReturnID(SQL              : String;
                                           Var Error        : Boolean;
                                           Var MessageError : String) : Integer;
Var
 oTab        : TFDDatStable;
 A, I        : Integer;
 fdCommand   : TFDCommand;
Begin
 Result := -1;
 Error  := False;
 fdCommand := TFDCommand.Create(Owner);
 Try
  fdCommand.Connection := vFDConnection;
  fdCommand.CommandText.Clear;
  fdCommand.CommandText.Add(DecodeStrings(SQL,GetEncoding(self.vEncoding)) + '; SELECT LAST_INSERT_ID()ID');
  fdCommand.Open;
  oTab := fdCommand.Define;
  fdCommand.Fetch(oTab, True);
  If oTab.Rows.Count > 0 Then
   Result := StrToInt(oTab.Rows[0].AsString['ID']);
  vFDConnection.CommitRetaining;
 Except
  On E : Exception do
   Begin
    vFDConnection.RollbackRetaining;
    Error        := True;
    MessageError := E.Message;
   End;
 End;
 fdCommand.Close;
 FreeAndNil(fdCommand);
 FreeAndNil(oTab);
 GetInvocationMetaData.CloseSession := True;
End;

Function TRESTPoolerDB.InsertMySQLReturnID(SQL              : String;
                                           Params           : TParams;
                                           Var Error        : Boolean;
                                           Var MessageError : String) : Integer;
Var
 oTab        : TFDDatStable;
 A, I        : Integer;
 vParamName  : String;
 fdCommand   : TFDCommand;
 Function GetParamIndex(Params : TFDParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
 Result := -1;
 Error  := False;
 fdCommand := TFDCommand.Create(Owner);
 Try
  fdCommand.Connection := vFDConnection;
  fdCommand.CommandText.Clear;
  fdCommand.CommandText.Add(DecodeStrings(SQL,GetEncoding(self.vEncoding)) + '; SELECT LAST_INSERT_ID()ID');
  If Params <> Nil Then
   Begin
    For I := 0 To Params.Count -1 Do
     Begin
      If fdCommand.Params.Count > I Then
       Begin
        vParamName := Copy(StringReplace(Params[I].Name, ',', '', []), 1, Length(Params[I].Name));
        A          := GetParamIndex(fdCommand.Params, vParamName);
        If A > -1 Then
         fdCommand.Params[A].Value := Params[I].Value;
       End
      Else
       Break;
     End;
   End;
  fdCommand.Open;
  oTab := fdCommand.Define;
  fdCommand.Fetch(oTab, True);
  If oTab.Rows.Count > 0 Then
   Result := StrToInt(oTab.Rows[0].AsString['ID']);
  vFDConnection.CommitRetaining;
 Except
  On E : Exception do
   Begin
    vFDConnection.RollbackRetaining;
    Error        := True;
    MessageError := E.Message;
   End;
 End;
 fdCommand.Close;
 FreeAndNil(fdCommand);
 FreeAndNil(oTab);
 GetInvocationMetaData.CloseSession := True;
End;

Function TRESTPoolerDB.ExecuteCommand(SQL        : String;
                                      Var Error  : Boolean;
                                      Var MessageError : String;
                                      Execute    : Boolean = False) : TFDJSONDataSets;
Var
 vTempQuery  : TFDQuery;
 vTempWriter : TFDJSONDataSetsWriter;
Begin
 Result := Nil;
 Error  := False;
 vTempQuery               := TFDQuery.Create(Owner);
 Try
  if not vFDConnection.Connected then
  vFDConnection.Connected :=true;
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL,GetEncoding(self.vEncoding)));
  If Not Execute Then
   Begin
    vTempQuery.Open   ;
    Result            := TFDJSONDataSets.Create;
    vTempWriter       := TFDJSONDataSetsWriter.Create(Result);
    Try
     vTempWriter.ListAdd(Result, vTempQuery);
    Finally
//     If vCompression Then
//      Result.ToString
     vTempWriter := Nil;
     vTempWriter.DisposeOf;
    End;
   End
  Else
   Begin
    vTempQuery.ExecSQL;
    vFDConnection.CommitRetaining;
   End;
 Except
  On E : Exception do
   Begin
    vFDConnection.RollbackRetaining;
    Error := True;
    MessageError := E.Message;
   End;
 End;
End;

Function TRESTPoolerDB.ExecuteCommand(SQL        : String;
                                      Params     : TParams;
                                      Var Error  : Boolean;
                                      Var MessageError : String;
                                      Execute    : Boolean = False) : TFDJSONDataSets;
Var
 vTempQuery  : TFDQuery;
 A, I        : Integer;
 vTempWriter : TFDJSONDataSetsWriter;
 vParamName  : String;
// vLogErro    : TStringList;
 Function GetParamIndex(Params : TFDParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
 Result := Nil;
 Error  := False;
 vTempQuery               := TFDQuery.Create(Owner);
 Try
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL,GetEncoding(self.vEncoding)));
  If Params <> Nil Then
   Begin
    vTempQuery.Prepare;
    For I := 0 To Params.Count -1 Do
     Begin
      If vTempQuery.ParamCount > I Then
       Begin
        vParamName := Copy(StringReplace(Params[I].Name, ',', '', []), 1, Length(Params[I].Name));
        A          := GetParamIndex(vTempQuery.Params, vParamName);
        If A > -1 Then//vTempQuery.ParamByName(vParamName) <> Nil Then
         Begin
          If vTempQuery.Params[A].DataType in [ftFixedChar, ftFixedWideChar,
                                               ftString,    ftWideString]    Then
           Begin
            If vTempQuery.Params[A].Size > 0 Then
             vTempQuery.Params[A].Value := Copy(Params[I].AsString, 1, vTempQuery.Params[A].Size)
            Else
             vTempQuery.Params[A].Value := Params[I].AsString;
           End
          Else
           vTempQuery.Params[A].Value    := Params[I].Value;
         End;
       End
      Else
       Break;
     End;
   End;
  If Not Execute Then
   Begin
//    vTempQuery.Active := True;
    Result            := TFDJSONDataSets.Create;
    vTempWriter       := TFDJSONDataSetsWriter.Create(Result);
    Try
     vTempWriter.ListAdd(Result, vTempQuery);
    Finally
     vTempWriter := Nil;
     vTempWriter.DisposeOf;
    End;
   End
  Else
   Begin
    vTempQuery.ExecSQL;
    vFDConnection.CommitRetaining;
   End;
 Except
  On E : Exception do
   Begin
    vFDConnection.RollbackRetaining;
    Error := True;
    MessageError := E.Message;
{
    vLogErro := TStringList.Create;
    vLogErro.Add(MessageError);
    vLogErro.SaveToFile(ExtractFilePath(ParamSTR(0)) + '..\LogErr.Text');
    vLogErro.DisposeOf;
}
   End;
 End;
 GetInvocationMetaData.CloseSession := True;
End;

Procedure TRESTPoolerDB.ApplyChanges(TableName,
                                     SQL               : String;
                                     Var Error         : Boolean;
                                     Var MessageError  : String;
                                     Const ADeltaList  : TFDJSONDeltas);
Var
 vTempQuery : TFDQuery;
 LApply     : IFDJSONDeltasApplyUpdates;
begin
 Error                    := False;
 vTempQuery               := TFDQuery.Create(Owner);
 vTempQuery.CachedUpdates := True;
 Try
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL, GetEncoding(vEncoding)));
  vTempQuery.Active := True;
 Except
  On E : Exception do
   Begin
    Error := True;
    MessageError := E.Message;
    vTempQuery.DisposeOf;
    Exit;
   End;
 End;
 LApply := TFDJSONDeltasApplyUpdates.Create(ADeltaList);
 vTempQuery.UpdateOptions.UpdateTableName := TableName;
 Try
  LApply.ApplyUpdates(0,  vTempQuery.Command);
 Except

 End;
 If LApply.Errors.Count > 0 then
  Begin
   Error := True;
   MessageError := LApply.Errors.Strings.Text;
  End;
 If Not Error Then
  Begin
   Try
    Database.CommitRetaining;
   Except
    On E : Exception do
     Begin
      Database.RollbackRetaining;
      Error := True;
      MessageError := E.Message;
     End;
   End;
  End;
 vTempQuery.DisposeOf;
end;

Procedure TRESTPoolerDB.ApplyChanges(TableName,
                                     SQL               : String;
                                     Params            : TParams;
                                     Var Error         : Boolean;
                                     Var MessageError  : String;
                                     Const ADeltaList  : TFDJSONDeltas);
Var
 I            : Integer;
 vTempQuery   : TFDQuery;
 LApply       : IFDJSONDeltasApplyUpdates;
 vTempWriter  : TFDJSONDeltasWriter;
begin
 Error  := False;
 vTempQuery               := TFDQuery.Create(Owner);
 vTempQuery.CachedUpdates := True;
 Try
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL,GetEncoding(self.vEncoding)));
  If Params <> Nil Then
   Begin
    vTempQuery.Prepare;
    For I := 0 To Params.Count -1 Do
     Begin
      If vTempQuery.ParamCount > I Then
       Begin
        If vTempQuery.ParamByName(Params[I].Name) <> Nil Then
         Begin
          If vTempQuery.ParamByName(Params[I].Name).DataType in [ftFixedChar, ftFixedWideChar,
                                                                 ftString,    ftWideString]    Then
           Begin
            If vTempQuery.ParamByName(Params[I].Name).Size > 0 Then
             vTempQuery.ParamByName(Params[I].Name).Value := Copy(Params[I].AsString, 1, vTempQuery.ParamByName(Params[I].Name).Size)
            Else
             vTempQuery.ParamByName(Params[I].Name).Value := Params[I].AsString;
           End
          Else
           vTempQuery.ParamByName(Params[I].Name).Value    := Params[I].Value;
         End;
       End
      Else
       Break;
     End;
   End;
  vTempQuery.Active := True;
 Except
  On E : Exception do
   Begin
    Error := True;
    MessageError := E.Message;
    vTempQuery.DisposeOf;
    Exit;
   End;
 End;
 LApply := TFDJSONDeltasApplyUpdates.Create(ADeltaList);
 vTempQuery.UpdateOptions.UpdateTableName := TableName;
 Try
  LApply.ApplyUpdates(0,  vTempQuery.Command);
 Except
 End;
 If LApply.Errors.Count > 0 then
  Begin
   Error := True;
   MessageError := LApply.Errors.Strings.Text;
  End;
 Try
  Database.CommitRetaining;
 Except
  On E : Exception do
   Begin
    Database.RollbackRetaining;
    Error := True;
    MessageError := E.Message;
   End;
 End;
 vTempQuery.DisposeOf;
end;

Constructor TRESTPoolerDB.Create(AOwner : TComponent);
Begin
 Inherited;
 Owner        := aOwner;
 FLock        := TCriticalSection.Create;
 vCompression := False;
 vEncoding    := esUtf8;
End;

Destructor  TRESTPoolerDB.Destroy;
Begin
 FLock.Release;
 FLock.DisposeOf;
 Inherited;
End;
{$ENDIF}

Constructor TAutoCheckData.Create;
Begin
 Inherited;
 vAutoCheck := False;
 vInTime    := 1000;
 vEvent     := Nil;
 Timer      := Nil;
 FLock      := TCriticalSection.Create;
End;

Destructor  TAutoCheckData.Destroy;
Begin
 SetState(False);
 FLock.Release;
 FLock.DisposeOf;
 Inherited;
End;

Procedure  TAutoCheckData.SetState(Value : Boolean);
Begin
 vAutoCheck := Value;
 If vAutoCheck Then
  Begin
   If Timer <> Nil Then
    Begin
     Timer.Terminate;
     Timer := Nil;
    End;
   Timer              := TTimerData.Create(vInTime, FLock);
   Timer.OnEventTimer := vEvent;
  End
 Else
  Begin
   If Timer <> Nil Then
    Begin
     Timer.Terminate;
     Timer := Nil;
    End;
  End;
End;

Procedure  TAutoCheckData.SetInTime(Value : Integer);
Begin
 vInTime    := Value;
 SetState(vAutoCheck);
End;

Procedure  TAutoCheckData.SetEventTimer(Value : TOnEventTimer);
Begin
 vEvent := Value;
 SetState(vAutoCheck);
End;

Constructor TTimerData.Create(AValue: Integer; ALock: TCriticalSection);
Begin
 FValue := AValue;
 FLock := ALock;
 Inherited Create(False);
End;

Procedure TTimerData.Execute;
Begin
 While Not Terminated do
  Begin
   Sleep(FValue);
   FLock.Acquire;
   if Assigned(vEvent) then
    vEvent;
   FLock.Release;
  End;
End;

Constructor TProxyOptions.Create;
Begin
 Inherited;
 vServer   := '';
 vLogin    := vServer;
 vPassword := vLogin;
 vPort     := 8888;
End;

Procedure TRESTPoolerList.SetConnectionOptions(Var Value : TDSRestConnection);
Begin
 Value                   := TDSRestConnection.Create(Nil);
 Value.LoginPrompt       := False;
 Value.PreserveSessionID := False;
 Value.Protocol          := 'http';
 Value.Host              := vRestWebService;
 Value.Port              := vPoolerPort;
 Value.UrlPath           := vRestURL;
 Value.UserName          := vLogin;
 Value.Password          := vPassword;
 if vProxy then
  Begin
   Value.ProxyHost     := vProxyOptions.vServer;
   Value.ProxyPort     := vProxyOptions.vPort;
   Value.ProxyUsername := vProxyOptions.vLogin;
   Value.ProxyPassword := vProxyOptions.vPassword;
  End
 Else
  Begin
   Value.ProxyHost     := '';
   Value.ProxyPort     := 0;
   Value.ProxyUsername := '';
   Value.ProxyPassword := '';
  End;
End;

Procedure TRESTDataBase.SetConnectionOptions(Var Value : TDSRestConnection);
Begin
 Value                     := TDSRestConnection.Create(Nil);
 Value.LoginPrompt         := False;
 Value.PreserveSessionID   := False;
 Value.Protocol            := 'http';
 Value.Host                := vRestWebService;
 Value.Port                := vPoolerPort;
 Value.UrlPath             := vRestURL;
 Value.UserName            := vLogin;
 Value.Password            := vPassword;
 Value.HTTP.ConnectTimeout := vTimeOut;
 Value.RESTContext         := vRESTContext;
 Value.Context             := vContentex;

 If vProxy Then
  Begin
   Value.ProxyHost     := vProxyOptions.vServer;
   Value.ProxyPort     := vProxyOptions.vPort;
   Value.ProxyUsername := vProxyOptions.vLogin;
   Value.ProxyPassword := vProxyOptions.vPassword;
  End
 Else
  Begin
   Value.ProxyHost     := '';
   Value.ProxyPort     := 0;
   Value.ProxyUsername := '';
   Value.ProxyPassword := '';
  End;
End;

Procedure TRESTDataBase.ApplyUpdates(Var SQL          : TStringList;
                                     Var Params       : TParams;
                                     ADeltaList       : TFDJSONDeltas;
                                     TableName        : String;
                                     Var Error        : Boolean;
                                     Var MessageError : String);
Var
 vDSRConnection    : TDSRestConnection;
 vRESTConnectionDB : TSMPoolerMethodClient;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
Begin
 if vRestPooler = '' then
  Exit;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Compression := vCompression;
 vRESTConnectionDB.Encoding    := GetEncoding(VEncondig);
 Try
  If Params.Count > 0 Then
   vRESTConnectionDB.ApplyChanges(vRestPooler,
                                  vRestModule,
                                  TableName,
                                  GetLineSQL(SQL),
                                  Params,
                                  ADeltaList,
                                  Error,
                                  MessageError, '',
                                  vTimeOut, vLogin, vPassword)
  Else
   vRESTConnectionDB.ApplyChangesPure(vRestPooler,
                                      vRestModule,
                                      TableName,
                                      GetLineSQL(SQL),
                                      ADeltaList,
                                      Error,
                                      MessageError, '',
                                      vTimeOut, vLogin, vPassword);
  If Assigned(vOnEventConnection) Then
   vOnEventConnection(True, 'ApplyUpdates Ok')
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vDSRConnection.DisposeOf;
 vRESTConnectionDB.DisposeOf;
End;

Function TRESTDataBase.InsertMySQLReturnID(Var SQL          : TStringList;
                                           Var Params       : TParams;
                                           Var Error        : Boolean;
                                           Var MessageError : String) : Integer;
Var
 vDSRConnection    : TDSRestConnection;
 vRESTConnectionDB : TSMPoolerMethodClient;
 oJsonObject       : Integer;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
Begin
 Result := -1;
 Error  := False;
 if vRestPooler = '' then
  Exit;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Compression := vCompression;
 vRESTConnectionDB.Encoding    := GetEncoding(VEncondig);
 Try
  If Params.Count > 0 Then
   oJsonObject := vRESTConnectionDB.InsertValue(vRestPooler,
                                                vRestModule,
                                                GetLineSQL(SQL),
                                                Params,
                                                Error, MessageError, '',
                                                vTimeOut, vLogin, vPassword)
  Else
   oJsonObject := vRESTConnectionDB.InsertValuePure(vRestPooler,
                                                    vRestModule,
                                                    GetLineSQL(SQL),
                                                    Error, MessageError, '',
                                                    vTimeOut, vLogin, vPassword);
  Result := oJsonObject;
  If Assigned(vOnEventConnection) Then
   vOnEventConnection(True, 'ExecuteCommand Ok');
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
    Error                    := True;
    MessageError             := E.Message;
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vDSRConnection.DisposeOf;
 vRESTConnectionDB.DisposeOf;
End;

Function TRESTDataBase.ExecuteCommand(Var SQL    : TStringList;
                                      Var Params : TParams;
                                      Var Error  : Boolean;
                                      Var MessageError : String;
                                      Execute    : Boolean = False) : TFDJSONDataSets;
Var
 vDSRConnection    : TDSRestConnection;
 vRESTConnectionDB : TSMPoolerMethodClient;
 oJsonObject       : TJSONObject;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;

Begin
 Result := Nil;
 if vRestPooler = '' then
  Exit;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Compression := vCompression;
 vRESTConnectionDB.Encoding    := GetEncoding(VEncondig);
 Try
  If Params.Count > 0 Then
   oJsonObject := vRESTConnectionDB.ExecuteCommandJSON(vRestPooler,
                                                       vRestModule, GetLineSQL(SQL),
                                                       Params, Error,
                                                       MessageError, Execute, '', vTimeOut, vLogin, vPassword)
  Else
   oJsonObject := vRESTConnectionDB.ExecuteCommandPureJSON(vRestPooler,
                                                           vRestModule,
                                                           GetLineSQL(SQL), Error,
                                                           MessageError, Execute, '', vTimeOut, vLogin, vPassword);
  Result := TFDJSONDataSets.Create;
  If (oJsonObject <> Nil) Then
   TFDJSONInterceptor.JSONObjectToDataSets(oJsonObject, Result);
  If Assigned(vOnEventConnection) Then
   vOnEventConnection(True, 'ExecuteCommand Ok');
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vDSRConnection.DisposeOf;
 vRESTConnectionDB.DisposeOf;
End;

Function TRESTDataBase.GetRestPoolers : TStringList;
Var
 I                 : Integer;
 vTempList         : TStringList;
 vDSRConnection    : TDSRestConnection;
 vRESTConnectionDB : TSMPoolerMethodClient;
Begin
 Result := Nil;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Compression := vCompression;
 vRESTConnectionDB.Encoding    := GetEncoding(VEncondig);
 Try
  vTempList        := vRESTConnectionDB.PoolersDataSet(vRestModule, '', vTimeOut, vLogin, vPassword);
  Result           := TStringList.Create;
  For I := 0 To vTempList.Count -1 do
   Result.Add(vTempList[I]);
  If Assigned(vOnEventConnection) Then
   vOnEventConnection(True, 'GetRestPoolers Ok');
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vDSRConnection.DisposeOf;
 vRESTConnectionDB.DisposeOf;
End;

Constructor TRESTPoolerList.Create(AOwner : TComponent);
Begin
 Inherited;
 Owner                     := AOwner;
 vLogin                    := '';
 vPassword                 := vLogin;
 vPoolerPort               := 8082;
 vProxy                    := False;
 vProxyOptions             := TProxyOptions.Create;
 vPoolerList               := TStringList.Create;
End;

Constructor TRESTDataBase.Create(AOwner : TComponent);
Begin
 Inherited;
 Owner                     := AOwner;
 vLogin                    := '';
 vMyIP                     := '0.0.0.0';
 vCompression              := False;
 vPassword                 := vLogin;
 vRestModule               := 'TServerMethods1';
 vRestPooler               := vPassword;
 vPoolerPort               := 8081;
 vProxy                    := False;
 vProxyOptions             := TProxyOptions.Create;
 vAutoCheckData            := TAutoCheckData.Create;
 vAutoCheckData.vAutoCheck := False;
 vAutoCheckData.vInTime    := 1000;
 vTimeOut                  := 10000;
 vAutoCheckData.vEvent     := CheckConnection;
 VEncondig                 := esUtf8;
 vContentex                := 'Datasnap';
 vRESTContext              := 'rest/';
End;

Destructor  TRESTPoolerList.Destroy;
Begin
 vProxyOptions.DisposeOf;
 If vPoolerList <> Nil Then
  vPoolerList.DisposeOf;
 Inherited;
End;

Destructor  TRESTDataBase.Destroy;
Begin
 vAutoCheckData.vAutoCheck := False;
 vProxyOptions.DisposeOf;
 vAutoCheckData.DisposeOf;
 Inherited;
End;

Procedure TRESTDataBase.CheckConnection;
Begin
 vConnected := TryConnect;
End;

Function  TRESTPoolerList.TryConnect : Boolean;
Var
 vTempSend,
 vTempResult       : String;
 vDSRConnection    : TDSRestConnection;
 vRESTConnectionDB : TSMPoolerMethodClient;
Begin
 Result := False;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB           := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Encoding  := TEncoding.ASCII;
 Try
  vPoolerList.Clear;
  vPoolerList.Assign(vRESTConnectionDB.PoolersDataSet(vPoolerPrefix, vTempResult, 3000, vLogin, vPassword));
  Result      := True;
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
   End;
 End;
 vDSRConnection.DisposeOf;
 vRESTConnectionDB.DisposeOf;
End;

Function  TRESTDataBase.TryConnect : Boolean;
Var
 vTempSend,
 vTempResult       : String;
 vDSRConnection    : TDSRestConnection;
 vRESTConnectionDB : TSMPoolerMethodClient;
Begin
 Result := False;
 If vRestPooler = '' Then
  vTempSend := 'ping'
 Else
  vTempSend := vRestPooler;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Encoding := GetEncoding(VEncondig);
 Try
  vTempResult := vRESTConnectionDB.EchoPooler(vTempSend, vRestModule, '', vTimeOut, vLogin, vPassword);
  vMyIP       := vTempResult;
  Result      := True;
  If Assigned(vOnEventConnection) Then
   vOnEventConnection(True, 'TryConnect Ok');
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vDSRConnection.DisposeOf;
 vRESTConnectionDB.DisposeOf;
End;

Procedure TRESTDataBase.SetConnection(Value : Boolean);
Begin
 If (Value) And
    (Trim(vRestPooler) = '') Then
  Exit;
 if (Value) And Not(vConnected) then
  If Assigned(vOnBeforeConnection) Then
   vOnBeforeConnection(Self);
 If Not(vConnected) And (Value) Then
  Begin
   vConnected := Value;
   if vConnected then
    vConnected := TryConnect
   Else
    vMyIP := '';
  End
 Else If Not (Value) Then
  Begin
   vConnected := Value;
   vMyIP := '';
  End;
End;

Procedure TRESTPoolerList.SetConnection(Value : Boolean);
Begin
 vConnected := Value;
 If vConnected Then
  vConnected := TryConnect;
End;

Procedure TRESTDataBase.SetPoolerPort(Value : Integer);
Begin
 vPoolerPort := Value;
End;

Procedure TRESTPoolerList.SetPoolerPort(Value : Integer);
Begin
 vPoolerPort := Value;
End;

Procedure TRESTDataBase.SetRestPooler(Value : String);
Begin
 vRestPooler := Value;
End;

Procedure TRESTClientSQL.SetDataBase(Value : TRESTDataBase);
Begin
 if Value is TRESTDataBase then
  vRESTDataBase := Value
 Else
  vRESTDataBase := Nil;
End;

Procedure TRESTClientSQL.SetMasterDataSet(Value : TRESTClientSQL);
Var
 MasterDetailItem : TMasterDetailItem;
Begin
 If (vMasterDataSet <> Nil) Then
  TRESTClientSQL(vMasterDataSet).vMasterDetailList.DeleteDS(TRESTClient(Self));
 If (Value = Self) And (Value <> Nil) Then
  Begin
   vMasterDataSet := Nil;
   MasterSource   := Nil;
   MasterFields   := '';
   Exit;
  End;
 vMasterDataSet := Value;
 If (vMasterDataSet <> Nil) Then
  Begin
   MasterDetailItem         := TMasterDetailItem.Create;
   MasterDetailItem.DataSet := TRESTClient(Self);
   TRESTClientSQL(vMasterDataSet).vMasterDetailList.Add(MasterDetailItem);
   vDataSource.DataSet := Value;
   Try
    MasterSource := vDataSource;
   Except
    vMasterDataSet := Nil;
    MasterSource   := Nil;
    MasterFields   := '';
   End;
  End
 Else
  Begin
   MasterSource := Nil;
   MasterFields := '';
  End;
End;

Procedure TRESTClientSQL.SetMasterFields(Value: String);
Begin

End;

Constructor TRESTClientSQL.Create(AOwner : TComponent);
Begin
 Inherited;
 Owner                             := AOwner;
 vDataCache                        := False;
 vConnectedOnce                    := True;
 vActive                           := False;
 UpdateOptions.CountUpdatedRecords := False;
 vBeforeClone                      := False;
 vCascadeDelete                    := True;
 vSQL                              := TStringList.Create;
 vSQL.OnChange                     := OnChangingSQL;
 vParams                           := TParams.Create;
 vCacheDataDB                      := Self.CloneSource;
 vUpdateTableName                  := '';
 FieldDefsUPD                      := TFieldDefs.Create(Self);
 FieldDefs                         := FieldDefsUPD;
 vMasterDetailList                 := TMasterDetailList.Create;
 OldData                           := TMemoryStream.Create;
 vMasterDataSet                    := Nil;
 vDataSource                       := TDataSource.Create(Nil);
 TFDMemTable(Self).AfterScroll     := ProcAfterScroll;
 TFDMemTable(Self).AfterOpen       := ProcAfterOpen;
 TFDMemTable(Self).AfterInsert     := ProcAfterInsert;
 TFDMemTable(Self).BeforeDelete    := ProcBeforeDelete;
 TFDMemTable(Self).AfterClose      := ProcAfterClose;
 TFDMemTable(Self).BeforePost      := ProcBeforePost;
 Inherited AfterPost               := OldAfterPost;
 Inherited AfterDelete             := OldAfterDelete;
End;

Destructor  TRESTClientSQL.Destroy;
Begin
 vSQL.DisposeOf;
 vParams.DisposeOf;
 FieldDefsUPD.DisposeOf;
 If (vMasterDataSet <> Nil) Then
  TRESTClientSQL(vMasterDataSet).vMasterDetailList.DeleteDS(TRESTClient(Self));
 vMasterDetailList.DisposeOf;
 vDataSource.DisposeOf;
 If vCacheDataDB <> Nil Then
  vCacheDataDB.DisposeOf;
 OldData.DisposeOf;
 Inherited;
End;

Function ReturnParams(SQL : String) : TStringList;
Var
 InitStr,
 FinalStr    : Integer;
 vTempString : String;
 Function CreateParamS(Var Value : String) : String;
 Var
  I      : Integer;
  vTempS : String;
 Begin
  I      := InitStr;
  vTempS := Value;
  Result := '';
  While (vTempS <> '') Do
   Begin
    If vTempS[I] in ['0'..'9', 'a'..'z', 'A'..'Z', '_'] then
     Result := Result + vTempS[I]
    Else
     Break;
    {$IFDEF MSWINDOWS}
    If I = Length(Value) Then
     Break;
    {$ELSE}
    If I = Length(Value) -1 Then
     Break;
    {$ENDIF}
    Inc(I);
   End;
  If (I = Length(Value)) Or (Length(Value) = 1) Then
   Value := ''
  Else
   Value := Copy(Value, Length(Result) + 1, Length(Value));
 End;
Begin
 {$IFDEF MSWINDOWS}
 InitStr   := 1;
 FinalStr  := 0;
 {$ELSE}
 InitStr   := 0;
 FinalStr  := 1;
 {$ENDIF}
 Result := Nil;
 vTempString := StringReplace(SQL, #12, '', [rfReplaceAll]);
 If Pos(':', SQL) > 0 Then
  Begin
   vTempString := Copy(vTempString, Pos(':', vTempString) + 1, Length(vTempString));
   Result := TStringList.Create;
   While vTempString <> '' Do
    Begin
     Result.Add(CreateParamS(vTempString));
     vTempString := Copy(vTempString, Pos(':', vTempString), Length(vTempString));
     If Pos(':', vTempString) = 0 Then
      Break
     Else
      vTempString := Copy(vTempString, Pos(':', vTempString) + 1, Length(vTempString));
    End;
  End;
End;

Procedure TRESTClientSQL.CreateParams;
Var
 I         : Integer;
 ParamList : TStringList;
 Procedure CreateParam(Value : String);
 Var
  FieldDef : TField;
 Begin
  FieldDef := FindField(Value);
  If FieldDef <> Nil Then
   vParams.CreateParam(FieldDef.DataType, Value, ptUnknown)
  Else
   vParams.CreateParam(ftUnknown, Value, ptUnknown);
 End;
Begin
 vParams.Clear;
 ParamList := ReturnParams(vSQL.Text);
 If ParamList <> Nil Then
 For I := 0 to ParamList.Count -1 Do
  CreateParam(ParamList[I]);
End;

Procedure TRESTClientSQL.ProcAfterScroll(DataSet: TDataSet);
Begin
 If State = dsBrowse Then
  Begin
   If Not Active Then
    PrepareDetailsNew
   Else
    Begin
     If RecordCount = 0 Then
      PrepareDetailsNew
     Else
      PrepareDetails(True)
    End;
  End
 Else If State = dsInactive Then
  PrepareDetails(False)
 Else If State = dsInsert Then
  PrepareDetailsNew;
 If Assigned(vOnAfterScroll) Then
  vOnAfterScroll(Dataset);
End;

Procedure TRESTClientSQL.GotoRec(Const RecNo: Integer);
Var
 ActiveRecNo,
 Distance     : Integer;
Begin
 If (RecNo > 0) Then
  Begin
   ActiveRecNo := Self.RecNo;
   If (RecNo <> ActiveRecNo) Then
    Begin
     Self.DisableControls;
     Try
      Distance := RecNo - ActiveRecNo;
      Self.MoveBy(Distance);
     Finally
      Self.EnableControls;
     End;
    End;
  End;
End;

Procedure TRESTClientSQL.ProcBeforeDelete(DataSet: TDataSet);
Var
 I : Integer;
 vDetailClient : TRESTClientSQL;
Begin
 vOldStatus   := State;
 Try
  vActualRec   := RecNo;
 Except
  vActualRec   := -1;
 End;
 OldData.Clear;
 SaveToStream(OldData, TFDStorageFormat.sfBinary);
 If Assigned(vOnBeforeDelete) Then
  vOnBeforeDelete(DataSet);
 If vCascadeDelete Then
  Begin
   For I := 0 To vMasterDetailList.Count -1 Do
    Begin
     vMasterDetailList.Items[I].ParseFields(TRESTClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
     vDetailClient        := TRESTClientSQL(vMasterDetailList.Items[I].DataSet);
     If vDetailClient <> Nil Then
      Begin
       vDetailClient.First;
       While Not vDetailClient.Eof Do
        vDetailClient.Delete;
      End;
    End;
  End;
End;

procedure TRESTClientSQL.ProcBeforePost(DataSet: TDataSet);
Begin
 vOldStatus   := State;
 Try
  vActualRec   := RecNo;
 Except
  vActualRec   := -1;
 End;
 OldData.Clear;
 SaveToStream(OldData, TFDStorageFormat.sfBinary);
 If Assigned(vOnBeforePost) Then
  vOnBeforePost(DataSet);
End;

Procedure TRESTClientSQL.ProcAfterClose(DataSet: TDataSet);
Var
 I : Integer;
 vDetailClient : TRESTClientSQL;
Begin
 If Assigned(vOnAfterClose) then
  vOnAfterClose(Dataset);
 If vCascadeDelete Then
  Begin
   For I := 0 To vMasterDetailList.Count -1 Do
    Begin
     vMasterDetailList.Items[I].ParseFields(TRESTClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
     vDetailClient        := TRESTClientSQL(vMasterDetailList.Items[I].DataSet);
     If vDetailClient <> Nil Then
      vDetailClient.Close;
    End;
  End;
End;

Procedure TRESTClientSQL.ProcAfterInsert(DataSet: TDataSet);
Var
 I : Integer;
 vFields       : TStringList;
 vDetailClient : TRESTClientSQL;
 Procedure CloneDetails(Value : TRESTClientSQL; FieldName : String);
 Begin
  If (FindField(FieldName) <> Nil) And (Value.FindField(FieldName) <> Nil) Then
   FindField(FieldName).Value := Value.FindField(FieldName).Value;
 End;
 Procedure ParseFields(Value : String);
 Var
  vTempFields : String;
 Begin
  vFields.Clear;
  vTempFields := Value;
  While (vTempFields <> '') Do
   Begin
    If Pos(';', vTempFields) > 0 Then
     Begin
      vFields.Add(UpperCase(Trim(Copy(vTempFields, 1, Pos(';', vTempFields) -1))));
      System.Delete(vTempFields, 1, Pos(';', vTempFields));
     End
    Else
     Begin
      vFields.Add(UpperCase(Trim(vTempFields)));
      vTempFields := '';
     End;
    vTempFields := Trim(vTempFields);
   End;
 End;
Begin
 vDetailClient := vMasterDataSet;
 If (vDetailClient <> Nil) And (Fields.Count > 0) Then
  Begin
   vFields     := TStringList.Create;
   ParseFields(MasterFields);
   For I := 0 To vFields.Count -1 Do
    Begin
     If vDetailClient.FindField(vFields[I]) <> Nil Then
      CloneDetails(vDetailClient, vFields[I]);
    End;
   vFields.DisposeOf;
  End;
 If Assigned(vOnAfterInsert) Then
  vOnAfterInsert(Dataset);
End;

Procedure TRESTClientSQL.ProcAfterOpen(DataSet: TDataSet);
Begin
 If Assigned(vOnAfterOpen) Then
  vOnAfterOpen(Dataset);
End;

Function  TRESTClientSQL.ApplyUpdates(Var Error : String) : Boolean;
var
 LDeltaList    : TFDJSONDeltas;
 vError        : Boolean;
 vMessageError : String;
 Function GetDeltas : TFDJSONDeltas;
 Begin
  TFDMemTable(Self).UpdateOptions.CountUpdatedRecords := False;
  If TFDMemTable(Self).State In [dsEdit, dsInsert] Then
   TFDMemTable(Self).Post;
  Result := TFDJSONDeltas.Create;
  TFDJSONDeltasWriter.ListAdd(Result, vUpdateTableName, TFDMemTable(Self));
 End;
Begin
 LDeltaList := GetDeltas;
 If Assigned(vRESTDataBase) And (Trim(UpdateTableName) <> '') Then
  vRESTDataBase.ApplyUpdates(vSQL, vParams, LDeltaList, Trim(vUpdateTableName), vError, vMessageError)
 Else
  Begin
   vError := True;
   If Not Assigned(vRESTDataBase) Then
    vMessageError := 'No RESTDatabase defined'
   Else
    vMessageError := 'No UpdateTableName defined';
  End;
 Result       := Not vError;
 Error        := vMessageError;
 vErrorBefore := vError;
 If (Result) And (Not(vError)) Then
  TFDMemTable(Self).ApplyUpdates(-1)
 Else If vError Then
  Begin
   TFDMemTable(Self).Close;
   OldData.Position := 0;
   LoadFromStream(OldData, TFDStorageFormat.sfBinary);
   Try
    If vActualRec > -1 Then
     GoToRec(vActualRec);
   Except
   End;
  End;
End;

Function  TRESTClientSQL.ParamByName(Value : String) : TParam;
Var
 I : Integer;
 vParamName,
 vTempParam : String;
 Function CompareValue(Value1, Value2 : String) : Boolean;
 Var
  InitStr,
  FinalStr,
  I         : Integer;
 Begin
  Result := False;
  {$IFDEF MSWINDOWS}
  InitStr   := 1;
  FinalStr  := 0;
  {$ELSE}
  InitStr   := 0;
  FinalStr  := 1;
  {$ENDIF}
  Result := Value1 = Value2;
 End;
Begin
 Result := Nil;
 For I := 0 to vParams.Count -1 do
  Begin
   vParamName := UpperCase(vParams[I].Name);
   vTempParam := UpperCase(Trim(Value));
   if CompareValue(vTempParam, vParamName) then
    Begin
     Result := vParams[I];
     Break;
    End;
  End;
End;

Procedure TRESTClientSQL.ExecSQL;
Var
 vError        : Boolean;
 vMessageError : String;
Begin
 Try
  vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, True);
 Except
 End;
End;

Function TRESTClientSQL.InsertMySQLReturnID : Integer;
Var
 vError        : Boolean;
 vMessageError : String;
Begin
 Try
  Result := vRESTDataBase.InsertMySQLReturnID(vSQL, vParams, vError, vMessageError);
 Except
  Result := -1;
 End;
End;

Procedure TRESTClientSQL.OnChangingSQL(Sender: TObject);
Begin
 CreateParams;
End;

Procedure TRESTClientSQL.SetSQL(Value : TStringList);
Var
 I : Integer;
Begin
 vSQL.Clear;
 For I := 0 To Value.Count -1 do
  vSQL.Add(Value[I]);

End;

Procedure TRESTClientSQL.CreateDataSet;
Begin
 vCreateDS := True;
 Inherited CreateDataSet;
 vCreateDS := False;
 vActive   := Self.Active;
End;

Procedure TRESTClientSQL.Close;
Begin
 vActive := False;
 Inherited Close;
 If TFDMemTable(Self).Fields.Count = 0 Then
  TFDMemTable(Self).FieldDefs.Clear;
End;

Function TRESTClientSQL.CanObserve(const ID: Integer): Boolean;
begin
  case ID of
    TObserverMapping.EditLinkID,      { EditLinkID is the observer that is used for control-to-field links }
    TObserverMapping.ControlValueID:
      Result := True;
  else
    Result := False;
  end;
end;

Procedure TRESTClientSQL.Open;
Begin
 If Not vActive Then
  SetActiveDB(True);
 If vActive Then
  Inherited Open;
End;

Procedure TRESTClientSQL.OpenCursor(InfoQuery: Boolean);
Begin
 If Not vBeforeClone Then
  Begin
   vBeforeClone := True;
   If vRESTDataBase <> Nil Then
    Begin
     vRESTDataBase.Active := True;
     If vRESTDataBase.Active Then
      Begin
       Try
        Try
         If Not (vActive) And (Not (vCreateDS)) Then
          Begin
           If GetData Then
            Begin
             If Not (csDesigning in ComponentState) Then
              vActive := True;
             Inherited OpenCursor(InfoQuery);
            End;
          End
         Else
          Inherited OpenCursor(InfoQuery);
         If Assigned(vOnGetDataError) Then
          vOnGetDataError(True, '');
        Except
         On E : Exception do
          Begin
           If Assigned(vOnGetDataError) Then
            vOnGetDataError(False, E.Message);
          End;
        End;
       Finally
        vBeforeClone := False;
       End;
      End;
    End;
  End;
End;

Procedure TRESTClientSQL.OldAfterPost(DataSet: TDataSet);
Begin
 vErrorBefore := False;
 if Assigned(vOnAfterPost) then
  vOnAfterPost(Self);
 if Not vErrorBefore then
  TFDMemTable(Self).CommitUpdates;
End;

Procedure TRESTClientSQL.OldAfterDelete(DataSet: TDataSet);
Begin
 vErrorBefore := False;
 If Assigned(vOnAfterDelete) Then
  vOnAfterDelete(Self);
 If Not vErrorBefore Then
  TFDMemTable(Self).CommitUpdates;
End;

Procedure TRESTClientSQL.SetUpdateTableName(Value : String);
Begin
 vCommitUpdates                  := Trim(Value) <> '';
 TFDMemTable(Self).CachedUpdates := vCommitUpdates;
 vUpdateTableName                := Value;
End;

Procedure TRESTClientSQL.Loaded;
Begin
 Inherited Loaded;
End;

Procedure ExecMethod(Execute : TExecuteProc = Nil);
Var
 EffectThread : TThread;
Begin
 EffectThread.CreateAnonymousThread(Procedure
                                    Begin
                                     //Se precisar interagir com a Thread da Interface
                                     If Assigned(Execute) Then
                                      TThread.Synchronize (TThread.CurrentThread,
                                                           Procedure
                                                           Begin
                                                            Execute;
                                                            EffectThread.DisposeOf;
                                                           End);
                                    End).Start;
End;

Procedure TRESTClientSQL.CloneDefinitions(Source : TFDMemTable; aSelf : TRESTClientSQL);
Var
 I, A : Integer;
Begin
 aSelf.Close;
 For I := 0 to Source.FieldDefs.Count -1 do
  Begin
   For A := 0 to aSelf.FieldDefs.Count -1 do
    If Uppercase(Source.FieldDefs[I].Name) = Uppercase(aSelf.FieldDefs[A].Name) Then
     Begin
      aSelf.FieldDefs.Delete(A);
      Break;
     End;
  End;
 For I := 0 to Source.FieldDefs.Count -1 do
  Begin
   With aSelf.FieldDefs.AddFieldDef Do
    Begin
     Name     := Source.FieldDefs[I].Name;
     DataType := Source.FieldDefs[I].DataType;
     Size     := Source.FieldDefs[I].Size;
     Required := Source.FieldDefs[I].Required;
    End;
  End;
 If aSelf.FieldDefs.Count > 0 Then
  aSelf.CreateDataSet;
End;

Procedure TRESTClientSQL.PrepareDetailsNew;
Var
 I : Integer;
 vDetailClient : TRESTClientSQL;
Begin
 For I := 0 To vMasterDetailList.Count -1 Do
  Begin
   vMasterDetailList.Items[I].ParseFields(TRESTClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
   vDetailClient        := TRESTClientSQL(vMasterDetailList.Items[I].DataSet);
   If vDetailClient <> Nil Then
    Begin
     If vDetailClient.Active Then
      Begin
       vDetailClient.EmptyDataSet;
       vDetailClient.ProcAfterScroll(vDetailClient);
      End;
    End;
  End;
End;

Procedure TRESTClientSQL.PrepareDetails(ActiveMode : Boolean);
Var
 I : Integer;
 vDetailClient : TRESTClientSQL;
 Procedure CloneDetails(Value : TRESTClientSQL);
 Var
  I : Integer;
 Begin
  For I := 0 To Value.Params.Count -1 Do
   Begin
    If FindField(Value.Params[I].Name) <> Nil Then
     Begin
      Value.Params[I].DataType := FindField(Value.Params[I].Name).DataType;
      Value.Params[I].Size     := FindField(Value.Params[I].Name).Size;
      Value.Params[I].Value    := FindField(Value.Params[I].Name).Value;
     End;
   End;
 End;
Begin
 For I := 0 To vMasterDetailList.Count -1 Do
  Begin
   vMasterDetailList.Items[I].ParseFields(TRESTClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
   vDetailClient        := TRESTClientSQL(vMasterDetailList.Items[I].DataSet);
   If vDetailClient <> Nil Then
    Begin
     vDetailClient.Active := False;
     CloneDetails(vDetailClient);
     vDetailClient.Active := ActiveMode;
    End;
  End;
End;

Function TRESTClientSQL.GetData : Boolean;
Var
 LDataSetList  : TFDJSONDataSets;
 vError        : Boolean;
 vMessageError : String;
 vTempTable    : TFDMemTable;
Begin
 Result := False;
 Self.Close;
 If Assigned(vRESTDataBase) Then
  Begin
   Try
    LDataSetList := vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, False);
    If LDataSetList <> Nil Then
     Begin
      vTempTable := TFDMemTable.Create(Nil);
      vTempTable.UpdateOptions.CountUpdatedRecords := False;
      Try
       Assert(TFDJSONDataSetsReader.GetListCount(LDataSetList) = 1);
       vTempTable.AppendData(TFDJSONDataSetsReader.GetListValue(LDataSetList, 0));
       CloneDefinitions(vTempTable, Self);
       If LDataSetList <> Nil Then
        Begin
         AppendData(TFDJSONDataSetsReader.GetListValue(LDataSetList, 0));
         Result := True;
        End;
      Except
      End;
      vTempTable.DisposeOf;
     End;
   Except
    If LDataSetList <> Nil Then
     LDataSetList.DisposeOf;
   End;
  End;
End;

Procedure TRESTClientSQL.SetActiveDB(Value : Boolean);
Begin
 vActive := False;
 if (vRESTDataBase <> Nil) And (Value) Then
  Begin
   If vRESTDataBase <> Nil Then
    If Not vRESTDataBase.Active Then
     vRESTDataBase.Active := True;
   If Not vRESTDataBase.Active then
    Exit;
   Try
    If Not(vActive) And (Value) Then
     vActive := GetData;
    If Assigned(vOnGetDataError) Then
     vOnGetDataError(True, '');
    If State = dsBrowse Then
     PrepareDetails(True)
    Else If State = dsInactive Then
     PrepareDetails(False);
   Except
    On E : Exception do
     Begin
      if Assigned(vOnGetDataError) then
       vOnGetDataError(False, E.Message);
     End;
   End;
  End
 Else
  Begin
   vActive := False;
   Close;
  End;
End;

end.
