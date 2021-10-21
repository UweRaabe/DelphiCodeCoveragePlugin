unit CodeCoverage.DM;

interface

uses
  System.Classes, System.Actions, System.Contnrs,
  Vcl.Graphics, Vcl.Menus, Vcl.ActnList, Vcl.ImgList,
  CodeCoverage.Handler;

type
  TdmCodeCoverage = class(TDataModule)
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
    procedure SetCodeCoverage(const Value: TCodeCoverage);
  strict protected
    procedure ExecuteRunCodeCoverage;
    procedure ExecuteSwitchCodeCoverage;
    procedure UpdateRunCodeCoverage;
    procedure UpdateSwitchCodeCoverage;
  protected
    function GetImageList: TCustomImageList;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    function FindImageIndexByName(const AImageName: string): Integer;
    function IsMyAction(Action: TBasicAction): Boolean;
    procedure RemoveActions;
    procedure RemoveMenuItems;
    property CodeCoverage: TCodeCoverage read FCodeCoverage write SetCodeCoverage;
    property ImageIndexOffset: Integer read FImageIndexOffset write FImageIndexOffset;
    property ImageList: TCustomImageList read GetImageList;
  end;

var
  dmCodeCoverage: TdmCodeCoverage;

implementation

uses
  CodeCoverage.Images.DM;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

constructor TdmCodeCoverage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActions := TComponentList.Create(False);
  FMenuItems := TComponentList.Create(False);
  RememberActions;
  RememberMenuItems;
end;

constructor TdmCodeCoverage.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  { avoids the datamodule being added to Screen.Datamodules }
//  Dummy := -1;
  inherited;
end;

destructor TdmCodeCoverage.Destroy;
begin
  FMenuItems.Free;
  FActions.Free;
  inherited Destroy;
end;

procedure TdmCodeCoverage.actRunCodeCoverageExecute(Sender: TObject);
begin
  ExecuteRunCodeCoverage;
end;

procedure TdmCodeCoverage.actRunCodeCoverageUpdate(Sender: TObject);
begin
  UpdateRunCodeCoverage;
end;

procedure TdmCodeCoverage.actSwitchCodeCoverageExecute(Sender: TObject);
begin
  ExecuteSwitchCodeCoverage;
end;

procedure TdmCodeCoverage.actSwitchCodeCoverageUpdate(Sender: TObject);
begin
  UpdateSwitchCodeCoverage;
end;

function TdmCodeCoverage.IsMyAction(Action: TBasicAction): Boolean;
begin
  Result := (FActions.IndexOf(Action) >= 0);
end;

procedure TdmCodeCoverage.RememberActions;
var
  item: TContainedAction;
begin
  for item in Actions do begin
    item.Tag := item.ImageIndex;
    FActions.Add(item);
  end;
end;

procedure TdmCodeCoverage.RememberMenuItems;
var
  item: TMenuItem;
begin
  for item in MenuItems.Items do begin
    FMenuItems.Add(item);
  end;
end;

procedure TdmCodeCoverage.RemoveActions;
var
  I: Integer;
begin
  for I := FActions.Count - 1 downto 0 do begin
    FActions[I].Free;
  end;
end;

procedure TdmCodeCoverage.RemoveMenuItems;
var
  I: Integer;
begin
  for I := FMenuItems.Count - 1 downto 0 do begin
    FMenuItems[I].Free;
  end;
end;

procedure TdmCodeCoverage.UpdateSwitchCodeCoverage;
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

procedure TdmCodeCoverage.UpdateRunCodeCoverage;
var
  enabled: Boolean;
begin
  enabled := False;
  if CodeCoverage <> nil then begin
    enabled := CodeCoverage.HasCodeCoverage;
  end;
  actRunCodeCoverage.Enabled := enabled;
end;

procedure TdmCodeCoverage.ExecuteRunCodeCoverage;
begin
  if CodeCoverage <> nil then begin
    CodeCoverage.Execute;
  end;
end;

procedure TdmCodeCoverage.ExecuteSwitchCodeCoverage;
begin
  if CodeCoverage <> nil then begin
    CodeCoverage.SwitchCodeCoverage;
    UpdateSwitchCodeCoverage;
  end;
end;

function TdmCodeCoverage.FindImageIndexByName(const AImageName: string): Integer;
begin
  Result := dmCodeCoverageImages.FindImageIndexByName(AImageName);
end;

function TdmCodeCoverage.GetImageList: TCustomImageList;
begin
  Result := Actions.Images;
end;

procedure TdmCodeCoverage.SetCodeCoverage(const Value: TCodeCoverage);
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
