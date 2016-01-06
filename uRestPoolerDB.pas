{
 Esse pacote de Componentes foi desenhado com o Objetivo de ajudar as pessoas a desenvolverem
com WebServices REST o mais pr�ximo poss�vel do desenvolvimento local DB, com componentes de
f�cil configura��o para que todos tenham acesso as maravilhas dos WebServices REST/JSON DataSnap.

Desenvolvedor Principal : Gilberto Rocha da Silva (XyberX)
Empresa : XyberPower Desenvolvimento
}

unit uRestPoolerDB;

interface

uses System.SysUtils,         System.Classes,           Datasnap.DSProxyRest, Datasnap.DSServer,
     FireDAC.Stan.Intf,       FireDAC.Stan.Option,      FireDAC.Stan.Param,   Datasnap.DSAuth,
     FireDAC.Stan.Error,      FireDAC.DatS,             FireDAC.Phys.Intf,    FireDAC.DApt.Intf,
     FireDAC.Stan.Async,      FireDAC.DApt,             FireDAC.UI.Intf,
     FireDAC.Stan.Def,        FireDAC.Stan.Pool,        FireDAC.Phys,         Data.DB,
     FireDAC.Comp.Client,     FireDAC.Comp.UI,          FireDAC.Comp.DataSet, Data.FireDACJSONReflect,
     System.JSON,             FireDAC.Stan.StorageBin,  FireDAC.Stan.StorageJSON,
     FireDAC.Phys.IBDef,      IPPeerClient,             Datasnap.DSClientRest,
     System.SyncObjs,         Data.DBXJSONReflect,      uPoolerMethod,        System.TypInfo;

Type
 TOnEventDB = Procedure (DataSet: TDataSet) of Object;

Type
 TOnEventConnection = Procedure (Sucess : Boolean; Const Error : String) of Object;

Type
 TOnEventTimer = Procedure of Object;

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
  vConnected           : Boolean;                    //Diz o Estado da Conex�o
  vOnEventConnection   : TOnEventConnection;         //Evento de Estado da Conex�o
  vAutoCheckData       : TAutoCheckData;             //Autocheck de Conex�o
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
 Public
  Function    GetRestPoolers : TStringList;          //Retorna a Lista de DataSet Sources do Pooler
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
 Published
  Property OnConnection    : TOnEventConnection Read vOnEventConnection Write vOnEventConnection; //Evento relativo a tudo que acontece quando tenta conectar ao Servidor
  Property Active          : Boolean            Read vConnected         Write SetConnection;      //Seta o Estado da Conex�o
  Property MyIP            : String             Read vMyIP;
  Property Login           : String             Read vLogin             Write vLogin;             //Login do Usu�rio caso haja autentica��o
  Property Password        : String             Read vPassword          Write vPassword;          //Senha do Usu�rio caso haja autentica��o
  Property Proxy           : Boolean            Read vProxy             Write vProxy;             //Diz se tem servidor Proxy
  Property ProxyOptions    : TProxyOptions      Read vProxyOptions      Write vProxyOptions;      //Se tem Proxy diz quais as op��es
  Property PoolerService   : String             Read vRestWebService    Write vRestWebService;    //Host do WebService REST
  Property PoolerURL       : String             Read vRestURL           Write vRestURL;           //URL do WebService REST
  Property PoolerPort      : Integer            Read vPoolerPort        Write SetPoolerPort;      //A Porta do Pooler do DataSet
  Property PoolerName      : String             Read vRestPooler        Write SetRestPooler;      //Qual o Pooler de Conex�o ligado ao componente
  Property RestModule      : String             Read vRestModule        Write vRestModule;        //Classe do Servidor REST Principal
  Property StateConnection : TAutoCheckData     Read vAutoCheckData     Write vAutoCheckData;     //Autocheck da Conex�o
End;

Type
 TRESTClientSQL   = Class(TFDMemTable)              //Classe com as funcionalidades de um DBQuery
 Private
  Owner               : TComponent;
  vUpdateTableName    : String;                     //Tabela que ser� feito Update no Servidor se for usada Reflex�o de Dados
  vDataCache,                                       //Se usa cache local
  vConnectedOnce,                                   //Verifica se foi conectado ao Servidor
  vCommitUpdates,
  vErrorBefore,
  vActive              : Boolean;                   //Estado do Dataset
  vSQL                 : TStringList;               //SQL a ser utilizado na conex�o
  vParams              : TParams;                   //Parametros de Dataset
  vCacheDataDB         : TFDDataset;                //O Cache de Dados Salvo para utiliza��o r�pida
  vOnGetDataError      : TOnEventConnection;        //Se deu erro na hora de receber os dados ou n�o
  vRESTDataBase        : TRESTDataBase;             //RESTDataBase do Dataset
  vOnAfterDelete,
  vOnAfterPost         : TDataSetNotifyEvent;
  Procedure OnChangingSQL(Sender: TObject);         //Quando Altera o SQL da Lista
  Procedure SetActiveDB(Value : Boolean);           //Seta o Estado do Dataset
  Procedure SetSQL(Value : TStringList);            //Seta o SQL a ser usado
  Procedure CreateParams;                           //Cria os Parametros na lista de Dataset
  Procedure SetDataBase(Value : TRESTDataBase);     //Diz o REST Database
  Procedure GetData;                                //Recebe os Dados da Internet vindo do Servidor REST
  Procedure SetUpdateTableName(Value : String);     //Diz qual a tabela que ser� feito Update no Banco
  Procedure OldAfterPost(DataSet: TDataSet);        //Eventos do Dataset para realizar o AfterPost
  Procedure OldAfterDelete(DataSet: TDataSet);      //Eventos do Dataset para realizar o AfterDelete
 Public
  //M�todos
  Procedure   Open;                                 //M�todo Open que ser� utilizado no Componente
  Procedure   Close;                                //M�todo Close que ser� utilizado no Componente
  Procedure   ExecSQL;                              //M�todo ExecSQL que ser� utilizado no Componente
  Function    ParamByName(Value : String) : TParam; //Retorna o Parametro de Acordo com seu nome
  Function    ApplyUpdates(var Error : String) : Boolean;
  Constructor Create(AOwner : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                     //Destroy a Classe
 Published
  Property AfterDelete     : TDataSetNotifyEvent Read vOnAfterDelete            Write vOnAfterDelete;
  Property AfterPost       : TDataSetNotifyEvent Read vOnAfterPost              Write vOnAfterPost;
  Property OnGetDataError  : TOnEventConnection  Read vOnGetDataError           Write vOnGetDataError;         //Recebe os Erros de ExecSQL ou de GetData
  Property Active          : Boolean             Read vActive                   Write SetActiveDB;             //Estado do Dataset
  Property DataCache       : Boolean             Read vDataCache                Write vDataCache;              //Diz se ser� salvo o �ltimo Stream do Dataset
  Property Params          : TParams             Read vParams                   Write vParams;                 //Parametros de Dataset
  Property DataBase        : TRESTDataBase       Read vRESTDataBase             Write SetDataBase;             //Database REST do Dataset
  Property SQL             : TStringList         Read vSQL                      Write SetSQL;                  //SQL a ser Executado
  Property UpdateTableName : String              Read vUpdateTableName          Write SetUpdateTableName;      //Tabela que ser� usada para Reflex�o de Dados
End;

Type
 TRESTPoolerDBP = ^TComponent;
 TRESTPoolerDB  = Class(TComponent)
 Private
  Owner          : TComponent;
  FLock          : TCriticalSection;
  vFDConnectionBack,
  vFDConnection  : TFDConnection;
//  vFDTransaction : TFDTransaction;
//  Procedure CopyConnection(CopyDBConnection : TFDConnection;
//                           Var DBConnection : TFDConnection;
//                           Var WriteTrans   : TFDTransaction);
  Procedure SetConnection(Value : TFDConnection);
  Function  GetConnection : TFDConnection;
 Public
  Procedure ApplyChanges(TableName,
                         SQL        : String;
                         Params     : TParams;
                         Var Error  : Boolean;
                         Var MessageError : String;
                         Const ADeltaList: TFDJSONDeltas);Overload;
  Procedure ApplyChanges(TableName,
                         SQL        : String;
                         Var Error  : Boolean;
                         Var MessageError : String;
                         Const ADeltaList: TFDJSONDeltas);Overload;
  Function ExecuteCommand(SQL        : String;
                          Var Error  : Boolean;
                          Var MessageError : String;
                          Execute    : Boolean = False) : TFDJSONDataSets;Overload;
  Function ExecuteCommand(SQL              : String;
                          Params           : TParams;
                          Var Error        : Boolean;
                          Var MessageError : String;
                          Execute          : Boolean = False) : TFDJSONDataSets;Overload;
 Published
  Property    Database : TFDConnection Read GetConnection Write SetConnection;
  Constructor Create(AOwner : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                     //Destroy a Classe
End;

Procedure Register;

implementation

Procedure Register;
Begin
 RegisterComponents('REST Dataware', [TRESTPoolerDB, TRESTDataBase, TRESTClientSQL]);
End;

Function EncodeStrings(Value : String) : String;
Begin
 Result := StringReplace(Value,  '%', '|:|', [rfReplaceAll, rfIgnoreCase]); //Sinal de %
 Result := StringReplace(Result, '/', '|*|', [rfReplaceAll, rfIgnoreCase]); //Sinal de /
 Result := StringReplace(Result, '-', '|A|', [rfReplaceAll, rfIgnoreCase]); //Sinal de -
 Result := StringReplace(Result, '.', '|B|', [rfReplaceAll, rfIgnoreCase]); //Sinal de .
End;

Function DecodeStrings(Value : String) : String;
Begin
 Result := StringReplace(Value,  '|:|', '%', [rfReplaceAll, rfIgnoreCase]); //Sinal de %
 Result := StringReplace(Result, '|*|', '/', [rfReplaceAll, rfIgnoreCase]); //Sinal de /
 Result := StringReplace(Result, '|A|', '-', [rfReplaceAll, rfIgnoreCase]); //Sinal de -
 Result := StringReplace(Result, '|B|', '.', [rfReplaceAll, rfIgnoreCase]); //Sinal de .
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

Function TRESTPoolerDB.ExecuteCommand(SQL        : String;
                                      Var Error  : Boolean;
                                      Var MessageError : String;
                                      Execute    : Boolean = False) : TFDJSONDataSets;
Var
 vTempQuery : TFDQuery;
Begin
 Result := Nil;
 Error  := False;
 vTempQuery               := TFDQuery.Create(Owner);
 Try
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL));
  If Not Execute Then
   Begin
    vTempQuery.Active := True;
    Result            := TFDJSONDataSets.Create;
    TFDJSONDataSetsWriter.ListAdd(Result, vTempQuery);
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
 vTempQuery : TFDQuery;
 I          : Integer;
Begin
 Result := Nil;
 Error  := False;
 vTempQuery               := TFDQuery.Create(Owner);
 Try
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL));
  If Params <> Nil Then
   Begin
    For I := 0 To Params.Count -1 Do
     Begin
      If vTempQuery.ParamCount > I Then
       Begin
        If vTempQuery.ParamByName(Params[I].Name) <> Nil Then
         vTempQuery.ParamByName(Params[I].Name).Value := Params[I].Value;
       End
      Else
       Break;
     End;
   End;
  If Not Execute Then
   Begin
    vTempQuery.Active := True;
    Result            := TFDJSONDataSets.Create;
    TFDJSONDataSetsWriter.ListAdd(Result, vTempQuery);
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

Procedure TRESTPoolerDB.ApplyChanges(TableName,
                                     SQL              : String;
                                     Var Error        : Boolean;
                                     Var MessageError : String;
                                     Const ADeltaList : TFDJSONDeltas);
Var
 vTempQuery : TFDQuery;
 LApply     : IFDJSONDeltasApplyUpdates;
begin
 Error                    := False;
 vTempQuery               := TFDQuery.Create(Owner);
 Try
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL));
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
                                     SQL              : String;
                                     Params           : TParams;
                                     Var Error        : Boolean;
                                     Var MessageError : String;
                                     Const ADeltaList : TFDJSONDeltas);
Var
 I          : Integer;
 vTempQuery : TFDQuery;
 LApply     : IFDJSONDeltasApplyUpdates;
begin
 Error  := False;
 vTempQuery               := TFDQuery.Create(Owner);
 Try
  vTempQuery.Connection   := vFDConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL));
  If Params <> Nil Then
   Begin
    For I := 0 To Params.Count -1 Do
     Begin
      If vTempQuery.ParamCount > I Then
       Begin
        If vTempQuery.ParamByName(Params[I].Name) <> Nil Then
         vTempQuery.ParamByName(Params[I].Name).Value := Params[I].Value;
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
 Owner := aOwner;
 FLock := TCriticalSection.Create;
End;

Destructor  TRESTPoolerDB.Destroy;
Begin
 FLock.Release;
 FLock.DisposeOf;
 Inherited;
End;

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

Procedure TRESTDataBase.SetConnectionOptions(Var Value : TDSRestConnection);
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
 Try
  If Params.Count > 0 Then
   vRESTConnectionDB.ApplyChanges(vRestPooler,
                                  vRestModule,
                                  TableName,
                                  GetLineSQL(SQL),
                                  Params,
                                  ADeltaList,
                                  Error,
                                  MessageError)
  Else
   vRESTConnectionDB.ApplyChangesPure(vRestPooler,
                                      vRestModule,
                                      TableName,
                                      GetLineSQL(SQL),
                                      ADeltaList,
                                      Error,
                                      MessageError);
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

Function TRESTDataBase.ExecuteCommand(Var SQL    : TStringList;
                                      Var Params : TParams;
                                      Var Error  : Boolean;
                                      Var MessageError : String;
                                      Execute    : Boolean = False) : TFDJSONDataSets;
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
 Result := Nil;
 if vRestPooler = '' then
  Exit;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 Try
  If Params.Count > 0 Then
   Result := vRESTConnectionDB.ExecuteCommand(vRestPooler,
                                              vRestModule, GetLineSQL(SQL),
                                              Params, Error,
                                              MessageError, Execute)
  Else
   Result := vRESTConnectionDB.ExecuteCommandPure(vRestPooler,
                                                  vRestModule,
                                                  GetLineSQL(SQL), Error,
                                                  MessageError, Execute);
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
 Try
  vTempList        := vRESTConnectionDB.PoolersDataSet(vRestModule);
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

Constructor TRESTDataBase.Create(AOwner : TComponent);
Begin
 Inherited;
 Owner                     := AOwner;
 vLogin                    := '';
 vMyIP                     := '0.0.0.0';
 vPassword                 := vLogin;
 vRestModule               := 'TServerMethods1';
 vRestPooler               := vPassword;
 vPoolerPort               := 8081;
 vProxy                    := False;
 vProxyOptions             := TProxyOptions.Create;
 vAutoCheckData            := TAutoCheckData.Create;
 vAutoCheckData.vAutoCheck := False;
 vAutoCheckData.vInTime    := 1000;
 vAutoCheckData.vEvent     := CheckConnection;
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
 Try
  vTempResult := vRESTConnectionDB.EchoPooler(vTempSend, vRestModule);
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
 vConnected := Value;
 if vConnected then
  vConnected := TryConnect
 Else
  vMyIP := '';
End;

Procedure TRESTDataBase.SetPoolerPort(Value : Integer);
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

Constructor TRESTClientSQL.Create(AOwner : TComponent);
Begin
 Inherited;
 Owner             := AOwner;
 vDataCache        := False;
 vConnectedOnce    := True;
 vActive           := False;
 vSQL              := TStringList.Create;
 vSQL.OnChange     := OnChangingSQL;
 vParams           := TParams.Create(Self);
 vCacheDataDB      := Self.CloneSource;
 vUpdateTableName  := '';
 Inherited AfterPost   := OldAfterPost;
 Inherited AfterDelete := OldAfterDelete;
End;

Destructor  TRESTClientSQL.Destroy;
Begin
 vSQL.DisposeOf;
 vParams.DisposeOf;
 If vCacheDataDB <> Nil Then
  vCacheDataDB.DisposeOf;
 Inherited;
End;

Procedure TRESTClientSQL.CreateParams;
Var
 I,  X      : Integer;
 vTempLine,
 vTempBuff,
 vParamName : String;
 Procedure CreateParam(Value : String);
 Begin
  vParams.CreateParam(ftUnknown, Value, ptUnknown);
 End;
 Function InBreakChar(Value : Char) : Boolean;
 Begin
  Result := CharInSet(Value, [' ', ')', '(', '=', '<', '>', '[', ']', '}', '{']);
 End;
Begin
 vParams.Clear;
 For I := 0 to vSQL.Count -1 Do
  Begin
   vTempLine := vSQL[I];
   While vTempLine <> '' Do
    Begin
     If Pos(':', vTempLine) > 0 Then
      Begin
       System.Delete(vTempLine, 1, Pos(':', vTempLine));
       vTempBuff := vTempLine;
       If Length(vTempBuff) = 0 then
        X := 0
       Else
        X := 1;
       vParamName := '';
       If Length(vTempBuff) > 0 then
        While (Not InBreakChar(vTempBuff[X])) Do
         Begin
          vParamName := vParamName + vTempBuff[X];
          Inc(X);
          If X > Length(vTempBuff) then
           Break;
         End;
       If X <= Length(vTempBuff) then
        System.Delete(vTempLine, 1, X)
       Else
        System.Delete(vTempLine, 1, Length(vTempLine));
       CreateParam(vParamName);
      End
     Else
      vTempLine := '';
    End;
  End;
End;

Function  TRESTClientSQL.ApplyUpdates(Var Error : String) : Boolean;
var
 LDeltaList    : TFDJSONDeltas;
 vError        : Boolean;
 vMessageError : String;
 Function GetDeltas : TFDJSONDeltas;
 Begin
  if TFDMemTable(Self).State in [dsEdit, dsInsert] then
   TFDMemTable(Self).Post;
  Result := TFDJSONDeltas.Create;
  TFDJSONDeltasWriter.ListAdd(Result, UpdateTableName, TFDMemTable(Self));
 End;
Begin
 LDeltaList := GetDeltas;
 If Assigned(vRESTDataBase) And (Trim(UpdateTableName) <> '') Then
  vRESTDataBase.ApplyUpdates(vSQL, vParams, LDeltaList, Trim(UpdateTableName), vError, vMessageError)
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
End;

Function  TRESTClientSQL.ParamByName(Value : String) : TParam;
Var
 I : Integer;
Begin
 Result := Nil;
 For I := 0 to vParams.Count -1 do
  Begin
   if UpperCase(vParams[I].Name) = UpperCase(Value) then
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
 vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, True);
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

Procedure TRESTClientSQL.Close;
Begin
 TFDMemTable(Self).Close;
 If TFDMemTable(Self).Fields.Count = 0 Then
  TFDMemTable(Self).FieldDefs.Clear;
End;

Procedure TRESTClientSQL.Open;
Begin
 TFDMemTable(Self).Open;
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

Procedure TRESTClientSQL.GetData;
Var
 LDataSetList  : TFDJSONDataSets;
 vError        : Boolean;
 vMessageError : String;
 vTempTable    : TFDMemTable;
 Procedure CloneDefinitions(Source : TFDMemTable; Var Dest : TRESTClientSQL);
 Var
  I, A : Integer;
 Begin
  Dest.Close;
  For I := 0 to Source.FieldDefs.Count -1 do
   Begin
    For A := 0 to Dest.FieldDefs.Count -1 do
     If Uppercase(Source.FieldDefs[I].Name) = Uppercase(Dest.FieldDefs[A].Name) Then
      Begin
       Dest.FieldDefs.Delete(A);
       Break;
      End;
   End;
  For I := 0 to Source.FieldDefs.Count -1 do
   Begin
    With Dest.FieldDefs.AddFieldDef Do
     Begin
      Name     := Source.FieldDefs[I].Name;
      DataType := Source.FieldDefs[I].DataType;
      Size     := Source.FieldDefs[I].Size;
      Required := Source.FieldDefs[I].Required;
     End;
   End;
  If Dest.FieldDefs.Count > 0 Then
   Dest.CreateDataSet;
 End;
Begin
 Close;
 If Assigned(vRESTDataBase) Then
  Begin
   LDataSetList := vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, False);
   If LDataSetList <> Nil Then
    Begin
     vTempTable := TFDMemTable.Create(Nil);
     Assert(TFDJSONDataSetsReader.GetListCount(LDataSetList) = 1);
     vTempTable.AppendData(TFDJSONDataSetsReader.GetListValue(LDataSetList, 0));
     Self.Close;
     Try
      CloneDefinitions(vTempTable, Self);
      AppendData(TFDJSONDataSetsReader.GetListValue(LDataSetList, 0));
     Finally
      vTempTable.DisposeOf;
     End;
    End;
  End;
End;

Procedure TRESTClientSQL.SetActiveDB(Value : Boolean);
Begin
 vActive := False;
 if (vRESTDataBase <> Nil) And (Value) Then
  Begin
   if Not vRESTDataBase.Active then
    Exit;
   Try
    GetData;
    vActive := True;
    If Assigned(vOnGetDataError) Then
     vOnGetDataError(True, '');
   Except
    On E : Exception do
     Begin
      if Assigned(vOnGetDataError) then
       vOnGetDataError(False, E.Message);
     End;
   End;
  End
 Else
  Close;
End;

end.
