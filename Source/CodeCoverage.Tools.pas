unit CodeCoverage.Tools;

interface

{ assure Winapi.Windows appears before Vcl.Graphics, because both declare TBitmap }
uses
  Winapi.Windows,
  System.Classes,
  Vcl.Graphics;

type
  TTools = class
  private
  class var
    FVersion: string;
    class function GetDescription: string; static;
    class function GetTitle: string; static;
    class function GetVersion: string; static;
  public
    class function AppVersion: string; static;
    class function CreateFromIconResource(const AName: string; ASize: Integer): TBitmap; overload;
    class procedure LoadFromIconResource(Target: TIcon; const AName: string);
    class procedure Postpone(AProc: TThreadMethod; ADelayMS: Cardinal = 0); overload;
    class procedure Postpone(AProc: TThreadProcedure; ADelayMS: Cardinal = 0); overload;
    class property Description: string read GetDescription;
    class property Title: string read GetTitle;
    class property Version: string read GetVersion;
  end;

implementation

uses
  System.SysUtils, System.Threading,
  CodeCoverage.Consts;

class function TTools.AppVersion: string;
var
  build: Cardinal;
  major: Cardinal;
  minor: Cardinal;
begin
  if GetProductVersion(GetModuleName(HInstance), major, minor, build) then begin
    Result := Format('V%d.%d.%d', [major, minor, build]); // do not localize
  end
  else begin
    Result := cVersion;
  end;
end;

class function TTools.CreateFromIconResource(const AName: string; ASize: Integer): TBitmap;
var
  icon: TIcon;
begin
  Result := TBitmap.Create;
  icon := TIcon.Create;
  try
    icon.SetSize(ASize, ASize);
    LoadFromIconResource(icon, AName);
    Result.Assign(icon);
  finally
    icon.Free;
  end;
end;

class function TTools.GetDescription: string;
begin
  Result := SDescription + sLineBreak + sLineBreak + cCopyRight;
end;

class function TTools.GetTitle: string;
begin
  Result := cTitle + ' ' + Version;
end;

class function TTools.GetVersion: string;
begin
  if FVersion = '' then begin
    FVersion := TTools.AppVersion;
  end;
  Result := FVersion;
end;

class procedure TTools.LoadFromIconResource(Target: TIcon; const AName: string);
begin
  Target.Handle := LoadImage(HInstance, PChar(AName), IMAGE_ICON, Target.Width, Target.Height, 0);
end;

class procedure TTools.Postpone(AProc: TThreadMethod; ADelayMS: Cardinal = 0);
begin
  TTask.Run(
    procedure
    begin
      if ADelayMS > 0 then begin
        Sleep(ADelayMS);
      end;
      TThread.Queue(nil, AProc);
    end);
end;

class procedure TTools.Postpone(AProc: TThreadProcedure; ADelayMS: Cardinal = 0);
begin
  TTask.Run(
    procedure
    begin
      if ADelayMS > 0 then begin
        Sleep(ADelayMS);
      end;
      TThread.Queue(nil, AProc);
    end);
end;

end.

