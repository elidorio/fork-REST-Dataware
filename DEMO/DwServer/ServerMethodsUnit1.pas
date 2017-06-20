// Para Funcionar o Servidor � necess�rio que todos os M�todos declarados em PUBLIC sejam
//adicionados em seus Projetos.
//Gilberto Rocha da Silva

unit ServerMethodsUnit1;

interface

uses System.SysUtils,         System.Classes,           Datasnap.DSServer,  Datasnap.DSAuth,
     FireDAC.Stan.Intf,       FireDAC.Stan.Option,      FireDAC.Stan.Param,
     FireDAC.Stan.Error,      FireDAC.DatS,             FireDAC.Phys.Intf,  FireDAC.DApt.Intf,
     FireDAC.Stan.Async,      FireDAC.DApt,             FireDAC.UI.Intf,    FireDAC.VCLUI.Wait,
     FireDAC.Stan.Def,        FireDAC.Stan.Pool,        FireDAC.Phys,       Data.DB,
     FireDAC.Comp.Client,     FireDAC.Phys.IBBase,      FireDAC.Phys.IB,    FireDAC.Comp.UI,
     FireDAC.Comp.DataSet,    Data.FireDACJSONReflect,  System.JSON,
     FireDAC.Stan.StorageBin, FireDAC.Stan.StorageJSON, FireDAC.Phys.IBDef,
     WebModuleUnit1,          Vcl.Dialogs,              TypInfo,
     IniFiles,  Vcl.Forms,    uRestPoolerDB, URestPoolerDBMethod, FireDAC.Phys.FBDef, FireDAC.Phys.FB,
  uRestDriverFD, ZAbstractConnection, ZConnection, uRestDriverZEOS, UniProvider,
  InterBaseUniProvider, DBAccess, Uni, uRestDriverUnidac;

type
{$METHODINFO ON}
  TServerMethods1 = class(TDataModule)
    FDGUIxWaitCursor1      : TFDGUIxWaitCursor;
    FDStanStorageJSONLink1 : TFDStanStorageJSONLink;
    Server_FDConnection: TFDConnection;
    RESTPoolerDB: TRESTPoolerDB;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    RESTDriverFD1: TRESTDriverFD;
    RESTDriverZEOS1: TRESTDriverZEOS;
    ZConnection1: TZConnection;
    RESTPoolerDBZEOS: TRESTPoolerDB;
    RESTDriverUnidac1: TRESTDriverUnidac;
    RESTPoolerUNIDAC: TRESTPoolerDB;
    UniConnection1: TUniConnection;
    InterBaseUniProvider1: TInterBaseUniProvider;
    procedure Server_FDConnectionBeforeConnect(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure ZConnection1BeforeConnect(Sender: TObject);
    procedure UniConnection1BeforeConnect(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
{$METHODINFO OFF}

Var
 UserName,
 Password      : String;
 vDatabaseName : String;


implementation

{$R *.dfm}

uses System.StrUtils, System.Generics.Collections, RestDWServerFormU;

procedure TServerMethods1.DataModuleCreate(Sender: TObject);
begin
 UserName := RestDWForm.Username;
 Password := RestDWForm.Password;
end;

procedure TServerMethods1.Server_FDConnectionBeforeConnect(Sender: TObject);
Var
 porta_BD,
 servidor,
 database,
 pasta,
 usuario_BD,
 senha_BD      : String;
Begin
 servidor      := RestDWForm.DatabaseIP;
 database      := RestDWForm.edBD.Text;
 pasta         := IncludeTrailingPathDelimiter(RestDWForm.edPasta.Text);
 porta_BD      := RestDWForm.edPortaBD.Text;
 usuario_BD    := RestDWForm.edUserNameBD.Text;
 senha_BD      := RestDWForm.edPasswordBD.Text;
 vDatabaseName := pasta + database;
 TFDConnection(Sender).Params.Clear;
 TFDConnection(Sender).Params.Add('DriverID=FB');
 TFDConnection(Sender).Params.Add('Server='    + Servidor);
 TFDConnection(Sender).Params.Add('Port='      + porta_BD);
 TFDConnection(Sender).Params.Add('Database='  + vDatabaseName);
 TFDConnection(Sender).Params.Add('User_Name=' + usuario_BD);
 TFDConnection(Sender).Params.Add('Password='  + senha_BD);
 TFDConnection(Sender).Params.Add('Protocol=TCPIP');
 //Server_FDConnection.Params.Add('CharacterSet=ISO8859_1');
 TFDConnection(Sender).UpdateOptions.CountUpdatedRecords := False;
end;

procedure TServerMethods1.UniConnection1BeforeConnect(Sender: TObject);
Var
 porta_BD,
 servidor,
 database,
 pasta,
 usuario_BD,
 senha_BD      : String;
Begin
 servidor      := RestDWForm.DatabaseIP;
 database      := RestDWForm.edBD.Text;
 pasta         := IncludeTrailingPathDelimiter(RestDWForm.edPasta.Text);
 porta_BD      := RestDWForm.edPortaBD.Text;
 usuario_BD    := RestDWForm.edUserNameBD.Text;
 senha_BD      := RestDWForm.edPasswordBD.Text;
 vDatabaseName := pasta + database;
 TUniConnection(Sender).Server        := Servidor;
 TUniConnection(Sender).Database      := vDatabaseName;
 TUniConnection(Sender).Port          := StrToInt(porta_BD);
 TUniConnection(Sender).ProviderName  := 'InterBase';
 TUniConnection(Sender).Username      := usuario_BD;
 TUniConnection(Sender).Password      := senha_BD;
end;

procedure TServerMethods1.ZConnection1BeforeConnect(Sender: TObject);
Var
 porta_BD,
 servidor,
 database,
 pasta,
 usuario_BD,
 senha_BD      : String;
Begin
 servidor                      := RestDWForm.DatabaseIP;
 database                      := RestDWForm.edBD.Text;
 pasta                         := IncludeTrailingPathDelimiter(RestDWForm.edPasta.Text);
 porta_BD                      := RestDWForm.edPortaBD.Text;
 usuario_BD                    := RestDWForm.edUserNameBD.Text;
 senha_BD                      := RestDWForm.edPasswordBD.Text;
 vDatabaseName                 := pasta + database;
 TZConnection(Sender).HostName := Servidor;
 TZConnection(Sender).Database := vDatabaseName;
 TZConnection(Sender).Port     := StrToInt(porta_BD);
 TZConnection(Sender).User     := usuario_BD;
 TZConnection(Sender).Password := senha_BD;
End;

end.

