unit CodeCoverage.ApiHelper;

interface

uses
  System.Generics.Collections, System.Classes, System.SysUtils,
  Vcl.Menus,
  ToolsAPI, PlatformAPI;

type
  OTA = record
  strict private
  class var
    FIDELibSuffix: string;
  public
    class function AboutBoxServices: IOTAAboutBoxServices; static;
    class function DebuggerServices: IOTADebuggerServices; static;
    class function EditorServices: IOTAEditorServices; static;
    class function IDELibSuffix: string; static;
    class function IsPackageInstalled(const APackageName: string): Boolean; static;
    class function KeyboardServices: IOTAKeyboardServices; static;
    class function ModuleServices: IOTAModuleServices; static;
    class function PackageServices: IOTAPackageServices; static;
    class function PlatformServices: IOTAPlatformServices; static;
    class function Services: IOTAServices; static;
  end;

  NTA = record
  public
    class function EnvironmentOptionsServices: INTAEnvironmentOptionsServices; static;
    class function FindMenuItem(const AName: string): TMenuItem; overload; static;
    class function FindMenuItem(const BreadCrumbs: array of string): TMenuItem; overload; static;
    class function Services: INTAServices; static;
  end;

type
  TCommonNotifier = class(TInterfacedObject, IOTANotifier)
  private
    FID: Integer;
    procedure Unregister;
  protected
    { IOTANotifier }
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;

    function DoRegister: Integer; virtual;
    procedure DoUnregister(ID: Integer); virtual;
    procedure InternalAfterSave; virtual;
    procedure InternalBeforeSave; virtual;
    procedure InternalDestroyed; virtual;
    procedure InternalModified; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Release;
  end;

  TNotifierHost = class(TInterfacedPersistent)
  private
    FNotifiers: TList<TCommonNotifier>;
  protected
    property Notifiers: TList<TCommonNotifier> read FNotifiers;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddNotifier(Value: TCommonNotifier);
    procedure ClearNotifiers;
    function FindNotifier<T: TCommonNotifier>(Predicate: TPredicate<T>): Boolean; overload;
    function FindNotifier<T: TCommonNotifier>(Predicate: TPredicate<T>; out Instance: T): Boolean; overload;
    procedure RemoveNotifier(Value: TCommonNotifier);
  end;

  THostedNotifier = class(TCommonNotifier)
  private
    FNotifierHost: TNotifierHost;
  protected
    procedure CheckNotifierHost(ANotifierHost: TNotifierHost); virtual;
    property NotifierHost: TNotifierHost read FNotifierHost;
  public
    constructor Create(ANotifierHost: TNotifierHost); overload;
    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils;

type
  TMenuItemHelper = class helper for TMenuItem
  public
    function FindByName(const AName: string): TMenuItem;
  end;

procedure TCommonNotifier.AfterConstruction;
begin
  inherited;
  FID := DoRegister;
end;

procedure TCommonNotifier.AfterSave;
begin
  InternalAfterSave;
end;

procedure TCommonNotifier.BeforeSave;
begin
  InternalBeforeSave;
end;

constructor TCommonNotifier.Create;
begin
  inherited;
  FID := -1;
end;

destructor TCommonNotifier.Destroy;
begin
  Unregister;
  inherited;
end;

procedure TCommonNotifier.Destroyed;
begin
  InternalDestroyed;
end;

function TCommonNotifier.DoRegister: Integer;
begin
  Result := -1;
end;

procedure TCommonNotifier.Modified;
begin
  InternalModified;
end;

procedure TCommonNotifier.DoUnregister(ID: Integer);
begin
end;

procedure TCommonNotifier.InternalAfterSave;
begin
end;

procedure TCommonNotifier.InternalBeforeSave;
begin
end;

procedure TCommonNotifier.InternalDestroyed;
begin
  Unregister;
end;

procedure TCommonNotifier.InternalModified;
begin
end;

procedure TCommonNotifier.Release;
begin
  Unregister;
end;

procedure TCommonNotifier.Unregister;
var
  tmpID: Integer;
begin
  if FID >= 0 then begin
    { to avoid recursive call }
    tmpID := FID;
    FID := -1;
    DoUnregister(tmpID);
  end;
end;

function TMenuItemHelper.FindByName(const AName: string): TMenuItem;
var
  item: TMenuItem;
begin
  for item in Self do begin
    if SameText(item.Name, AName) then
      Exit(item);
    Result := item.FindByName(AName);
    if Result <> nil then
      Exit;
  end;
  Result := nil;
end;

constructor TNotifierHost.Create;
begin
  inherited Create;
  FNotifiers := TList<TCommonNotifier>.Create();
end;

destructor TNotifierHost.Destroy;
begin
  ClearNotifiers;
  FNotifiers.Free;
  inherited Destroy;
end;

procedure TNotifierHost.AddNotifier(Value: TCommonNotifier);
begin
  FNotifiers.Add(Value);
end;

procedure TNotifierHost.ClearNotifiers;
var
  I: Integer;
  item: TCommonNotifier;
begin
  for I := FNotifiers.Count - 1 downto 0 do begin
    item := FNotifiers[I];
    FNotifiers.Delete(I);
    item.Release;
  end;
end;

function TNotifierHost.FindNotifier<T>(Predicate: TPredicate<T>): Boolean;
var
  instance: T;
begin
  Result := FindNotifier<T>(Predicate, instance);
end;

function TNotifierHost.FindNotifier<T>(Predicate: TPredicate<T>; out Instance: T): Boolean;
var
  notifier: TCommonNotifier;
  item: T;
begin
  Result := False;
  Instance := nil;
  for notifier in Notifiers do begin
    if notifier is T then begin
      item := notifier as T;
      if Predicate(item) then begin
        Instance := Item;
        Result := True;
        Break;
      end;
    end;
  end;
end;

procedure TNotifierHost.RemoveNotifier(Value: TCommonNotifier);
begin
  FNotifiers.Remove(Value);
end;

class function OTA.AboutBoxServices: IOTAAboutBoxServices;
begin
  BorlandIDEServices.GetService(IOTAAboutBoxServices, Result);
end;

class function OTA.DebuggerServices: IOTADebuggerServices;
begin
  BorlandIDEServices.GetService(IOTADebuggerServices, Result);
end;

class function OTA.EditorServices: IOTAEditorServices;
begin
  BorlandIDEServices.GetService(IOTAEditorServices, Result);
end;

class function OTA.IDELibSuffix: string;
var
  I: Integer;
  myInfo: IOTAPackageInfo;
begin
  if FIDELibSuffix = '' then begin
    { Extract LibSuffix from RTL package }
    for I := 0 to PackageServices.PackageCount - 1 do
    begin
      myInfo := PackageServices.Package[I];
      if SameText(myInfo.SymbolFileName, 'rtl') then begin // do not localize
        FIDELibSuffix := Copy(TPath.GetFileNameWithoutExtension(myInfo.Name), Length(myInfo.SymbolFileName) + 1);
        Break;
      end;
    end;
  end;
  Result := FIDELibSuffix;
end;

class function OTA.IsPackageInstalled(const APackageName: string): Boolean;
var
  fullName: string;
  I: Integer;
begin
  fullName := APackageName + IDELibSuffix + '.bpl'; // do not localize
  for I := 0 to PackageServices.PackageCount - 1 do begin
    if SameText(PackageServices.PackageNames[I], fullName) then Exit(True);
  end;
  Result := False;
end;

class function OTA.KeyboardServices: IOTAKeyboardServices;
begin
  BorlandIDEServices.GetService(IOTAKeyboardServices, Result);
end;

class function OTA.ModuleServices: IOTAModuleServices;
begin
  BorlandIDEServices.GetService(IOTAModuleServices, Result);
end;

class function OTA.PackageServices: IOTAPackageServices;
begin
  BorlandIDEServices.GetService(IOTAPAckageServices, Result);
end;

class function OTA.PlatformServices: IOTAPlatformServices;
begin
  BorlandIDEServices.GetService(IOTAPlatformServices, Result);
end;

class function OTA.Services: IOTAServices;
begin
  BorlandIDEServices.GetService(IOTAServices, Result);
end;

class function NTA.EnvironmentOptionsServices: INTAEnvironmentOptionsServices;
begin
  BorlandIDEServices.GetService(INTAEnvironmentOptionsServices, Result);
end;

class function NTA.FindMenuItem(const AName: string): TMenuItem;
begin
  Result := Services.MainMenu.Items.FindByName(AName);
end;

class function NTA.FindMenuItem(const BreadCrumbs: array of string): TMenuItem;
var
  item: TMenuItem;
  S: string;
begin
  item := Services.MainMenu.Items;
  for S in BreadCrumbs do begin
    item := item.Find(S);
    if item = nil then Exit(nil);
  end;
  Result := item;
end;

class function NTA.Services: INTAServices;
begin
  BorlandIDEServices.GetService(INTAServices, Result);
end;

constructor THostedNotifier.Create(ANotifierHost: TNotifierHost);
begin
  CheckNotifierHost(ANotifierHost);
  inherited Create;
  FNotifierHost := ANotifierHost;
  FNotifierHost.AddNotifier(Self);
end;

destructor THostedNotifier.Destroy;
begin
  FNotifierHost.RemoveNotifier(Self);
  inherited;
end;

procedure THostedNotifier.CheckNotifierHost(ANotifierHost: TNotifierHost);
begin
  if ANotifierHost = nil then
    raise EProgrammerNotFound.Create('NotifierHost must not be nil!');
end;

end.
