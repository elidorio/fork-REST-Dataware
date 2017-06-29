unit uRESTDWBase;

{
  REST Dataware vers�o CORE.
  Criado por XyberX (Gilbero Rocha da Silva), o REST Dataware tem como objetivo o uso de REST/JSON
 de maneira simples, em qualquer Compilador Pascal (Delphi, Lazarus e outros...).
  O REST Dataware tamb�m tem por objetivo levar componentes compat�veis entre o Delphi e outros Compiladores
 Pascal e com compatibilidade entre sistemas operacionais.
  Desenvolvido para ser usado de Maneira RAD, o REST Dataware tem como objetivo principal voc� usu�rio que precisa
 de produtividade e flexibilidade para produ��o de Servi�os REST/JSON, simplificando o processo para voc� programador.

 Membros do Grupo :

 XyberX (Gilberto Rocha) - Admin - Criador e Administrador do CORE do pacote.
 Ivan Cesar              - Admin - Administrador do CORE do pacote.
 Giovani da Cruz         - Admin - Administrador do CORE do pacote.
 Alexandre Abbade        - Admin - Administrador do desenvolvimento de DEMOS, coordenador do Grupo.
 Mizael Rocha            - Member Tester and DEMO Developer.
 Fl�vio Motta            - Member Tester and DEMO Developer.
 Itamar Gaucho           - Member Tester and DEMO Developer.
}

interface

Uses
     {$IFDEF FPC}
     SysUtils,         Classes, SysTypes, ServerUtils, {$IFDEF WINDOWS}Windows,{$ENDIF}
     IdContext,        IdHTTPServer,      IdCustomHTTPServer,    IdSSLOpenSSL, IdSSL,
     IdAuthentication, IdHTTPHeaderInfo,  uDWJSONTools,          uDWConsts,    IdHTTP,
     uDWJSONObject;
     {$ELSE}
     System.SysUtils,  System.Classes,   SysTypes, ServerUtils, Windows,
     IdContext,        IdHTTPServer,     IdCustomHTTPServer,    IdSSLOpenSSL, IdSSL,
     IdAuthentication, IdHTTPHeaderInfo, uDWJSONTools,          uDWConsts,    IdHTTP,
     uDWJSONObject;
     {$ENDIF}

Type
 TLastRequest  = Procedure (Value     : String)                  Of Object;
 TLastResponse = Procedure (Value     : String)                  Of Object;
 TReplyEvent   = Procedure (SendType  : TSendEvent;
                            Arguments : TArguments)              Of Object;
 TEventContext = Procedure (AContext      : TIdContext;
                            ARequestInfo  : TIdHTTPRequestInfo;
                            AResponseInfo : TIdHTTPResponseInfo) Of Object;

Type
 TProxyOptions = Class(TPersistent)
 Private
  vServer,                  //Servidor Proxy na Rede
  vLogin,                   //Login do Servidor Proxy
  vPassword     : String;   //Senha do Servidor Proxy
  vPort         : Integer;  //Porta do Servidor Proxy
 Public
  Constructor Create;
  Procedure   Assign(Source : TPersistent); Override;
 Published
  Property Server        : String  Read vServer   Write vServer;   //Servidor Proxy na Rede
  Property Port          : Integer Read vPort     Write vPort;     //Porta do Servidor Proxy
  Property Login         : String  Read vLogin    Write vLogin;    //Login do Servidor
  Property Password      : String  Read vPassword Write vPassword; //Senha do Servidor
End;

Type
 TRESTServicePooler = Class(TComponent)
 Protected
  Procedure aCommandGet  (AContext      : TIdContext;
                          ARequestInfo  : TIdHTTPRequestInfo;
                          AResponseInfo : TIdHTTPResponseInfo);
  Procedure aCommandOther(AContext      : TIdContext;
                          ARequestInfo  : TIdHTTPRequestInfo;
                          AResponseInfo : TIdHTTPResponseInfo);
 Private
  vActive          : Boolean;
  vProxyOptions    : TProxyOptions;
  HTTPServer       : TIdHTTPServer;
  vServicePort     : Integer;
  vServerMethod    : TClass;
  vServerParams    : TServerParams;
  vLastRequest     : TLastRequest;
  vLastResponse    : TLastResponse;
  {$IFDEF FPC} {$IFDEF WINDOWS}
  vCriticalSection : TRTLCriticalSection;
  {$ENDIF}{$ENDIF}
  lHandler         : TIdServerIOHandlerSSLOpenSSL;
  aSSLVersion      : TIdSSLVersion;
  vServerContext,
  ASSLPrivateKeyFile,
  ASSLPrivateKeyPassword,
  ASSLCertFile     : String;
  VEncondig        : TEncodeSelect;              //Enconding se usar CORS usar UTF8 - Alexandre Abade
  Procedure GetSSLPassWord(Var Password: String);
  Procedure SetActive(Value : Boolean);
  Function  GetSecure : Boolean;
 Public
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
 Published
  Property Active                : Boolean         Read vActive                Write SetActive;
  Property Secure                : Boolean         Read GetSecure;
  Property ServicePort           : Integer         Read vServicePort           Write vServicePort;  //A Porta do Servi�o do DataSet
  Property ProxyOptions          : TProxyOptions   Read vProxyOptions          Write vProxyOptions; //Se tem Proxy diz quais as op��es
  Property ServerParams          : TServerParams   Read vServerParams          Write vServerParams;
  Property ServerMethodClass     : TClass          Read vServerMethod          Write vServerMethod;
  Property SSLPrivateKeyFile     : String          Read aSSLPrivateKeyFile     Write aSSLPrivateKeyFile;
  Property SSLPrivateKeyPassword : String          Read aSSLPrivateKeyPassword Write aSSLPrivateKeyPassword;
  Property SSLCertFile           : String          Read aSSLCertFile           Write aSSLCertFile;
  Property SSLVersion            : TIdSSLVersion   Read aSSLVersion            Write aSSLVersion;
  Property OnLastRequest         : TLastRequest    Read vLastRequest           Write vLastRequest;
  Property OnLastResponse        : TLastResponse   Read vLastResponse          Write vLastResponse;
  Property Encoding              : TEncodeSelect   Read VEncondig              Write VEncondig;          //Encoding da string
  Property ServerContext         : String          Read vServerContext         Write vServerContext;
End;

Type
 TRESTClientPooler = Class(TComponent) //Novo Componente de Acesso a Requisi��es REST para o RESTDataware
 Protected
  //Vari�veis, Procedures e  Fun��es Protegidas
  HttpRequest       : TIdHTTP;
  Procedure SetParams;
 Private
  //Vari�veis, Procedures e Fun��es Privadas
  vTypeRequest      : TTypeRequest;
  vRSCharset        : TEncodeSelect;
  vUserName,
  vPassword,
  vHost             : String;
  vPort             : Integer;
  vAutenticacao     : Boolean;
  vTransparentProxy : TIdProxyConnectionInfo;
  vRequestTimeOut   : Integer;
  Procedure SetUserName(Value : String);
  procedure SetPassword(Value : String);
 Public
  //M�todos, Propriedades, Vari�veis, Procedures e Fun��es Publicas
  Function    SendEvent(EventData : String)              : String;Overload;
  Function    SendEvent(EventData : String;
                        Var RBody : TStringStream;
                        EventType : TSendEvent = sePOST) : String;Overload;
  Function    SendEvent(EventData  : String;
                        Var Params : TDWParams) : String;Overload;
  Constructor Create(AOwner: TComponent);Override;
  Destructor  Destroy;Override;
 Published
  //M�todos e Propriedades
  Property Encoding         : TEncodeSelect          Read vRSCharset        Write vRSCharset;
  Property TypeRequest      : TTypeRequest           Read vTypeRequest      Write vTypeRequest       Default trHttp;
  Property Host             : String                 Read vHost             Write vHost;
  Property Port             : Integer                Read vPort             Write vPort              Default 8082;
  Property UserName         : String                 Read vUserName         Write SetUserName;
  Property Password         : String                 Read vPassword         Write SetPassword;
  Property Autenticacao     : Boolean                Read vAutenticacao     Write vAutenticacao      Default True;
  Property ProxyOptions     : TIdProxyConnectionInfo Read vTransparentProxy Write vTransparentProxy;
  Property RequestTimeOut   : Integer                Read vRequestTimeOut   Write vRequestTimeOut;
End;

implementation

Uses uDWJSONParser;

Constructor TRESTClientPooler.Create(AOwner: TComponent);
Begin
 Inherited;
 HttpRequest                     := TIdHTTP.Create(Nil);
 HttpRequest.Request.ContentType := 'application/json';
 vTransparentProxy               := TIdProxyConnectionInfo.Create;
 vHost                           := 'localhost';
 vPort                           := 8082;
 vUserName                       := 'testserver';
 vPassword                       := 'testserver';
 vRSCharset                      := esASCII;
 vAutenticacao                   := True;
 vRequestTimeOut                 := 10000;
End;

Destructor  TRESTClientPooler.Destroy;
Begin
 HttpRequest.Free;
 vTransparentProxy.Free;
 Inherited;
End;

Function TRESTClientPooler.SendEvent(EventData : String;
                                     Var RBody : TStringStream;
                                     EventType : TSendEvent = sePOST) : String;
Var
 vURL,
 vTpRequest  : String;
 vResultParams : TMemoryStream;
 StringStream  : TStringStream;
 Procedure SetData(InputValue     : String;
                   Var ParamsData : TStringStream;
                   Var ResultJSON : String);
 Var
  JsonParser  : TJsonParser;
  bJsonValue  : TJsonObject;
  JSONParam   : TJSONParam;
  A, I, InitPos : Integer;
  vValue,
  vTempValue  : String;
 Begin
  ClearJsonParser(JsonParser);
  Try
   ParamsData.Free;
   ParamsData := TStringStream.Create('');
   InitPos    := Pos('"RESULT":[', InputValue) + 10;
   vTempValue := Copy(InputValue, InitPos, Pos(']}', InputValue) - InitPos);
   Delete(InputValue, InitPos, Pos(']}', InputValue) - InitPos);
   ParseJson(JsonParser, InputValue);
   If Length(JsonParser.Output.Objects) > 0 Then
    Begin
     For A := 1 To Length(JsonParser.Output.Objects) -1 Do
      Begin
       bJsonValue := JsonParser.Output.Objects[A];
       If GetObjectName(bJsonValue[0].Value.Value) <> toParam Then
        Break;
       JSONParam := TJSONParam.Create(GetEncoding(vRSCharset));
       Try
        JSONParam.ParamName       := bJsonValue[4].Key;
        JSONParam.ObjectValue     := GetValueType(bJsonValue[3].Value.Value);
        JSONParam.ObjectDirection := GetDirectionName(bJsonValue[1].Value.Value);
        JSONParam.Encoded         := GetBooleanFromString(bJsonValue[2].Value.Value);
        If JSONParam.Encoded Then
         vValue := DecodeStrings(bJsonValue[4].Value.Value{$IFNDEF FPC}, GetEncoding(vRSCharset){$ENDIF})
        Else
         vValue := bJsonValue[4].Value.Value;
        JSONParam.SetValue(vValue);
        ParamsData.WriteString(Format('%s=%s', [JSONParam.ParamName, JSONParam.ToJSON]) + TSepParams);
       Finally
        JSONParam.Free;
       End;
      End;
    End;
  Finally
   If vTempValue <> '' Then
    ResultJSON := DecodeStrings(vTempValue{$IFNDEF FPC}, GetEncoding(vRSCharset){$ENDIF});
  End;
 End;
Begin
 vResultParams := TMemoryStream.Create;
 If vTypeRequest = trHttp Then
  vTpRequest := 'http'
 Else If vTypeRequest = trHttps Then
  vTpRequest := 'https';
 SetParams;
 Try
  If Pos(Uppercase(Format(UrlBase, [vTpRequest, vHost, vPort])), Uppercase(EventData)) = 0 Then
   vURL := LowerCase(Format(UrlBase, [vTpRequest, vHost, vPort])) + EventData
  Else
   vURL := EventData;
  If vRSCharset = esUtf8 Then
   HttpRequest.Request.Charset := 'utf-8'
  Else If vRSCharset = esASCII Then
   HttpRequest.Request.Charset := 'ansi';
  Case EventType Of
   seGET :
    Begin
     HttpRequest.Request.ContentType := 'application/json';
     Result := HttpRequest.Get(vURL);
    End;
   sePOST,
   sePUT,
   seDELETE :
    Begin;
     If EventType = sePOST Then
      Begin
       HttpRequest.Request.ContentType := 'application/x-www-form-urlencoded';
       HttpRequest.Post(vURL, RBody, vResultParams);
       vResultParams.WriteBuffer(#0' ', 1);
       vResultParams.Position := 0;
       StringStream  := TStringStream.Create('');
       Try
        StringStream.CopyFrom(vResultParams, vResultParams.Size);
        StringStream.Position := 0;
        SetData(StringStream.DataString, RBody, Result);
       Finally
        StringStream.Free;
       End;
      End
     Else If EventType = sePUT Then
      Begin
       HttpRequest.Request.ContentType := 'application/x-www-form-urlencoded';
       HttpRequest.Put(vURL, RBody, vResultParams);
       vResultParams.WriteBuffer(#0' ', 1);
       vResultParams.Position := 0;
       StringStream  := TStringStream.Create('');
       Try
        StringStream.CopyFrom(vResultParams, vResultParams.Size);
        StringStream.Position := 0;
        SetData(StringStream.DataString, RBody, Result);
       Finally
        StringStream.Free;
       End;
      End
     Else If EventType = seDELETE Then
      Begin
       Try
         HttpRequest.Request.ContentType := 'application/json';
         HttpRequest.Delete(vURL);
         Result := GetPairJSON('OK', 'DELETE COMMAND OK');
       Except
        On e:exception Do
         Begin
          Result := GetPairJSON('NOK', e.Message);
         End;
       End;
      End;
    End;
  End;
 Except

 End;
 vResultParams.Free;
End;

Function TRESTClientPooler.SendEvent(EventData : String) : String;
Var
 RBody      : TStringStream;
 vTpRequest : String;
Begin
 RBody   := TStringStream.Create('');
 Try
  If vTypeRequest = trHttp Then
   vTpRequest := 'http'
  Else If vTypeRequest = trHttps Then
   vTpRequest := 'https';
  Result := SendEvent(Format(UrlBase, [vTpRequest, vHost, vPort]) + EventData, RBody, seGET);
 Except
 End;
 RBody.Free;
End;

Procedure TRESTClientPooler.SetParams;
Begin
 HttpRequest.Request.BasicAuthentication := vAutenticacao;
 If HttpRequest.Request.BasicAuthentication Then
  Begin
   If HttpRequest.Request.Authentication = Nil Then
    HttpRequest.Request.Authentication         := TIdBasicAuthentication.Create;
   HttpRequest.Request.Authentication.Password := vPassword;
   HttpRequest.Request.Authentication.Username := vUserName;
  End;
 HttpRequest.ProxyParams := vTransparentProxy;
 HttpRequest.ReadTimeout := vRequestTimeout;
End;

procedure TRESTClientPooler.SetPassword(Value : String);
begin
 vPassword := Value;
 HttpRequest.Request.Password := vPassword;
end;

procedure TRESTClientPooler.SetUserName(Value : String);
begin
 vUsername := Value;
end;

Constructor TProxyOptions.Create;
Begin
 Inherited;
 vServer   := '';
 vLogin    := vServer;
 vPassword := vLogin;
 vPort     := 8888;
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

{ TRESTServicePooler }

Procedure TRESTServicePooler.aCommandGet(AContext      : TIdContext;
                                         ARequestInfo  : TIdHTTPRequestInfo;
                                         AResponseInfo : TIdHTTPResponseInfo);
Var
 DWParams           : TDWParams;
 vReplyString,
 Cmd , UrlMethod,
 JSONStr            : String;
 vTempServerMethods : TObject;
Begin
 vTempServerMethods := Nil;
 DWParams           := TDWParams.Create;
 DWParams.Encoding  := GetEncoding(VEncondig);
 Try
  Cmd := Trim(ARequestInfo.RawHTTPCommand);
  If (vServerParams.HasAuthentication) Then
   Begin
    If Not ((ARequestInfo.AuthUsername = vServerParams.Username)  And
            (ARequestInfo.AuthPassword = vServerParams.Password)) Then
     Begin
      AResponseInfo.AuthRealm := AuthRealm;
      AResponseInfo.WriteContent;
      Exit;
     End;
   End;
  If (UpperCase(Copy (Cmd, 1, 3)) = 'GET' ) OR
     (UpperCase(Copy (Cmd, 1, 4)) = 'POST') OR
     (UpperCase(Copy (Cmd, 1, 3)) = 'HEAD') Then
   Begin
    If ARequestInfo.URI <> '/favicon.ico' Then
     Begin
      If ARequestInfo.Params.Count > 0 Then
       DWParams  := TServerUtils.ParseWebFormsParams (ARequestInfo.Params, ARequestInfo.URI,
                                                      UrlMethod, GetEncoding(VEncondig))
      Else
       DWParams  := TServerUtils.ParseRESTURL (ARequestInfo.URI, GetEncoding(VEncondig));
      If Assigned(vServerMethod) Then
       vTempServerMethods := vServerMethod.Create
      Else
       JSONStr := GetPairJSON(-5, 'Server Methods Cannot Assigned');
      Try
       If Assigned(vLastRequest) Then
        Begin
         {$IFDEF FPC} {$IFDEF WINDOWS}
         EnterCriticalSection(vCriticalSection);
         {$ENDIF}{$ENDIF}
         vLastRequest(ARequestInfo.UserAgent + #13#10 +
                      ARequestInfo.RawHTTPCommand);
         {$IFDEF FPC} {$IFDEF WINDOWS}
         LeaveCriticalSection(vCriticalSection);
         {$ENDIF}{$ENDIF}
        End;
       If Assigned(vServerMethod) Then
        Begin
         If vTempServerMethods <> Nil Then
          Begin
           If UpperCase(Copy (Cmd, 1, 3)) = 'GET' Then
            JSONStr := TServerMethods(vTempServerMethods).ReplyEvent(seGET, '', DWParams);
           If UpperCase(Copy (Cmd, 1, 4)) = 'POST' Then
            JSONStr := TServerMethods(vTempServerMethods).ReplyEvent(sePOST, UrlMethod, DWParams);
          End;
        End;
       Try
        JSONStr                         := EncodeStrings(JSONStr{$IFNDEF FPC}, GetEncoding(VEncondig){$ENDIF});
        vReplyString                    := Format(TValueDisp, [DWParams.ToJSON, JSONStr]);
        AResponseInfo.FreeContentStream := True;
        AResponseInfo.ContentStream     := TStringStream.Create(vReplyString);
        AResponseInfo.ContentStream.Position := 0;
        AResponseInfo.ContentLength     := AResponseInfo.ContentStream.Size;
        AResponseInfo.WriteHeader;
       Finally
       End;
       If Assigned(vLastResponse) Then
        Begin
         {$IFDEF FPC} {$IFDEF WINDOWS}
         EnterCriticalSection(vCriticalSection);
         {$ENDIF}{$ENDIF}
         vLastResponse(DecodeStrings(JSONStr{$IFNDEF FPC}, GetEncoding(VEncondig){$ENDIF}));
         {$IFDEF FPC} {$IFDEF WINDOWS}
         LeaveCriticalSection(vCriticalSection);
         {$ENDIF}{$ENDIF}
        End;
       AResponseInfo.WriteContent;
      Finally
       If Assigned(vServerMethod) Then
        vTempServerMethods.Free;
      End;
     End;
   End;
 Finally
  DWParams.Free;
 End;
End;

Procedure TRESTServicePooler.aCommandOther(AContext      : TIdContext;
                                           ARequestInfo  : TIdHTTPRequestInfo;
                                           AResponseInfo : TIdHTTPResponseInfo);
Var
 DWParams           : TDWParams;
 vReplyString,
 Cmd, JSONStr       : String;
 vTempServerMethods : TObject;
Begin
 vTempServerMethods := Nil;
 Cmd := ARequestInfo.RawHTTPCommand;
 If (vServerParams.HasAuthentication) Then
  Begin
   If Not ((ARequestInfo.AuthUsername = vServerParams.Username)  And
           (ARequestInfo.AuthPassword = vServerParams.Password)) Then
    Begin
     AResponseInfo.AuthRealm := AuthRealm;
     AResponseInfo.WriteContent;
     Exit;
    End;
  End;
 If (UpperCase(Copy (Cmd, 1, 3)) = 'PUT')    OR
    (UpperCase(Copy (Cmd, 1, 6)) = 'DELETE') Then
  Begin
   DWParams := TServerUtils.ParseRESTURL (ARequestInfo.URI, GetEncoding(VEncondig));
   If Assigned(vServerMethod) Then
    vTempServerMethods := vServerMethod.Create
   Else
    JSONStr := GetPairJSON(-5, 'Server Methods Cannot Assigned');
   Try
    If Assigned(vLastRequest) Then
     Begin
      {$IFDEF FPC} {$IFDEF WINDOWS}
      EnterCriticalSection(vCriticalSection);
      {$ENDIF}{$ENDIF}
      vLastRequest(ARequestInfo.UserAgent + #13#10 +
                   ARequestInfo.RawHTTPCommand);
      {$IFDEF FPC} {$IFDEF WINDOWS}
      LeaveCriticalSection(vCriticalSection);
      {$ENDIF}{$ENDIF}
     End;
    If Assigned(vServerMethod) Then
     Begin
      If vTempServerMethods <> Nil Then
       Begin
        If UpperCase(Copy (Cmd, 1, 3)) = 'PUT' Then
         JSONStr := TServerMethods(vTempServerMethods).ReplyEvent(sePUT, '', DWParams);
        If UpperCase(Copy (Cmd, 1, 6)) = 'DELETE' Then
         JSONStr := TServerMethods(vTempServerMethods).ReplyEvent(seDELETE, '', DWParams);
       End;
     End;
    Try
     vReplyString                    := Format(TValueDisp, ['', JSONStr]);
     AResponseInfo.FreeContentStream := True;
     AResponseInfo.ContentStream     := TStringStream.Create(vReplyString);
     AResponseInfo.ContentStream.Position := 0;
     AResponseInfo.ContentLength     := AResponseInfo.ContentStream.Size;
     AResponseInfo.WriteHeader;
    Finally
    End;
    If Assigned(vLastResponse) Then
     Begin
      {$IFDEF FPC} {$IFDEF WINDOWS}
      EnterCriticalSection(vCriticalSection);
      {$ENDIF}{$ENDIF}
      vLastResponse(DecodeStrings(JSONStr{$IFNDEF FPC}, GetEncoding(VEncondig){$ENDIF}));
      {$IFDEF FPC} {$IFDEF WINDOWS}
      LeaveCriticalSection(vCriticalSection);
      {$ENDIF}{$ENDIF}
     End;
    AResponseInfo.WriteContent;
   Finally
    If Assigned(vServerMethod) Then
     vTempServerMethods.Free;
   End;
  End;
end;

Constructor TRESTServicePooler.Create(AOwner: TComponent);
Begin
 Inherited;
 vProxyOptions                   := TProxyOptions.Create;
 HTTPServer                      := TIdHTTPServer.Create(Nil);
 lHandler                        := TIdServerIOHandlerSSLOpenSSL.Create;
 {$IFDEF FPC}
 HTTPServer.OnCommandGet         := @aCommandGet;
 HTTPServer.OnCommandOther       := @aCommandOther;
 {$ELSE}
 HTTPServer.OnCommandGet         := aCommandGet;
 HTTPServer.OnCommandOther       := aCommandOther;
 {$ENDIF}
 vServerParams                   := TServerParams.Create;
 vActive                         := False;
 vServerParams.HasAuthentication := True;
 vServerParams.UserName          := 'testserver';
 vServerParams.Password          := 'testserver';
 vServerContext                  := 'restdataware';
 VEncondig                       := esASCII;
 {$IFDEF FPC} {$IFDEF WINDOWS}
 InitializeCriticalSection(vCriticalSection);
 {$ENDIF}{$ENDIF}
End;

Destructor TRESTServicePooler.Destroy;
Begin
 vProxyOptions.Free;
 HTTPServer.Active := False;
 HTTPServer.Free;
 vServerParams.Free;
 lHandler.Free;
 {$IFDEF FPC}{$IFDEF WINDOWS}DeleteCriticalSection(vCriticalSection);{$ENDIF}{$ENDIF}
 Inherited;
End;

Function TRESTServicePooler.GetSecure : Boolean;
Begin
 Result:= vActive And (HTTPServer.IOHandler is TIdServerIOHandlerSSLBase);
End;

Procedure TRESTServicePooler.GetSSLPassWord(var Password: String);
Begin
 Password := aSSLPrivateKeyPassword;
End;

Procedure TRESTServicePooler.SetActive(Value : Boolean);
Begin
 If (Value)                   And
    (Not (HTTPServer.Active)) Then
  Begin
   Try
    If (ASSLPrivateKeyFile <> '')     And
       (ASSLPrivateKeyPassword <> '') And
       (ASSLCertFile <> '')           Then
     Begin
      lHandler.SSLOptions.Method                := aSSLVersion;
      {$IFDEF FPC}
      lHandler.OnGetPassword                    := @GetSSLPassword;
      {$ELSE}
      lHandler.OnGetPassword                    := GetSSLPassword;
      {$ENDIF}
      lHandler.SSLOptions.CertFile              := ASSLCertFile;
      lHandler.SSLOptions.KeyFile               := ASSLPrivateKeyFile;
      HTTPServer.IOHandler := lHandler;
     End
    Else
     HTTPServer.IOHandler  := Nil;
    HTTPServer.DefaultPort := vServicePort;
    HTTPServer.Active      := True;
   Except
    On E : Exception do
     Begin
      Raise Exception.Create(PChar(E.Message));
     End;
   End;
  End
 Else If Not(Value) Then
  HTTPServer.Active := False;
 vActive := HTTPServer.Active;
End;

Function TRESTClientPooler.SendEvent(EventData  : String;
                                     Var Params : TDWParams): String;
Var
 I : Integer;
 vStringList : TStringStream;
 Procedure SetDWParams(StringList   : TStringStream;
                       Var DWParams : TDWParams);
 Var
  vTempValue,
  vTempLine   : String;
  JSONParam   : TJSONParam;
  vInitPos    : Integer;
 Begin
  vTempValue := StringList.DataString;
  JSONParam := TJSONParam.Create(GetEncoding(vRSCharset));
  Try
   While Not (vTempValue = '') Do
    Begin
     vInitPos  := Pos('=', vTempValue) +1;
     JSONParam.FromJSON(Copy(vTempValue, vInitPos, Pos(TSepParams, vTempValue) - vInitPos));
     Delete(vTempValue, 1, Pos(TSepParams, vTempValue) + Length(TSepParams) -1);
     If DWParams.ItemsString[JSONParam.ParamName] <> Nil Then
      DWParams.ItemsString[JSONParam.ParamName].SetValue(JSONParam.Value);
    End;
  Finally

  End;
 End;
Begin
 vStringList := TStringStream.Create('');
 Try
  For I := 0 To Params.Count -1 Do
   Begin
    If I = 0 Then
     vStringList.WriteString(Format('%s=%s',  [Params.Items[I].ParamName, Params.Items[I].ToJSON]))
    Else
     vStringList.WriteString(Format('&%s=%s', [Params.Items[I].ParamName, Params.Items[I].ToJSON]))
   End;
  vStringList.Position := 0;
  Result := SendEvent(EventData, vStringList, sePOST);
  SetDWParams(vStringList, Params);
 Finally
  vStringList.Free;
 End;
End;

end.
