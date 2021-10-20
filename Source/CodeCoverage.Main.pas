unit CodeCoverage.Main;

interface

uses
  Vcl.Graphics, Vcl.ComCtrls,
  CodeCoverage.Handler;

type
  TMagician = class
  private
    FAboutBitmap: TBitmap;
    FCodeCoverage: TCodeCoverage;
    FPluginInfoID: Integer;
    FSplashBitmap: TBitmap;
    FVersion: string;
  class var
    FInstance: TMagician;
    function CreateFromIconResource(ASize: Integer): TBitmap; overload;
    function GetAboutBitmap: TBitmap;
    function GetDescription: string;
    function GetSplashBitmap: TBitmap;
    function GetTitle: string;
    function GetVersion: string;
  protected
    procedure AddMenuItems;
    procedure AddToolbars;
    procedure RemoveMenuItem;
    procedure RemoveToolButtons; overload;
    procedure RemoveToolButtons(ToolBar: TToolBar); overload;
    property AboutBitmap: TBitmap read GetAboutBitmap;
    property CodeCoverage: TCodeCoverage read FCodeCoverage;
    property Description: string read GetDescription;
    property SplashBitmap: TBitmap read GetSplashBitmap;
    property Title: string read GetTitle;
    property Version: string read GetVersion;
  public
    constructor Create;
    destructor Destroy; override;
    class procedure CreateInstance;
    class procedure DestroyInstance;
  end;

procedure Register;

implementation

uses
  System.IOUtils, System.Types, System.StrUtils, System.Classes,
  Vcl.Controls,
  CodeCoverage.Tools, CodeCoverage.Consts, CodeCoverage.DM, CodeCoverage.KeyBindings, CodeCoverage.ApiHelper,
  ToolsApi;

resourcestring
  SCodeCoverage = 'Code Coverage';

const
  cRunDebugMenuItemName = 'RunRunNoDebugItem';
  cRunMenuItemName = 'RunRunItem';
  cSplashBitmapSize = 24;
  cAboutBitmapSize = 48;
  cCodeCoverageIni = 'CodeCoverage.ini';
  cCodeCoverageToolbar = 'CodeCoverageToolbar';

type
  TToolButtonHelper = class helper for TToolButton
  public
    function GetToolBar: TToolBar;
    procedure SetToolBar(const Value: TToolBar);
    property ToolBar: TToolBar read GetToolBar write SetToolBar;
  end;

function TToolButtonHelper.GetToolBar: TToolBar;
begin
  Result := FToolBar;
end;

procedure TToolButtonHelper.SetToolBar(const Value: TToolBar);
begin
  inherited SetToolBar(Value);
end;

constructor TMagician.Create;
begin
  inherited;

  FCodeCoverage := TCodeCoverage.Create;
  FCodeCoverage.Initialize;

  dmCodeCoverage := TdmCodeCoverage.Create(nil);
  dmCodeCoverage.CodeCoverage := CodeCoverage;

  {$IF Declared(TGraphicArray) }
  SplashScreenServices.AddPluginBitmap(Title, dmCodeCoverage.ImageArray[cIconName], False, '', '');
  FPluginInfoID := OTA.AboutBoxServices.AddPluginInfo(Title, Description, dmCodeCoverage.ImageArray[cIconName]);
  {$ELSE}
  SplashScreenServices.AddPluginBitmap(Title, SplashBitmap.Handle);
  FPluginInfoID := OTA.AboutBoxServices.AddPluginInfo(Title, Description, AboutBitmap.Handle, False, '', '', otaafDefined);
  {$IFEND}
  TKeyboardBinding.Create(CodeCoverage);

  dmCodeCoverage.ImageIndexOffset := NTA.Services.AddImages(dmCodeCoverage.Images, cInternalName);
  AddMenuItems;
  AddToolbars;
end;

destructor TMagician.Destroy;
begin
  CodeCoverage.ClearNotifiers;

  RemoveToolButtons;
  RemoveMenuItem;
//  NTA.Services.AddImages(nil, cInternalName);

  if FPluginInfoID > 0 then begin
    OTA.AboutBoxServices.RemovePluginInfo(FPluginInfoID);
  end;

  dmCodeCoverage.Free;
  dmCodeCoverage := nil;

  FCodeCoverage.Free;
  FAboutBitmap.Free;
  FSplashBitmap.Free;
  inherited;
end;

procedure TMagician.AddMenuItems;
begin
  CodeCoverage.RunMenuItem := NTA.FindMenuItem(cRunMenuItemName);

  NTA.Services.AddActionMenu('', dmCodeCoverage.actSwitchCodeCoverage, nil, False);
  NTA.Services.AddActionMenu(cRunDebugMenuItemName, dmCodeCoverage.actRunCodeCoverage, dmCodeCoverage.mnuRunCodeCoverage, True);
end;

procedure TMagician.AddToolbars;
const
  cBtnSwitch = cCodeCoverageToolbar + 'BtnSwitch';
  cBtnRun = cCodeCoverageToolbar + 'BtnRun';
var
  btn: TToolButton;
  dbgR: TRect;
  I: Integer;
  tlb: TToolBar;
  tlbDebug: TToolBar;
begin
  tlb := NTA.Services.ToolBar[cCodeCoverageToolbar];
  if tlb <> nil then begin
    { remove existent buttons - just in case... }
    for I := tlb.ButtonCount - 1 downto 0 do begin
      btn := tlb.Buttons[I];
      if MatchStr(btn.Name, [cBtnRun, cBtnSwitch]) then begin
        btn.ToolBar := nil;
        btn.Free;
      end;
    end;
  end
  else begin
    tlbDebug := NTA.Services.ToolBar[sDebugToolBar];
    dbgR := tlbDebug.BoundsRect;
    tlb := NTA.Services.NewToolbar(cCodeCoverageToolbar, SCodeCoverage, tlbDebug.Name, False);
    tlb.AutoSize := True;
    tlb.SetBounds(dbgR.Right + 1, dbgR.Top, tlb.Width, dbgR.Height);
  end;
  NTA.Services.AddToolButton(tlb.Name, cBtnRun, dmCodeCoverage.actRunCodeCoverage);
  NTA.Services.AddToolButton(tlb.Name, cBtnSwitch, dmCodeCoverage.actSwitchCodeCoverage);
  tlb.Visible := True;
end;

function TMagician.CreateFromIconResource(ASize: Integer): TBitmap;
begin
  Result := TTools.CreateFromIconResource(cIconName, ASize);
end;

class procedure TMagician.CreateInstance;
begin
  FInstance := TMagician.Create;
end;

class procedure TMagician.DestroyInstance;
begin
  FInstance.Free;
end;

function TMagician.GetAboutBitmap: TBitmap;
begin
  if FAboutBitmap = nil then begin
    FAboutBitmap := CreateFromIconResource(cAboutBitmapSize);
  end;
  result := FAboutBitmap;
end;

function TMagician.GetDescription: string;
begin
  Result := SDescription + sLineBreak + sLineBreak + cCopyRight;
end;

function TMagician.GetSplashBitmap: TBitmap;
begin
  if FSplashBitmap = nil then begin
    FSplashBitmap := CreateFromIconResource(cSplashBitmapSize);
  end;
  result := FSplashBitmap;
end;

function TMagician.GetTitle: string;
begin
  Result := cTitle + ' ' + Version;
end;

function TMagician.GetVersion: string;
begin
  if FVersion = '' then begin
    FVersion := TTools.AppVersion;
  end;
  Result := FVersion;
end;

procedure TMagician.RemoveMenuItem;
begin
  dmCodeCoverage.RemoveMenuItems;
  dmCodeCoverage.RemoveActions;
end;

procedure TMagician.RemoveToolButtons;
const
  { IDE's Toolbar names }
  cToolBarNames: array of string = [sCustomToolBar, sStandardToolBar, sDebugToolBar, sViewToolBar, sDesktopToolBar,
    sInternetToolBar, sCORBAToolBar, sAlignToolbar, sBrowserToolbar, sHTMLDesignToolbar, sHTMLFormatToolbar,
    sHTMLTableToolbar, sPersonalityToolBar, sPositionToolbar, sSpacingToolbar, sIDEInsightToolbar,
    sPlatformDeviceToolbar];
var
  S: string;
  tlb: TToolBar;
begin
  tlb := NTA.Services.ToolBar[cCodeCoverageToolbar];
  if tlb <> nil then begin
    RemoveToolButtons(tlb);
    tlb.Visible := (tlb.ButtonCount > 0);
  end;

  for S in cToolBarNames do begin
    RemoveToolButtons(NTA.Services.ToolBar[S]);
  end;
end;

procedure TMagician.RemoveToolButtons(ToolBar: TToolBar);
var
  I: Integer;
  Btn: TToolButton;
begin
  if ToolBar = nil then Exit;

  for I := ToolBar.ButtonCount - 1 downto 0 do begin
    Btn := ToolBar.Buttons[I];
    { someone could have just created a new button from our actions in the customize dialog }
    if dmCodeCoverage.IsMyAction(Btn.Action) then begin
      Btn.ToolBar := nil;
      Btn.Free;
    end;
  end;
end;

procedure Register;
begin
  TMagician.CreateInstance;
end;

initialization
finalization
  TMagician.DestroyInstance;
end.

