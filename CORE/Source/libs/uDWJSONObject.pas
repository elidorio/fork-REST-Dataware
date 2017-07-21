unit uDWJSONObject;

interface

Uses {$IFDEF FPC}
      SysUtils, Classes, uDWJSONTools, IdGlobal, DB, uDWJSONParser, uDWConsts, uDWConstsData, JvMemoryDataset;
     {$ELSE}
      {$if CompilerVersion > 21} // Delphi 2010 pra cima
       System.SysUtils, System.Classes, uDWJSONTools, uDWConsts, uDWJSONParser, uDWConstsData,
       IdGlobal,        System.Rtti,    Data.DB,      Soap.EncdDecd, Datasnap.DbClient, JvMemoryDataset;
      {$ELSE}
       SysUtils, Classes, uDWJSONTools, uDWJSONParser,
       IdGlobal,        DB,     EncdDecd, DbClient, uDWConsts, uDWConstsData, JvMemoryDataset;
      {$IFEND}
     {$ENDIF}

Type
 TJSONBufferObject = Class

End;

Type
 TJSONValue = Class
 Private
  vBinary             : Boolean;
  vtagName            : String;
  vTypeObject         : TTypeObject;
  vObjectDirection    : TObjectDirection;
  vObjectValue        : TObjectValue;
  aValue              : TIdBytes;
  vEncoded            : Boolean;
  {$IFNDEF FPC}
   {$if CompilerVersion > 21}
    vEncoding          : TEncoding;
   {$IFEND}
  {$ENDIF}
  Function    GetValue                    : String;
  Procedure   WriteValue     (bValue      : String);
  Function    FormatValue    (bValue      : String)   : String;
  Function    GetValueJSON   (bValue      : String)   : String;
  Function    DatasetValues  (bValue      : TDataset) : String;
  Function    EncodedString  : String;
 Public
  Procedure   ToStream       (Var bValue  : TMemoryStream);
  Procedure   LoadFromDataset(TableName    : String;
                              bValue       : TDataset;
                              EncodedValue : Boolean = True);
  Procedure   WriteToDataset (DatasetType  : TDatasetType;
                              JSONValue    : String;
                              DestDS       : TDataset);
  Procedure   LoadFromJSON   (bValue       : String);
  Procedure   LoadFromStream (Stream       : TMemoryStream;
                              Encode       : Boolean = True);
  Procedure   SaveToStream   (Stream       : TMemoryStream);
  Function    ToJSON                       : String;
  Procedure   SetValue(Value : String; Encode : Boolean = True);
  Function    Value : String;
  Constructor Create;
  Destructor  Destroy;Override;
  Property    TypeObject                  : TTypeObject      Read vTypeObject      Write vTypeObject;
  Property    ObjectDirection             : TObjectDirection Read vObjectDirection Write vObjectDirection;
  Property    ObjectValue                 : TObjectValue     Read vObjectValue     Write vObjectValue;
  {$IFNDEF FPC}
   {$if CompilerVersion > 21}
   Property    Encoding                    : TEncoding        Read vEncoding        Write vEncoding;
   {$IFEND}
  {$ENDIF}
  Property    Tagname                     : String           Read vtagName         Write vtagName;
  Property    Encoded                     : Boolean          Read vEncoded         Write vEncoded;
End;

Type
 TJSONParam = Class(TObject)
 Private
  vJSONValue                         : TJSONValue;
  {$IFNDEF FPC}
   {$if CompilerVersion > 21}
    vEncoding                          : TEncoding;
   {$IFEND}
  {$ENDIF}
  vTypeObject                        : TTypeObject;
  vObjectDirection                   : TObjectDirection;
  vObjectValue                       : TObjectValue;
  vParamName                         : String;
  vBinary,
  vEncoded                           : Boolean;
  Function    EncodedString  : String;
  Function    FormatValue    (bValue : String) : String;
  Procedure   WriteValue     (bValue : String);
  Procedure   SetParamName   (bValue : String);
  Function    GetValueJSON   (bValue : String) : String;
 Public
  Constructor Create{$IFNDEF FPC}{$if CompilerVersion > 21}(Encoding : TEncoding){$IFEND}{$ENDIF};
  Destructor  Destroy;Override;
  Procedure   FromJSON(JSON : String);
  Function    ToJSON        : String;
  Procedure   CopyFrom(JSONParam : TJSONParam);
  Function    Value : String;
  Procedure   SetValue(aValue : String; Encode : Boolean = True);
  Procedure   LoadFromStream (Stream       : TMemoryStream;
                              Encode       : Boolean = True);
  Procedure   SaveToStream   (Stream       : TMemoryStream);
  Procedure   LoadFromParam  (Param        : TParam);
  Property    ObjectDirection             : TObjectDirection Read vObjectDirection Write vObjectDirection;
  Property    ObjectValue                 : TObjectValue     Read vObjectValue     Write vObjectValue;
  Property    ParamName                   : String           Read vParamName       Write SetParamName;
  Property    Encoded                     : Boolean          Read vEncoded         Write vEncoded;
End;

Type
 TDWParams = Class(TList)
 Private
  {$IFNDEF FPC}
   {$if CompilerVersion > 21}
    vEncoding  : TEncoding;
   {$IFEND}
  {$ENDIF}
  Function  GetRec(Index    : Integer)         : TJSONParam; Overload;
  Procedure PutRec(Index    : Integer;    Item : TJSONParam);Overload;
  Function  GetRecName(Index    : String)      : TJSONParam; Overload;
  Procedure PutRecName(Index    : String; Item : TJSONParam);Overload;
 Public
  Constructor Create;
  Function  ParamsReturn  : Boolean;
  Function  ToJSON        : String;
  Procedure FromJSON(JSON : String);
  Procedure CopyFrom(DWParams:TDWParams );
  Procedure Delete      (Index : Integer);                 Overload;
  Function  Add         (Item  : TJSONParam) : Integer;    Overload;
  Property  Items      [Index  : Integer]    : TJSONParam  Read GetRec     Write PutRec;Default;
  Property  ItemsString[Index  : String]     : TJSONParam  Read GetRecName Write PutRecName;
  {$IFNDEF FPC}
   {$if CompilerVersion > 21}
    Property  Encoding         : TEncoding                 Read vEncoding  Write vEncoding;
   {$IFEND}
  {$ENDIF}
End;

Type
 TDWDatalist = Class
End;

implementation

uses uRESTDWPoolerDB;

Function CopyValue(Var bValue : String) : String;
Var
 vOldString,
 vStringBase,
 vTempString      : String;
 A, vLengthString : Integer;
Begin
 vOldString    := bValue;
 vStringBase   := '"ValueType":"';
 vLengthString := Length(vStringBase);
 vTempString   := Copy(bValue, Pos(vStringBase, bValue) +  vLengthString, Length(bValue));
 A             := Pos(':', vTempString);
 vTempString   := Copy(vTempString, A, Length(vTempString));
 If vTempString[InitStrPos] = ':' Then
  Delete(vTempString, InitStrPos, 1);
 If vTempString[InitStrPos] = '"' Then
  Delete(vTempString, InitStrPos, 1);
 If vTempString = '}' Then
  vTempString := '';
 If vTempString <> '' Then
  Begin
   For A := Length(vTempString) Downto InitStrPos Do
    Begin
     If vTempString[Length(vTempString)] <> '}' Then
      Delete(vTempString, Length(vTempString), 1)
     Else
      Begin
       Delete(vTempString, Length(vTempString), 1);
       Break;
      End;
    End;
   If vTempString[Length(vTempString)] = '"' Then
    Delete(vTempString, Length(vTempString), 1);
  End;
 Result := vTempString;
 bValue := StringReplace(bValue, Result, '', [rfReplaceAll]);
End;

Function  TDWParams.Add(Item : TJSONParam) : Integer;
Var
 vItem : ^TJSONParam;
Begin
 New(vItem);
 vItem^ := Item;
 {$IFNDEF FPC}
  {$if CompilerVersion > 21}
   vItem^.vEncoding := vEncoding;
  {$IFEND}
 {$ENDIF}
 Result := TList(Self).Add(vItem);
End;

Constructor TDWParams.Create;
Begin
 Inherited;
 {$IFNDEF FPC}
  {$if CompilerVersion > 21}
   vEncoding := TEncoding.ASCII;
  {$IFEND}
 {$ENDIF}
End;

Function  TDWParams.ToJSON : String;
Var
 I : Integer;
Begin
 For I := 0 To Self.Count -1 Do
  Begin
   If I = 0 Then
    Result := TJSONParam(TList(Self).Items[I]^).ToJSON
   Else
    Result := Result + ', ' + TJSONParam(TList(Self).Items[I]^).ToJSON;
  End;
End;

Procedure TDWParams.FromJSON(JSON : String);
Var
 JsonParser    : TJsonParser;
 bJsonValue    : TJsonObject;
 JSONParam     : TJSONParam;
 vTempValue    : String;
 I             : Integer;
Begin
 ClearJsonParser(JsonParser);
 Try
  ParseJson(JsonParser, JSON);
  For I := 0 To Length(JsonParser.Output.Objects) -1 Do
   Begin
    bJsonValue       := JsonParser.Output.Objects[I];
    {$IFNDEF FPC}
     {$if CompilerVersion > 21}
      JSONParam                     := TJSONParam.Create(GetEncoding(TEncodeSelect(vEncoding)));
     {$ELSE}
      JSONParam                     := TJSONParam.Create;
     {$IFEND}
    {$ENDIF}
    JSONParam.ParamName             := bJsonValue[4].Key;
    JSONParam.ObjectDirection       := GetDirectionName(bJsonValue[1].Value.Value);
    JSONParam.ObjectValue           := GetValueType    (bJsonValue[3].Value.Value);
    JSONParam.Encoded               := GetBooleanFromString(bJsonValue[2].Value.Value);
    JSONParam.SetValue(bJsonValue[4].Value.Value);
    Add(JSONParam);
   End;
 Finally

 End;
End;

Procedure TDWParams.CopyFrom(DWParams:TDWParams );
 Var
  i:integer;
  p    : TJSONParam;
  JSONParam : TJSONParam;
 Begin
  Clear;
  for i:=0 to DWParams.Count-1 do
  begin
     p:=DWParams.Items[i];
     JSONParam := TJSONParam.Create{$IFNDEF FPC}{$if CompilerVersion > 21} (DWParams.Encoding){$IFEND}{$ENDIF};
     JSONParam.CopyFrom(p);
     Add(JSONParam);
  end;
End;
Procedure TDWParams.Delete(Index : Integer);
Begin
 If (Index < Self.Count) And (Index > -1) Then
  Begin
   If Assigned(TList(Self).Items[Index]) Then
    FreeMem(TList(Self).Items[Index]);
   TList(Self).Delete(Index);
  End;
End;

Function  TDWParams.GetRec(Index : Integer) : TJSONParam;
Begin
 Result := Nil;
 If (Index < Self.Count) And (Index > -1) Then
  Result := TJSONParam(TList(Self).Items[Index]^);
End;

Function TDWParams.GetRecName(Index : String) : TJSONParam;
Var
 I : Integer;
Begin
 Result := Nil;
 For I := 0 To Self.Count -1 Do
  Begin
   If (Uppercase(Index) = Uppercase(TJSONParam(TList(Self).Items[I]^).vParamName)) Then
    Begin
     Result := TJSONParam(TList(Self).Items[I]^);
     Break;
    End;
  End;
End;

Function TDWParams.ParamsReturn : Boolean;
Var
 I : Integer;
Begin
 For I := 0 To Self.Count -1 Do
  Begin
   Result := Items[I].vObjectDirection In [odOUT, odINOUT];
   If Result Then
    Break;
  End;
End;

Procedure TDWParams.PutRec(Index : Integer; Item : TJSONParam);
Begin
 If (Index < Self.Count) And (Index > -1) Then
  TJSONParam(TList(Self).Items[Index]^) := Item;
End;

procedure TDWParams.PutRecName(Index: String; Item: TJSONParam);
Var
 I : Integer;
Begin
 For I := 0 To Self.Count -1 Do
  Begin
   If (Uppercase(Index) = Uppercase(TJSONParam(TList(Self).Items[I]^).vParamName)) Then
    Begin
     TJSONParam(TList(Self).Items[I]^) := Item;
     Break;
    End;
  End;
End;

Function EscapeQuotes(Const S : String) : String;
Begin
 //Easy but not best performance
 Result := StringReplace(S,      '\', TSepValueMemString,    [rfReplaceAll]);
 Result := StringReplace(Result, '"', TQuotedValueMemString, [rfReplaceAll]);
End;

Function RevertQuotes(Const S : String) : String;
Begin
 //Easy but not best performance
 Result := StringReplace(S,      TSepValueMemString,    '\', [rfReplaceAll]);
 Result := StringReplace(Result, TQuotedValueMemString, '"', [rfReplaceAll]);
End;

{ TJSONValue }

Constructor TJSONValue.Create;
Begin
 {$IFNDEF FPC}
  {$if CompilerVersion > 21}
   vEncoding       := TEncoding.ASCII;
  {$IFEND}
 {$ENDIF}
 vTypeObject     := toObject;
 ObjectDirection := odINOUT;
 vObjectValue    := ovString;
 vTAGName        := 'TAGJSON';
 vBinary         := True;
End;

destructor TJSONValue.Destroy;
Begin
 SetLength(aValue, 0);
 inherited;
End;

function TJSONValue.GetValueJSON(bValue: String): String;
Begin
 Result := bValue;
 If vObjectValue In [ovString, ovFixedChar,   ovWideString,
                     ovFixedWideChar, ovDate, ovTime,
                     ovDateTime]  Then
  Result := bValue;
End;

function TJSONValue.FormatValue(bValue: String): String;
Var
 aResult  : String;
Begin
 aResult  := bValue;
 If vTypeObject = toDataset Then
  Result  := Format(TValueFormatJSON, ['ObjectType', GetObjectName(vTypeObject),
                                       'Direction',  GetDirectionName(vObjectDirection),
                                       'Encoded',    EncodedString,
                                       'ValueType',  GetValueType(vObjectValue),
                                       vTAGName,     GetValueJSON(aResult)])
 Else
  Result  := Format(TValueFormatJSONValue, ['ObjectType', GetObjectName(vTypeObject),
                                            'Direction',  GetDirectionName(vObjectDirection),
                                            'Encoded',    EncodedString,
                                            'ValueType',  GetValueType(vObjectValue),
                                            vTAGName,     GetValueJSON(aResult)])
End;

function TJSONValue.GetValue: String;
Var
 vTempString : String;
Begin
 vTempString := BytesArrToString(aValue);
 If Length(vTempString) > 0 Then
  Begin
   If vTempString[InitStrPos] = '"' Then
    Delete(vTempString, InitStrPos, 1);
   If vTempString[Length(vTempString)] = '"' Then
    Delete(vTempString, Length(vTempString), 1);
  End;
 If vEncoded Then
  Begin
   If (vObjectValue in [ovWideMemo, ovBytes, ovVarBytes, ovBlob,
                        ovMemo,   ovGraphic, ovFmtMemo,  ovOraBlob,
                        ovOraClob]) And (vBinary) Then
    vTempString := vTempString
   Else
    Begin
     If Length(vTempString) > 0 Then
      vTempString := DecodeStrings(vTempString{$IFNDEF FPC}{$if CompilerVersion > 21}, vEncoding{$IFEND}{$ENDIF});
    End;
  End
 Else
  vTempString := BytesArrToString(aValue);
 If vObjectValue = ovString Then
  Begin
   If vTempString <> '' Then
    If vTempString[InitStrPos] = '"' Then
     Begin
      Delete(vTempString, 1, 1);
      If vTempString[Length(vTempString)] = '"' Then
       Delete(vTempString, Length(vTempString), 1);
     End;
   Result := vTempString;
  End
 Else
  Result := vTempString;
End;

function TJSONValue.DatasetValues(bValue: TDataset): String;
Var
 vLines : String;
 Function GenerateHeader : String;
 Var
  I : Integer;
  vPrimary,
  vRequired,
  vGenerateLine : String;
 Begin
  For I := 0 To bValue.Fields.Count -1 Do
   Begin
    vPrimary := 'N';
    If pfInKey in bValue.Fields[I].ProviderFlags Then
     vPrimary := 'S';
    vRequired := 'N';
    If bValue.Fields[I].Required Then
     vRequired := 'S';
    If bValue.Fields[I].DataType in [{$IFNDEF FPC}{$if CompilerVersion > 21}ftExtended,{$IFEND}{$ENDIF}ftFloat, ftCurrency, ftFMTBcd, ftBCD] Then
     vGenerateLine := Format(TJsonDatasetHeader, [bValue.Fields[I].FieldName,
                                                   GetFieldType(bValue.Fields[I].DataType),
                                                   vPrimary, vRequired,
                                                   TFloatField(bValue.Fields[I]).Size,
                                                   TFloatField(bValue.Fields[I]).Precision])
    Else
     vGenerateLine := Format(TJsonDatasetHeader, [bValue.Fields[I].FieldName,
                                                  GetFieldType(bValue.Fields[I].DataType),
                                                  vPrimary, vRequired,
                                                  bValue.Fields[I].Size, 0]);

    If I = 0 Then
     Result := vGenerateLine
    Else
     Result := Result + ', ' + vGenerateLine;
   End;
 End;
 Function GenerateLine : String;
 Var
  I : Integer;
  vTempValue    : String;
  bStream       : TStream;
  vStringStream : TStringStream;
 Begin
  For I := 0 To bValue.Fields.Count -1 Do
   Begin
    If bValue.Fields[I].DataType      in [{$IFNDEF FPC}{$if CompilerVersion > 21}ftExtended,{$IFEND}{$ENDIF}ftFloat, ftCurrency, ftFMTBcd,  ftBCD] Then
     vTempValue := Format('"%s"', [StringFloat(bValue.Fields[I].AsString)])
    Else If bValue.Fields[I].DataType in [ftWideString, ftBytes, ftVarBytes, ftBlob,
                                          ftMemo,   ftGraphic, ftFmtMemo,  ftOraBlob, ftOraClob] Then
     Begin
      vStringStream     := TStringStream.Create('');
      Try
       bStream           := bValue.CreateBlobStream(TBlobField(bValue.Fields[I]), bmRead);
       bStream.Position := 0;
       vStringStream.CopyFrom(bStream, bStream.Size);
       vStringStream.Position := 0;
       If vEncoded Then
        vTempValue := Format('"%s"', [EncodeStrings(vStringStream.DataString{$IFNDEF FPC}{$if CompilerVersion > 21}  , vEncoding{$IFEND}{$ENDIF})])
       Else
        vTempValue := Format('"%s"', [vStringStream.DataString])
      Finally
       vStringStream.Free;
      End;
     End
    Else
     Begin
      If bValue.Fields[I].DataType in [ftString, ftWideString, ftFixedChar] Then
       Begin
        If vEncoded Then
         vTempValue := Format('"%s"', [EncodeStrings(bValue.Fields[I].AsString{$IFNDEF FPC}{$if CompilerVersion > 21}, vEncoding{$IFEND}{$ENDIF})])
        Else
         vTempValue := Format('"%s"', [bValue.Fields[I].AsString])
       End
      Else
       vTempValue := Format('"%s"', [bValue.Fields[I].AsString]);
     End;
    If I = 0 Then
     Result := vTempValue
    Else
     Result := Result + ', ' + vTempValue;
   End;
 End;
Begin
 bValue.DisableControls;
 If Not bValue.Active Then
  bValue.Open;
 bValue.First;
 Result := '[' + GenerateHeader + '], [%s]';
 While Not bValue.Eof Do
  Begin
   If bValue.RecNo = 1 Then
    vLines := '[' + GenerateLine + ']'
   Else
    vLines := vLines + ', [' + GenerateLine + ']';
   bValue.Next;
  End;
 Result := Format(Result, [vLines]);
 bValue.First;
 bValue.EnableControls;
End;

Function TJSONValue.EncodedString : String;
Begin
 If vEncoded Then
  Result := 'true'
 Else
  Result := 'false';
End;

procedure TJSONValue.LoadFromDataset(TableName : String;
                                     bValue    : TDataset;
                                     EncodedValue : Boolean = True);
Var
 vTagGeral : String;
Begin
 vTypeObject      := toDataset;
 vObjectDirection := odINOUT;
 vObjectValue     := ovDataSet;
 vtagName         := lowercase(TableName);
 vEncoded         := EncodedValue;
 vTagGeral        := DatasetValues(bValue);
 aValue           := tIdBytes(ToBytes(vTagGeral));
End;

Function TJSONValue.ToJSON: String;
Var
 vTempValue : String;
Begin
 If vEncoded Then
  {$IFNDEF FPC}
   vTempValue := FormatValue({$if CompilerVersion > 21}vEncoding.GetString(TBytes(aValue)){$ELSE}BytesToString(aValue){$IFEND})
  {$ELSE}
   vTempValue := FormatValue(BytesToString(TBytes(aValue)))
  {$ENDIF}
 Else
  vTempValue := FormatValue(BytesArrToString(aValue));
 Result := vTempValue;
End;

procedure TJSONValue.ToStream(var bValue: TMemoryStream);
Begin
 If Length(aValue) > 0 Then
  Begin
   bValue := TMemoryStream.Create;
   bValue.Write(aValue[0], -1);
  End
 Else
  bValue := Nil;
End;

function TJSONValue.Value : String;
Begin
 Result := GetValue;
End;

procedure TJSONValue.WriteToDataset(DatasetType  : TDatasetType;
                                    JSONValue    : String;
                                    DestDS       : TDataset);
var
 JsonParser  : TJsonParser;
 bJsonValue  : TJsonObject;
 JsonArray   : TJsonArray;
 J, I        : Integer;
 FieldDef    : TFieldDef;
 Field       : TField;
 vBlobStream : TStringStream;
 Procedure SetValueA(Field : TField; Value : String);
 Begin
  Case Field.DataType Of
   ftUnknown,
   ftString,
   ftFixedChar,
   //ftFixedWideChar,
   ftWideString     :
    Begin
     Field.AsString := Value;
    End;
   ftAutoInc,
   ftSmallint,
   ftInteger,
   ftLargeint,
   ftWord,
   ftBoolean        :
    Begin
     If Value <> '' Then
      Field.AsInteger := StrToInt(Value);
    End;
   ftFloat,
   ftCurrency,
   ftBCD,
   ftFMTBcd         :
    Begin
     If Value <> '' Then
      Begin
       Case Field.DataType Of
        ftFloat     : Field.AsFloat := StrToFloat(Value);
        ftCurrency,
        ftBCD,
        ftFMTBcd    : Field.AsCurrency := StrToFloat(Value);
       End;
      End;
    End;
   ftDate,
   ftTime,
   ftDateTime,
   ftTimeStamp      :
    Begin
     If Value <> '' Then
      Field.AsDateTime := StrToDateTime(Value);
    End;
  End;
 End;
begin
 ClearJsonParser(JsonParser);
 Try
  ParseJson(JsonParser, JSONValue);
  If Length(JsonParser.Output.Objects) > 0 Then
   Begin
    bJsonValue       := JsonParser.Output.Objects[0];
    vTypeObject      := GetObjectName   (bJsonValue[0].Value.Value);
    vObjectDirection := GetDirectionName(bJsonValue[1].Value.Value);
    vEncoded         := GetBooleanFromString(bJsonValue[2].Value.Value);
    vObjectValue     := GetValueType    (bJsonValue[3].Value.Value);
    vtagName         := Lowercase       (bJsonValue[4].Key);
    //Add Field Defs
    DestDS.DisableControls;
    If DestDS.Active Then
     DestDS.Close;
    DestDS.FieldDefs.Clear;
    {$IFDEF FPC}
    DestDS.Fields.Clear;
    {$ENDIF}
    For J := 1 To Length(JsonParser.Output.Objects) -1 Do
     Begin
      bJsonValue         := JsonParser.Output.Objects[J];
      FieldDef           := DestDS.FieldDefs.AddFieldDef;
      FieldDef.Name      := bJsonValue[0].Value.Value;
      FieldDef.DataType  := GetFieldType(bJsonValue[1].Value.Value);
      FieldDef.Required  := UpperCase(bJsonValue[3].Value.Value) = 'S';
      If Not(FieldDef.DataType In [ftSmallInt, ftInteger, ftFloat, ftCurrency, ftBCD, ftFMTBcd]) Then
       Begin
        FieldDef.Size      := StrToInt(bJsonValue[4].Value.Value);
        FieldDef.Precision := StrToInt(bJsonValue[5].Value.Value);
       End;
     End;
    Try
     {$IFNDEF FPC}
      If DestDS Is TClientDataset Then
       TClientDataset(DestDS).CreateDataSet
      Else If DestDS Is TJvMemoryData Then
       Begin
        TRESTDWClientSQL(DestDS).Inactive := True;
        TRESTDWClientSQL(DestDS).Active   := True;
        TRESTDWClientSQL(DestDS).Inactive := False;
       End
      Else
       DestDS.Open;
     {$ELSE}
      DestDS.Open;
     {$ENDIF}
    Except
    End;
    //Add Set PK Fields
    For J := 1 To Length(JsonParser.Output.Objects) -1 Do
     Begin
      bJsonValue         := JsonParser.Output.Objects[J];
      If UpperCase(bJsonValue[2].Value.Value) = 'S' Then
       Begin
        Field := TJvMemoryData(DestDS).FindField(bJsonValue[0].Value.Value);
        If Field <> Nil Then
         Field.ProviderFlags := [pfInUpdate, pfInWhere, pfInKey];
       End;
     End;
    For J := 5 To Length(JsonParser.Output.Arrays) -1 Do
     Begin
      JsonArray  := JsonParser.Output.Arrays[J];
      DestDS.Append;
      For I := 0 To Length(JsonArray) -1 Do
       Begin
        If DestDS.Fields[I].DataType In [ftMemo, ftGraphic, ftFmtMemo,
                                         ftParadoxOle,      ftDBaseOle,
                                         ftTypedBinary,     ftCursor,
                                         ftDataSet,         ftOraBlob,
                                         ftOraClob,         ftWideString
                                         {$IFNDEF FPC}
                                         {$if CompilerVersion > 21}
                                         ,ftParams,         ftStream{$IFEND}{$ENDIF}]  Then
         Begin
          If vEncoded Then
           vBlobStream := TStringStream.Create(DecodeStrings(JsonArray[I].Value{$IFNDEF FPC}{$if CompilerVersion > 21}, vEncoding{$IFEND}{$ENDIF}))
          Else
           vBlobStream := TStringStream.Create(JsonArray[I].Value);
          Try
           vBlobStream.Position := 0;
           DestDS.CreateBlobStream(DestDS.Fields[I], bmWrite);
          Finally
           {$IFNDEF FPC}
            {$if CompilerVersion > 21}
             vBlobStream.Clear;
            {$IFEND}
           {$ENDIF}
           vBlobStream.Free;
          End;
         End
        Else
         Begin
          If JsonArray[I].Value <> '' Then
           Begin
            If DestDS.Fields[I].DataType in [ftString, ftWideString, ftFixedChar] Then
             Begin
              If vEncoded Then
               DestDS.Fields[I].AsString := DecodeStrings(JsonArray[I].Value{$IFNDEF FPC}{$if CompilerVersion > 21}, vEncoding{$IFEND}{$ENDIF})
              Else
               DestDS.Fields[I].AsString := JsonArray[I].Value;
             End
            Else
             Begin
              {$IFNDEF FPC}
               DestDS.Fields[I].Value := JsonArray[I].Value;
              {$ELSE}
               SetValueA(DestDS.Fields[I], JsonArray[I].Value);
              {$ENDIF}
             End;
           End;
         End;
       End;
      DestDS.Post;
     End;
   End
  Else
   Begin
    DestDS.Close;
    Raise Exception.Create('Invalid JSON Data...');
   End;
 Finally
  If DestDS.Active Then
   DestDS.First;
  DestDS.EnableControls;
 End;
End;

Procedure TJSONValue.SaveToStream(Stream : TMemoryStream);
Begin
 Try
  Stream.Write(aValue[0], Length(aValue));
 Finally
  Stream.Position := 0;
 End;
End;

procedure TJSONValue.LoadFromJSON(bValue : String);
Var
 JsonParser    : TJsonParser;
 bJsonValue    : TJsonObject;
 vTempValue    : String;
 vStringStream : TMemoryStream;
Begin
 ClearJsonParser(JsonParser);
 Try
  vTempValue := CopyValue(bValue);
  ParseJson(JsonParser, bValue);
  bJsonValue       := JsonParser.Output.Objects[0];
  vTypeObject      := GetObjectName   (bJsonValue[0].Value.Value);
  vObjectDirection := GetDirectionName(bJsonValue[1].Value.Value);
  vEncoded         := GetBooleanFromString(bJsonValue[2].Value.Value);
  vObjectValue     := GetValueType    (bJsonValue[3].Value.Value);
  vtagName         := Lowercase       (bJsonValue[4].Key);
  If vEncoded Then
   Begin
    If vObjectValue In [ovWideMemo, ovBytes, ovVarBytes, ovBlob,
                        ovMemo,   ovGraphic, ovFmtMemo,  ovOraBlob,
                        ovOraClob] Then
     Begin
      Try
       vStringStream := TMemoryStream.Create;
       HexToStream(vTempValue, vStringStream);
       aValue := tIdBytes(StreamToBytes(vStringStream));
      Finally
       vStringStream.Free;
      End;
     End
    Else
     vTempValue := DecodeStrings(vTempValue{$IFNDEF FPC}{$if CompilerVersion > 21}, vEncoding{$IFEND}{$ENDIF});
   End;
  If Not(vObjectValue In [ovWideMemo, ovBytes, ovVarBytes, ovBlob,
                          ovMemo,     ovGraphic, ovFmtMemo,  ovOraBlob,
                          ovOraClob]) Then
   SetValue(vTempValue, vEncoded);
 Finally

 End;
End;

Procedure TJSONValue.LoadFromStream(Stream    : TMemoryStream;
                                    Encode    : Boolean = True);
Begin
 ObjectValue := ovBlob;
 SetValue(StreamToHex(Stream), Encode);
End;

procedure TJSONValue.SetValue(Value: String; Encode: Boolean);
begin
 vBinary  := False;
 vEncoded := Encode;
 If Encode Then
  Begin
   If vObjectValue in [ovWideMemo, ovBytes, ovVarBytes, ovBlob,
                       ovMemo,   ovGraphic, ovFmtMemo,  ovOraBlob,
                       ovOraClob] Then
    WriteValue(Value)
   Else
    WriteValue(EncodeStrings(Value{$IFNDEF FPC}{$if CompilerVersion > 21} , vEncoding{$IFEND}{$ENDIF}))
  End
 Else
  WriteValue(Value);
end;

procedure TJSONValue.WriteValue(bValue: String);
Begin
 SetLength(aValue, 0);
 If vObjectValue = ovString Then
  Begin
   If vEncoded Then
    Begin
     {$IFDEF FPC}
      aValue := ToBytes(Format(TJsonStringValue, [bValue]));
     {$ELSE}
      {$if CompilerVersion > 21}
       aValue := tIdBytes(vEncoding.GetBytes(Format(TJsonStringValue, [bValue])));
      {$ELSE}
       aValue := ToBytes(Format(TJsonStringValue, [bValue]));
      {$IFEND}
     {$ENDIF}
    End
   Else
    aValue := ToBytes(Format(TJsonStringValue, [bValue]));
  End
 Else
  {$IFNDEF FPC}
   {$if CompilerVersion > 21}
    aValue := tIdBytes(vEncoding.GetBytes(bValue));
   {$ELSE}
    aValue := ToBytes(bValue);
   {$IFEND}
  {$ELSE}
   aValue := ToBytes(bValue);
  {$ENDIF}
End;

{ TJSONParam }

constructor TJSONParam.Create{$IFNDEF FPC}{$if CompilerVersion > 21}(Encoding : TEncoding){$IFEND}{$ENDIF};
begin
 vJSONValue         := TJSONValue.Create;
 {$IFNDEF FPC}
  {$if CompilerVersion > 21}
   vEncoding          := Encoding;
  {$IFEND}
 {$ENDIF}
 vTypeObject        := toParam;
 ObjectDirection    := odINOUT;
 vObjectValue       := ovString;
 vBinary            := False;
 vJSONValue.vBinary := vBinary;
end;

destructor TJSONParam.Destroy;
Begin
 vJSONValue.Free;
 inherited;
End;

function TJSONParam.FormatValue(bValue: String): String;
Var
 aResult  : String;
Begin
 aResult  := bValue;
 If vTypeObject = toDataset Then
  Result  := Format(TValueFormatJSON, ['ObjectType', GetObjectName(vTypeObject),
                                       'Direction',  GetDirectionName(vObjectDirection),
                                       'Encoded',    EncodedString,
                                       'ValueType',  GetValueType(vObjectValue),
                                       vParamName,   GetValueJSON(aResult)])
 Else
  Result  := Format(TValueFormatJSONValue, ['ObjectType', GetObjectName(vTypeObject),
                                            'Direction',  GetDirectionName(vObjectDirection),
                                            'Encoded',    EncodedString,
                                            'ValueType',  GetValueType(vObjectValue),
                                            vParamName,   GetValueJSON(aResult)])
End;

Function TJSONParam.EncodedString : String;
Begin
 If vEncoded Then
  Result := 'true'
 Else
  Result := 'false';
End;

function TJSONParam.GetValueJSON(bValue : String): String;
Begin
 Result := bValue;
 If vObjectValue In [ovString, ovFixedChar,   ovWideString,
                     ovFixedWideChar, ovDate, ovTime,
                     ovDateTime]  Then
  Result := '"' + bValue + '"';
End;

Procedure TJSONParam.LoadFromParam(Param : TParam);
Var
 MemoryStream : TMemoryStream;
Begin
 If Param.DataType in [ftString, ftWideString, ftFixedChar] Then
  SetValue(Param.AsString, True)
 Else If Param.DataType in [{$IFNDEF FPC}{$if CompilerVersion > 21}ftExtended,{$IFEND}{$ENDIF}
                            ftInteger, ftSmallInt, ftFloat, ftCurrency, ftFMTBcd,  ftBCD] Then
  SetValue(Param.AsString, False)
 Else If Param.DataType in [ftWideString, ftBytes, ftVarBytes, ftBlob, ftMemo,
                            ftGraphic,    ftFmtMemo,     ftOraBlob, ftOraClob] Then
  Begin
   MemoryStream := TMemoryStream.Create;
   Try
    {$IFDEF FPC}
     Param.SetData(MemoryStream);
    {$ELSE}
     {$if CompilerVersion > 21}
      MemoryStream.CopyFrom(Param.AsStream, Param.AsStream.Size);
     {$ELSE}
      Param.SetData(MemoryStream);
     {$IFEND}
    {$ENDIF}
    LoadFromStream(MemoryStream, True);
   Finally
    MemoryStream.Free;
   End;
  End
 Else If Param.DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] Then
  SetValue(Param.AsString, True);
 vObjectValue := FieldTypeToObjectValue(Param.DataType);
End;

procedure TJSONParam.LoadFromStream(Stream: TMemoryStream; Encode: Boolean);
begin
 ObjectValue        := ovBlob;
 vBinary            := False;
 SetValue(StreamToHex(Stream), Encode);
end;

procedure TJSONParam.FromJSON(JSON: String);
Var
 JsonParser  : TJsonParser;
 bJsonValue  : TJsonObject;
 vValue      : String;
Begin
 ClearJsonParser(JsonParser);
 Try
  vValue     := CopyValue(JSON);
  ParseJson(JsonParser, JSON);
  If Length(JsonParser.Output.Objects) > 0 Then
   Begin
    bJsonValue       := JsonParser.Output.Objects[0];
    vTypeObject      := GetObjectName   (bJsonValue[0].Value.Value);
    vObjectDirection := GetDirectionName(bJsonValue[1].Value.Value);
    vEncoded         := GetBooleanFromString(bJsonValue[2].Value.Value);
    vObjectValue     := GetValueType    (bJsonValue[3].Value.Value);
    vParamName       := Lowercase       (bJsonValue[4].Key);
    WriteValue(vValue);
   End;
 Finally

 End;
End;

Procedure TJSONParam.CopyFrom(JSONParam:TJSONParam );
Var
 //JsonParser  : TJsonParser;
 //bJsonValue  : TJsonObject;
 vValue      : String;
Begin
 Try
    vValue          := JSONParam.Value;
    //bJsonValue       := JSONParam.vJSONValue; //JsonParser.Output.Objects[0];
    Self.vTypeObject      := JSONParam.vTypeObject; //GetObjectName   (bJsonValue[0].Value.Value);
    Self.vObjectDirection := JSONParam.vObjectDirection;// GetDirectionName(bJsonValue[1].Value.Value);
    Self.vEncoded         := JSONParam.vEncoded;// GetBooleanFromString(bJsonValue[2].Value.Value);
    Self.vObjectValue     := JSONParam.vObjectValue;// GetValueType    (bJsonValue[3].Value.Value);
    Self.vParamName       := JSONParam.vParamName;// Lowercase       (bJsonValue[4].Key);
    Self.SetValue(vValue);
 Finally

 End;

end;

procedure TJSONParam.SaveToStream(Stream: TMemoryStream);
Begin
 HexToStream(Value, Stream);
End;

procedure TJSONParam.SetParamName(bValue: String);
begin
 vParamName := Uppercase(bValue);
end;

procedure TJSONParam.SetValue(aValue: String; Encode: Boolean);
Begin
 vEncoded            := Encode;
 vJSONValue.vEncoded := vEncoded;
 If Encode Then
  WriteValue(EncodeStrings(aValue{$IFNDEF FPC}{$if CompilerVersion > 21}, vEncoding{$IFEND}{$ENDIF}))
 Else
  WriteValue(aValue);
 vBinary             := False;
 vJSONValue.vBinary  := vBinary;
End;

function TJSONParam.ToJSON: String;
begin
 Result := vJSONValue.ToJSON;
end;

Function TJSONParam.Value : String;
begin
 Result := vJSONValue.Value;
end;

procedure TJSONParam.WriteValue(bValue: String);
begin
 {$IFNDEF FPC}
  {$if CompilerVersion > 21}
   vJSONValue.Encoding         := vEncoding;
  {$IFEND}
 {$ENDIF}
 vJSONValue.vtagName         := vParamName;
 vJSONValue.vTypeObject      := vTypeObject;
 vJSONValue.vObjectDirection := vObjectDirection;
 vJSONValue.vObjectValue     := vObjectValue;
 vJSONValue.vEncoded         := vEncoded;
 vJSONValue.WriteValue(bValue);
end;

end.
