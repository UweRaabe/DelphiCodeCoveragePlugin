unit CodeCoverage.Base.DM;

interface

uses
  System.Classes, System.Actions, System.Contnrs,
  Vcl.Graphics, Vcl.Menus, Vcl.ActnList, Vcl.ImgList,
  CodeCoverage.Handler;

type
  TdmCodeCoverageBase = class(TDataModule)
    Actions: TActionList;
    actSwitchCodeCoverage: TAction;
    actRunCodeCoverage: TAction;
    MenuItems: TPopupMenu;
    mnuRunCodeCoverage: TMenuItem;
    procedure actRunCodeCoverageExecute(Sender: TObject);
    procedure actRunCodeCoverageUpdate(Sender: TObject);
    procedure actSwitchCodeCoverageExecute(Sender: TObject);
    procedure actSwitchCodeCoverageUpdate(Sender: TObject);
  private
    FCodeCoverage: TCodeCoverage;
    FActions: TComponentList;
    FImageIndexOffset: Integer;
    FMenuItems: TComponentList;
    procedure RememberActions;
    procedure RememberMenuItems;
    procedure CheckCurrentMethodState;
    procedure CheckHasCodeCoverage;
    procedure SetCodeCoverage(const Value: TCodeCoverage);
  strict protected
    function FindImageIndexByName(const AImageName: string): Integer; virtual; abstract;
  protected
    function GetImageList: TCustomImageList; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    function IsMyAction(Action: TBasicAction): Boolean;
    procedure RemoveActions;
    procedure RemoveMenuItems;
    property CodeCoverage: TCodeCoverage read FCodeCoverage write SetCodeCoverage;
    property ImageIndexOffset: Integer read FImageIndexOffset write FImageIndexOffset;
    property ImageList: TCustomImageList read GetImageList;
  end;

var
  dmCodeCoverageBase: TdmCodeCoverageBase;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

constructor TdmCodeCoverageBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActions := TComponentList.Create(False);
  FMenuItems := TComponentList.Create(False);
  RememberActions;
  RememberMenuItems;
end;

constructor TdmCodeCoverageBase.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  { avoids the datamodule being added to Screen.Datamodules }
  Dummy := -1;
  inherited;
end;

destructor TdmCodeCoverageBase.Destroy;
begin
  FMenuItems.Free;
  FActions.Free;
  inherited Destroy;
end;

procedure TdmCodeCoverageBase.actRunCodeCoverageExecute(Sender: TObject);
begin
  if CodeCoverage <> nil then begin
    CodeCoverage.Execute;
  end;
end;

procedure TdmCodeCoverageBase.actRunCodeCoverageUpdate(Sender: TObject);
begin
  CheckHasCodeCoverage;
end;

procedure TdmCodeCoverageBase.actSwitchCodeCoverageExecute(Sender: TObject);
begin
  if CodeCoverage <> nil then begin
    CodeCoverage.SwitchCodeCoverage;
    CheckCurrentMethodState;
  end;
end;

procedure TdmCodeCoverageBase.actSwitchCodeCoverageUpdate(Sender: TObject);
begin
  CheckCurrentMethodState;
end;

function TdmCodeCoverageBase.IsMyAction(Action: TBasicAction): Boolean;
begin
  Result := (FActions.IndexOf(Action) >= 0);
end;

procedure TdmCodeCoverageBase.RememberActions;
var
  item: TContainedAction;
begin
  for item in Actions do begin
    item.Tag := item.ImageIndex;
    FActions.Add(item);
  end;
end;

procedure TdmCodeCoverageBase.RememberMenuItems;
var
  item: TMenuItem;
begin
  for item in MenuItems.Items do begin
    FMenuItems.Add(item);
  end;
end;

procedure TdmCodeCoverageBase.RemoveActions;
var
  I: Integer;
begin
  for I := FActions.Count - 1 downto 0 do begin
    FActions[I].Free;
  end;
end;

procedure TdmCodeCoverageBase.RemoveMenuItems;
var
  I: Integer;
begin
  for I := FMenuItems.Count - 1 downto 0 do begin
    FMenuItems[I].Free;
  end;
end;

procedure TdmCodeCoverageBase.CheckCurrentMethodState;
var
  state: TCoverState;
begin
  state := TCoverState.noncoverable;
  if CodeCoverage <> nil then begin
    if CodeCoverage.IsAvailable then begin
      state := CodeCoverage.CurrentMethodState;
    end;
  end;
  actSwitchCodeCoverage.Enabled := (state > TCoverState.noncoverable);
  actSwitchCodeCoverage.Checked := (state = TCoverState.covered);
end;

procedure TdmCodeCoverageBase.CheckHasCodeCoverage;
var
  enabled: Boolean;
begin
  enabled := False;
  if CodeCoverage <> nil then begin
    enabled := CodeCoverage.HasCodeCoverage;
  end;
  actRunCodeCoverage.Enabled := enabled;
end;

procedure TdmCodeCoverageBase.SetCodeCoverage(const Value: TCodeCoverage);
begin
  if FCodeCoverage <> Value then
  begin
    FCodeCoverage := Value;
    if FCodeCoverage <> nil then begin
      FCodeCoverage.ImageList := ImageList;
      FCodeCoverage.ImageIndexCodeCoverage := FindImageIndexByName('CodeCoverage'); // do not localize
      FCodeCoverage.ImageIndexNoCoverage := FindImageIndexByName('NoCoverage'); // do not localize
    end;
  end;
end;

end.
