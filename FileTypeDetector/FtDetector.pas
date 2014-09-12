{
  *******************************************************************
  AUTHOR : Flakron Shkodra 2011
  *******************************************************************
 //modified last on 19.06.2013 - added PreviewType
//modified last on 08.09.2011 - added Detect from memory stream
}





unit FtDetector;
{$mode objfpc}{$H+}
interface

uses SysUtils,Classes,fgl,FileUtil;

type

{$REGION 'TFileTypes Intf'}
TBytes = array of byte;

TFileTypePreview = (ftpNone,ftpBitmap,ftpJpeg,ftpGif,ftpPng);

TFileType = class
 public
  Signature:TBytes;//set from TFileTypes
  Extensions:string; //set from TFileTypes
  Description:string;//set from TFileTypes
  Filename:string;//set from TFileDetector
  DefaultExtension:string; //set from TFileDetector
  PreviewType:TFileTypePreview;
  function SignatureToString:string;
 end;

TFileTypes = class(specialize TFPGObjectList<TFileType>)
 strict private
   _Exceptions:TStringList;
   _SigMaxLength:Integer;
   procedure SetSigMaxLength;
 public
   constructor Create;
   property Exceptions:TStringList read _Exceptions;
   property MaxSignatureLength:Integer read _SigMaxLength;
   function FindBySignature(sig:TBytes):TFileType;
   procedure LoadFromText(AList: TStringList);
   procedure AddDelimited(TextLine:String);//commad delimited: sig, extensions, description
 end;

{$ENDREGION}

{$REGION 'TFileDetector Intf'}

 { TFileDetector }

 TFileDetector = class
 strict private
  _FileTypes:TFileTypes;
 public
  constructor Create;
  function Detect(Filename:string):TFileType;overload;
  function Detect(Stream:TStream):TFileType;overload;
  function GetFirstBytes(Filename:string):string;
  destructor Destroy;
 end;

 TFileInformations = specialize TFPGList<TFileType>;

{$ENDREGION}

implementation

{$R FtDetector.rc}

{$REGION 'TFileTypes Impl'}

function TFileType.SignatureToString: string;
var
  I: Integer;
  s:string;
begin
    s:='';
    if Length(Signature)>0 then
    for I := 0 to Length(Signature) - 1 do
    begin
       s:=s+IntToHex(Signature[I],2);
    end;
    Result:=s;
end;

procedure TFileTypes.AddDelimited(TextLine: String);
var
 lst:TStringList;
  I,J: Integer;
  ft:TFileType;
  b:TBytes;
  str:string;
  strB:array of string;
  ex:TExceptionClass;
begin
  try
    lst:=TStringList.Create;
    lst.Delimiter:=',';
    lst.DelimitedText:=TextLine;
    ft := TFileType.Create;
    try
      str := lst[0];

      SetLength(b,Length(str) div 2);
      SetLength(strB,Length(b));

      I:=1;
      J:=0;
      while I<=Length(str) do
      begin
        strB[J]:= '$'+str[I]+str[I+1];
        Inc(I,2);
        Inc(J,1);
      end;

      for I := 0 to Length(strB) - 1 do
      begin
        b[I] := StrToInt(strB[I]);
      end;

      ft.Signature := b;
      ft.Extensions := lst[1]; //extensions .doc .rar .jpeg
      ft.Description := lst[2]; //Description "word document, rar archive, jpeg image etc"
      ft.PreviewType:= ftpNone;


      if (ft.Description = 'JPG Graphic File') then
      ft.PreviewType:= ftpJpeg
      else
      if (ft.Description = 'GIF 89A') then
      ft.PreviewType:= ftpGif
      else
      if (ft.Description = 'Windows Bitmap') then
      ft.PreviewType:= ftpBitmap
      else
      if (ft.Description = 'PNG Image File') then
      ft.PreviewType:= ftpPng;


      Add(ft);
    except on e:Exception do
      begin
        e.Message:=e.Message+(TextLine);
        ShowException(e,@e);
      end;
    end;

  finally
   lst.Free;
  end;

end;

constructor TFileTypes.Create;
begin
  inherited Create;
  _SigMaxLength := 0;
  _Exceptions :=  TStringList.Create;
end;

function TFileTypes.FindBySignature(sig: TBytes): TFileType;
var
  I: Integer;
  strSig:string;
begin

   Result := nil;

   for I := 0 to Length(sig) - 1 do
   begin
      strSig:=strSig+IntToHex(sig[I],2);
   end;

   for I := 0 to Count - 1 do
   begin
     if Items[I].SignatureToString = Copy(strSig,1,Length(Items[I].Signature)*2) then
     begin
        Result := Items[I];
        Break;
     end;
   end;
end;

procedure TFileTypes.LoadFromText(AList: TStringList);
var
  I: Integer;
begin

  try
    for I := 0 to AList.Count - 1 do
    AddDelimited(AList[I]);
  except on E:Exception do
    begin
      _Exceptions.Add('Line ['+IntToStr(I)+'] : '+E.Message);
    end;
  end;

  SetSigMaxLength;
end;

procedure TFileTypes.SetSigMaxLength;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Length(Items[I].Signature)>_SigMaxLength then
    _SigMaxLength := Length(Items[I].Signature);

  end;
end;

{$ENDREGION }

{$Region 'TFileDetector Impl'}

constructor TFileDetector.Create;
var
 r:TResourceStream;
 lst:TStringList;
begin
  inherited Create;
  _FileTypes := TFileTypes.Create;
  try
    r:=TResourceStream.Create(HInstance,'SIG','FS');
    lst := TStringList.Create;
    lst.LoadFromStream(r);
    _FileTypes.LoadFromText(lst);
  finally
    r.Free;
    lst.Free;
  end;
end;

destructor TFileDetector.Destroy;
begin
  _FileTypes.Free;
end;

function TFileDetector.Detect(Filename: string): TFileType;
var
 f:TMemoryStream;
 b:TBytes;
  I: Integer;
  ft:TFileType;
begin
   Result := nil;
    if FileIsText(Filename) then
    begin
     ft :=  TFileType.Create;
     ft.DefaultExtension:=ExtractFileExt(Filename);
     ft.Description:='Plain Text File';
    end else
    begin
        try
          f:=TMemoryStream.Create;
          f.LoadFromFile(Filename);
          f.Position:=0;
          SetLength(b,_FileTypes.MaxSignatureLength);

          for I := 0 to _FileTypes.MaxSignatureLength - 1 do
          begin
            f.Read(b[I],1);
          end;

        finally
          f.Free;
        end;

        ft := _FileTypes.FindBySignature(b);
    end;

    if ft=nil then
    begin
      ft := TFileType.Create;
      ft.Description :='Unknown';
    end;

    ft.Filename := Filename;
    ft.DefaultExtension := ExtractFileExt(Filename);
    Result := ft;
end;

function TFileDetector.Detect(Stream: TStream): TFileType;
var
  b:TBytes;
  I: Integer;
  ft:TFileType;
begin
   Result := nil;


    Stream.Position:=0;
    SetLength(b,_FileTypes.MaxSignatureLength);

    for I := 0 to _FileTypes.MaxSignatureLength - 1 do
    begin
      Stream.Read(b[I],1);
    end;

    ft := _FileTypes.FindBySignature(b);

    if ft=nil then
    begin
      ft := TFileType.Create;
      ft.Description :='Unknown';
    end;

    ft.Filename := 'Memory';
    ft.DefaultExtension := '';
    Result := ft;

end;

function TFileDetector.GetFirstBytes(Filename: string): string;
var
 f:TMemoryStream;
 s:string;
  I: Integer;
  b:TBytes;
begin
     try
       f := TMemoryStream.Create;
       f.LoadFromFile(Filename);
       SetLength(b,10);
       for I := 0 to 10 do
       begin
         f.Read(b[i],1);
         s := s+ IntToHex(b[i],2);
       end;
     finally
      f.Free;
     end;
     Result := s;
end;



{$ENDREGION}

end.