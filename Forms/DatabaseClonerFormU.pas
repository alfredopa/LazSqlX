{
  *******************************************************************
  AUTHOR : Flakron Shkodra 2011
  *******************************************************************
}

unit DatabaseClonerFormU;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, Spin, types, LCLType, ComCtrls, TableInfo, DbType,
  ZConnection;

type

  { TDatabaseClonerForm }

  TLogType = (ltInfo,ltError);

  TDatabaseClonerForm = class(TForm)
    btnAccept: TBitBtn;
    btnCancel: TBitBtn;
    chkDbStructure: TCheckBox;
    chkIntegratedSecurity: TCheckBox;
    cmbDatabase: TComboBox;
    cmbDatabaseType: TComboBox;
    cmbServerName: TComboBox;
    grpLog: TGroupBox;
    grpDestServer: TGroupBox;
    imgDatabaseTypes: TImageList;
    Label2: TLabel;
    lblDatabase1: TLabel;
    lblPassword: TLabel;
    lblPort: TLabel;
    lblProgress: TLabel;
    lblSever: TLabel;
    lblUseraname: TLabel;
    lstLog: TListBox;
    btnOpenFile: TSpeedButton;
    OpenDialog1: TOpenDialog;
    txtErrors: TMemo;
    pgLog: TPageControl;
    pbProgressBar: TProgressBar;
    pnlMain: TPanel;
    tabProgress: TTabSheet;
    tabErrors: TTabSheet;
    txtConnStr: TMemo;
    txtPassword: TEdit;
    txtPort: TSpinEdit;
    txtUserName: TEdit;
    txtDestinationDbName: TEdit;
    procedure btnAcceptClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure cmbDatabaseEnter(Sender: TObject);
    procedure cmbDatabaseTypeChange(Sender: TObject);
    procedure cmbDatabaseTypeDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FTableInfos: TTableInfos;
    FDbType: TDatabaseType;
    procedure WriteLog(Msg:string; LogType:TLogType);
    { private declarations }
  public
    { public declarations }
    function ShowModal(Infos: TTableInfos): TModalResult;
  end;

var
  DatabaseClonerForm: TDatabaseClonerForm;

  bmpSqlType: TBitmap;
  bmpOracleType: TBitmap;
  bmpMySqlType: TBitmap;
  bmpSqliteType: TBitmap;
  bmpFirebird: TBitmap;

implementation

uses AsDatabaseCloner, AsStringUtils, ProgressFormU;

{$R *.lfm}

{ TDatabaseClonerForm }

procedure TDatabaseClonerForm.cmbDatabaseTypeDrawItem(Control: TWinControl;
  Index: integer; ARect: TRect; State: TOwnerDrawState);
var
  cmb: TComboBox;
begin
  cmb := Control as TComboBox;

  if odSelected in State then
  begin
    cmb.Canvas.GradientFill(ARect, $00E2E2E2, clGray, gdVertical);
  end
  else
  begin
    cmb.Canvas.Brush.Color := clWindow;
    cmb.Canvas.FillRect(ARect);
  end;


  case Index of
    0: cmb.Canvas.Draw(ARect.Left, ARect.Top, bmpSqlType);
    1: cmb.Canvas.Draw(ARect.Left, ARect.Top, bmpOracleType);
    2: cmb.Canvas.Draw(ARect.Left, ARect.Top, bmpMySqlType);
    3: cmb.Canvas.Draw(ARect.Left, ARect.Top, bmpSqliteType);
    4: cmb.Canvas.Draw(ARect.Left, ARect.Top, bmpFirebird);
  end;

  cmb.Canvas.Font.Size := 10;
  cmb.Canvas.Brush.Style := bsClear;
  cmb.Canvas.TextOut(ARect.Left + 30, ARect.Top + 3, cmb.Items[Index]);
end;

procedure TDatabaseClonerForm.cmbDatabaseTypeChange(Sender: TObject);
begin
  cmbDatabase.Width := 397;
  txtDestinationDbName.Width:= 581;
  btnOpenFile.Visible:=False;
  lblUseraname.Visible := True;
  txtUserName.Visible := True;
  lblPassword.Visible := True;
  txtPassword.Visible := True;
  lblPort.Visible := True;
  txtPort.Visible := True;
  lblSever.Visible := True;
  cmbServerName.Visible := True;
  lblDatabase1.Caption := 'Destination Database Name';
  cmbDatabase.Visible:=True;
  case cmbDatabaseType.ItemIndex of
    0:
    begin
      txtPort.Text := '0';
      txtUserName.Text := 'sa';
      txtPassword.Text := '';
      lblDatabase1.Caption := 'Destination Database Name (Creates new database)';
    end;
    1:
    begin
      txtPort.Text := '1521';
      txtUserName.Text := 'sa';
      txtPassword.Text := '';
      lblDatabase1.Caption := 'Destination Database Name (Uses existing database)';
    end;
    2:
    begin
      txtPort.Text := '3306';
      txtUserName.Text := 'root';
      txtPassword.Text := '';
      lblDatabase1.Caption := 'Destination Database Name (Creates new database)';
    end;
    3:
    begin
      //cmbDatabase.Width := 217;
      cmbDatabase.Visible := False;

      lblUseraname.Visible := False;
      txtUserName.Visible := False;
      lblPassword.Visible := False;
      txtPassword.Visible := False;
      lblPort.Visible := False;
      txtPort.Visible := False;
      lblSever.Visible := False;
      cmbServerName.Visible := False;
      lblDatabase1.Caption := 'Destination Database Name (Creates new database, provide full physical path like C:\~~.sqlite)';
      txtDestinationDbName.Text:=ChangeFileExt(txtDestinationDbName.Text,'')+'.sqlite';
    end;
    4:
    begin
      txtDestinationDbName.Width := 557;
      cmbDatabase.Visible := False;
      btnOpenFile.Visible:=True;

      lblUseraname.Visible := True;
      txtUserName.Visible := True;
      lblPassword.Visible := True;
      txtPassword.Visible := True;
      lblPort.Visible := False;
      txtPort.Visible := False;
      lblSever.Visible := False;
      cmbServerName.Visible := False;
      lblDatabase1.Caption := 'Destination Database Name (Uses existing database file. Provide full physical path like C:\~~.fdb)';
      txtDestinationDbName.Text:=ChangeFileExt(txtDestinationDbName.Text,'')+'.fdb';
    end;
  end;

  FDbType :=TDbUtils.DatabaseTypeFromString(cmbDatabaseType.Text);

end;

procedure TDatabaseClonerForm.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TDatabaseClonerForm.btnOpenFileClick(Sender: TObject);
begin
 if OpenDialog1.Execute then
 begin
   txtDestinationDbName.Text:=OpenDialog1.FileName;
 end;
end;

procedure TDatabaseClonerForm.cmbDatabaseEnter(Sender: TObject);
var
  DbConnection: TZConnection;
begin
  try
    try
      FDbType:=TDatabaseType(cmbDatabaseType.ItemIndex);
      DbConnection := TZConnection.Create(nil);
      DbConnection.HostName := cmbServerName.Text;
      DbConnection.User := txtUserName.Text;
      DbConnection.Password := txtPassword.Text;
      DbConnection.Catalog := cmbDatabase.Text;
      DBConnection.LoginPrompt := False;
      DbConnection.Port := txtPort.Value;
      DbConnection.Protocol :=
       TDbUtils.DatabaseTypeAsString(TDatabaseType(cmbDatabaseType.ItemIndex), True);


      case FDbType of
        dtMsSql:
        begin
          DbConnection.Connect;
          DbConnection.GetCatalogNames(cmbDatabase.Items);
        end;

        dtMySql:
        begin
          DbConnection.Connect;
          DbConnection.GetCatalogNames(cmbDatabase.Items);
        end;

      end
    except
      on e: Exception do
      begin
        ShowMessage(e.Message);
      end;

    end;
  finally
    DbConnection.Free;
  end;

end;

procedure TDatabaseClonerForm.btnAcceptClick(Sender: TObject);
var
  dbc: TAsDatabaseCloner;
  I: integer;
  wt: TStringWrapType;
  destDb:string;
  connDb:string;
  dbi:TDbConnectionInfo;
begin
  try
    pnlMain.Enabled:=False;
    btnAccept.Enabled:=False;
    btnCancel.Enabled:=False;
    txtDestinationDbName.Enabled:=False;

    destDb:= txtDestinationDbName.Text;
    cmbDatabaseEnter(Sender);
    lstLog.Clear;
    txtErrors.Clear;

    pgLog.ActivePageIndex:=0;

    WriteLog('Starting...',ltInfo);
    WriteLog('',ltInfo);

    if FDbType in [dtSQLite,dtFirebirdd] then
    begin
      connDb:=destDb;
    end else
    begin
      if cmbDatabase.Items.Count<1 then
      begin
        WriteLog('Sorry! We can''t create database on that server.',ltError);
        WriteLog('Process stopped',ltInfo);
        Exit;
      end;
      connDb:= cmbDatabase.Items[0];
    end;

    case FDbType of
      dtMsSql: wt := swtBrackets;
      dtOracle: wt := swtQuotes;
      else
        wt := swtNone;
    end;


    if txtPort.Visible then
      if not TryStrToInt(txtPort.Text, i) then
      begin
        WriteLog('Port must be number.',ltError);
        WriteLog('Process stopped.',ltInfo);
        Exit;
      end;

    dbi:=TDbConnectionInfo.Create;
    dbi.Server:=cmbServerName.Text;
    dbi.Database:=connDb;
    dbi.Username := txtUserName.Text;
    dbi.Password := txtPassword.Text;
    dbi.DatabaseType := TDatabaseType(cmbDatabaseType.ItemIndex);
    dbi.Port := StrToInt(txtPort.Text);

    dbc := TAsDatabaseCloner.Create(dbi,txtDestinationDbName.Text);
    try

      dbc.MakeDatabase;
      pbProgressBar.Max := FTableInfos.Count;
      pbProgressBar.Step:=1;


      for I := 0 to FTableInfos.Count - 1 do
      begin
        try
         lblProgress.Caption := 'Processing [' + FTableInfos[I].Tablename + ']';
         dbc.MakeTable(FTableInfos[I],false,True);
         pbProgressBar.StepIt;
         WriteLog('SUCCESS: Table [' + FTableInfos[I].Tablename + ']',ltInfo);
         Application.ProcessMessages;
        except on e:Exception do
          begin
            WriteLog('FAIL: Table ['+FTableInfos[I].Tablename+']',ltError);
          end;
        end;
      end;

      pbProgressBar.Position:=0;

      WriteLog('',ltInfo);
      WriteLog('CONSTRAINTS',ltInfo);
      WriteLog('',ltInfo);

      if cmbDatabaseType.ItemIndex<>3 then
      for I := 0 to FTableInfos.Count - 1 do
      begin
        try
         lblProgress.Caption := 'Recreating constraints [' + FTableInfos[I].Tablename + ']';
         dbc.CreateConstraints(FTableInfos[I]);
         pbProgressBar.StepIt;
         WriteLog('SUCCESS: Create constraints for ['+FTableInfos[I].Tablename+']',ltInfo);
         Application.ProcessMessages;
        except on e:exception do
          begin
            WriteLog('FAIL: Create constraints for ['+FTableInfos[I].Tablename+']',ltError);
          end;
        end;
      end;

      WriteLog('',ltInfo);
      WriteLog('PROCESS FINISHED.',ltInfo);

    except
      on E: Exception do
      begin
        //dbc.UnmakeDatabase;
        WriteLog(e.Message,ltError);
        ShowMessage(e.Message);
      end;
    end;

    WriteLog('End',ltInfo);

  finally
    dbc.Free;
    pbProgressBar.Position:=0;
    lblProgress.Caption:='Progress';
    pnlMain.Enabled:=True;
    btnAccept.Enabled:=True;
    btnCancel.Enabled:=True;
    txtDestinationDbName.Enabled:=True;
  end;
end;

procedure TDatabaseClonerForm.FormCreate(Sender: TObject);
begin
  bmpSqlType := TBitmap.Create;
  bmpOracleType := TBitmap.Create;
  bmpMySqlType := TBitmap.Create;
  bmpSqliteType := TBitmap.Create;
  bmpFirebird := TBitmap.Create;

  imgDatabaseTypes.GetBitmap(0, bmpSqlType);
  imgDatabaseTypes.GetBitmap(1, bmpOracleType);
  imgDatabaseTypes.GetBitmap(2, bmpMySqlType);
  imgDatabaseTypes.GetBitmap(3, bmpSqliteType);
  imgDatabaseTypes.GetBitmap(4,bmpFirebird);


end;

procedure TDatabaseClonerForm.FormDestroy(Sender: TObject);
begin
  bmpMySqlType.Free;
  bmpSqliteType.Free;
  bmpOracleType.Free;
  bmpSqlType.Free;
  bmpFirebird.Free;
end;

procedure TDatabaseClonerForm.FormShow(Sender: TObject);
begin
 pgLog.ActivePageIndex:=0;
end;

procedure TDatabaseClonerForm.WriteLog(Msg: string; LogType: TLogType);
var
  s:string;
begin

  if Trim(Msg)=EmptyStr then
  begin
    s := '';
  end
  else
  begin
    s := TimeToStr(Now)+'   '+Msg;
  end;

  case LogType of
    ltInfo:lstLog.Items.Add(s);
    ltError:txtErrors.Lines.Add(s);
  end;

  lstLog.ItemIndex:=lstLog.Count-1;
end;

function TDatabaseClonerForm.ShowModal(Infos: TTableInfos): TModalResult;
begin
  FTableInfos := Infos;
  Result := inherited ShowModal;
end;

end.