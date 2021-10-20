unit CodeCoverage.Notifier;

interface

uses
  System.Types, System.Classes,
  Vcl.Graphics,
  CodeCoverage.ApiHelper, CodeCoverage.Types,
  ToolsAPI, DockForm;

type
  ICodeCoverage = interface
  ['{BCF35C6D-C396-4A3E-8237-D5B99328D72D}']
    function CheckFullRepaint(const EditView: IOTAEditView): Boolean;
    procedure CreateEditViewNotifier(const View: IOTAEditView);
    procedure DrawImage(ACanvas: TCanvas; X, Y, Index: Integer);
    procedure EnableCodeCoverage(const AProcess: IOTAProcess);
    function FindCoveredLinesList(const EditView: IOTAEditView): TCoveredLinesList;
    function FindCoveredMethodList(const EditView: IOTAEditView): TCoveredMethodList;
    function GetImageIndexCodeCoverage: Integer;
    function GetImageIndexNoCoverage: Integer;
    function GetValid: Boolean;
    procedure MarkModified(const EditView: IOTAEditView);
    function MethodIdByLineNumber(const EditBuffer: IOTAEditBuffer; Line: Integer; out AID: TMethodID): Boolean;
    procedure ModuleRenamed(const OldName, NewName: string);
    procedure RemoveEditor(const Editor: IOTASourceEditor);
    procedure RetrieveResults;
    function SwitchCodeCoverage: Boolean;
    procedure TrackedLineChanged(const Tracker: IOTAEditLineTracker; OldLine, NewLine, Data: Integer);
    procedure UpdateCurrentMethodState;
    property ImageIndexCodeCoverage: Integer read GetImageIndexCodeCoverage;
    property ImageIndexNoCoverage: Integer read GetImageIndexNoCoverage;
    property Valid: Boolean read GetValid;
  end;

type
  TCodeCoverageNotifier = class(THostedNotifier)
  private
    FCodeCoverage: ICodeCoverage;
  protected
    procedure CheckNotifierHost(ANotifierHost: TNotifierHost); override;
    property CodeCoverage: ICodeCoverage read FCodeCoverage;
  public
    constructor Create(ANotifierHost: TNotifierHost);
  end;

  TCodeCoverageNotifier<T> = class(TCodeCoverageNotifier)
  private
    FTarget: T;
  public
    constructor Create(AParentInstance: TNotifierHost; const ATarget: T);
    function HandlesTarget(const ATarget: T): Boolean; virtual; abstract;
    property Target: T read FTarget write FTarget;
  end;

type
  TDebuggerNotifier = class(TCodeCoverageNotifier, IOTADebuggerNotifier, IOTADebuggerNotifier90)
  protected
    function DoRegister: Integer; override;
    procedure DoUnregister(ID: Integer); override;
  public
    function BeforeProgramLaunch(const Project: IOTAProject): Boolean;
    procedure BreakpointAdded(const Breakpoint: IOTABreakpoint);
    procedure BreakpointChanged(const Breakpoint: IOTABreakpoint);
    procedure BreakpointDeleted(const Breakpoint: IOTABreakpoint);
    procedure CurrentProcessChanged(const Process: IOTAProcess);
    procedure ProcessCreated(const Process: IOTAProcess);
    procedure ProcessDestroyed(const Process: IOTAProcess);
    procedure ProcessMemoryChanged;
    procedure ProcessStateChanged(const Process: IOTAProcess);
  end;

type
  TEditLineNotifier = class(TCodeCoverageNotifier<IOTAEditLineTracker>, IOTAEditLineNotifier)
  private
    FNextID: Integer;
  protected
    function DoRegister: Integer; override;
    procedure DoUnregister(ID: Integer); override;
    procedure InternalDestroyed; override;
  public
    function HandlesTarget(const ATarget: IOTAEditLineTracker): Boolean; override;
    procedure LineChanged(OldLine: Integer; NewLine: Integer; Data: Integer);
    function NextID: Integer;
  end;

type
  TEditorNotifier = class(TCodeCoverageNotifier<IOTASourceEditor>, IOTAEditorNotifier)
  private
  protected
    function DoRegister: Integer; override;
    procedure DoUnregister(ID: Integer); override;
    procedure InternalDestroyed; override;
  public
    function HandlesTarget(const ATarget: IOTASourceEditor): Boolean; override;
    procedure ViewActivated(const View: IOTAEditView);
    procedure ViewNotification(const View: IOTAEditView; Operation: TOperation);
  end;

type
  TEditServicesNotifier = class(TCodeCoverageNotifier, INTAEditServicesNotifier)
  protected
    function DoRegister: Integer; override;
    procedure DoUnregister(ID: Integer); override;
  public
    procedure DockFormRefresh(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
    procedure DockFormUpdated(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
    procedure DockFormVisibleChanged(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
    procedure EditorViewActivated(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
    procedure EditorViewModified(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
    procedure WindowActivated(const EditWindow: INTAEditWindow);
    procedure WindowCommand(const EditWindow: INTAEditWindow; Command: Integer; Param: Integer; var Handled: Boolean);
    procedure WindowNotification(const EditWindow: INTAEditWindow; Operation: TOperation);
    procedure WindowShow(const EditWindow: INTAEditWindow; Show: Boolean; LoadedFromDesktop: Boolean);
  end;

type
  TEditViewNotifier = class(TCodeCoverageNotifier<IOTAEditView>, INTAEditViewNotifier)
  private
    FCoveredLinesList: TCoveredLinesList;
    FCoveredMethodList: TCoveredMethodList;
  protected
    function DoRegister: Integer; override;
    procedure DoUnregister(ID: Integer); override;
  public
    procedure BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);
    procedure EditorIdle(const View: IOTAEditView);
    procedure EndPaint(const View: IOTAEditView);
    function HandlesTarget(const ATarget: IOTAEditView): Boolean; override;
    procedure PaintLine(const View: IOTAEditView; LineNumber: Integer; const LineText: PAnsiChar; const TextWidth: Word;
      const LineAttributes: TOTAAttributeArray; const Canvas: TCanvas; const TextRect: TRect; const LineRect: TRect;
      const CellSize: TSize);
    property CoveredLinesList: TCoveredLinesList read FCoveredLinesList;
    property CoveredMethodList: TCoveredMethodList read FCoveredMethodList;
  end;

type
  TModuleNotifier = class(TCodeCoverageNotifier<IOTAModule>, IOTAModuleNotifier)
  private
    FFileName: string;
  protected
    function DoRegister: Integer; override;
    procedure DoUnregister(ID: Integer); override;
  public
    function CheckOverwrite: Boolean;
    function HandlesTarget(const ATarget: IOTAModule): Boolean; override;
    procedure ModuleRenamed(const NewName: string);
    property FileName: string read FFileName write FFileName;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, System.Math;

type
  TCanvasState = class
  private
    FBrush: TBrushRecall;
    FFont: TFontRecall;
    FPen: TPenRecall;
  public
    constructor Create(ACanvas: TCanvas);
    destructor Destroy; override;
  end;

procedure TCodeCoverageNotifier.CheckNotifierHost(ANotifierHost: TNotifierHost);
begin
  inherited;
  if not Supports(ANotifierHost, ICodeCoverage) then
    raise EProgrammerNotFound.Create('NotifierHost must support ICodeCoverage!');
end;

constructor TCodeCoverageNotifier.Create(ANotifierHost: TNotifierHost);
begin
  inherited Create(ANotifierHost);
  { We know that this will succeed }
  FCodeCoverage := NotifierHost as ICodeCoverage;
end;

function TDebuggerNotifier.BeforeProgramLaunch(const Project: IOTAProject): Boolean;
begin
  Result := True;
end;

procedure TDebuggerNotifier.BreakpointAdded(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TDebuggerNotifier.BreakpointChanged(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TDebuggerNotifier.BreakpointDeleted(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TDebuggerNotifier.CurrentProcessChanged(const Process: IOTAProcess);
begin
end;

function TDebuggerNotifier.DoRegister: Integer;
begin
  Result := OTA.DebuggerServices.AddNotifier(Self);
end;

procedure TDebuggerNotifier.DoUnregister(ID: Integer);
begin
  OTA.DebuggerServices.RemoveNotifier(ID);
  inherited;
end;

procedure TDebuggerNotifier.ProcessCreated(const Process: IOTAProcess);
begin
end;

procedure TDebuggerNotifier.ProcessDestroyed(const Process: IOTAProcess);
begin
end;

procedure TDebuggerNotifier.ProcessMemoryChanged;
begin
end;

procedure TDebuggerNotifier.ProcessStateChanged(const Process: IOTAProcess);
begin
  case Process.ProcessState of
    psNothing: ;
    psRunning: CodeCoverage.EnableCodeCoverage(Process);
    psStopping: ;
    psStopped: ;
    psFault: ;
    psResFault: ;
    psTerminated: CodeCoverage.RetrieveResults;
    psException: ;
    psNoProcess: ;
  end;
end;

function TEditLineNotifier.DoRegister: Integer;
begin
  Result := inherited DoRegister;
  if Target <> nil then begin
    Result := Target.AddNotifier(Self);
  end;
end;

procedure TEditLineNotifier.DoUnregister(ID: Integer);
begin
  if Target <> nil then begin
    Target.RemoveNotifier(ID);
  end;
  inherited;
end;

function TEditLineNotifier.HandlesTarget(const ATarget: IOTAEditLineTracker): Boolean;
begin
  Result := (ATarget = Target);
end;

procedure TEditLineNotifier.InternalDestroyed;
var
  I: Integer;
begin
  for I := Target.Count - 1 downto 0 do begin
    Target.Delete(I);
  end;
  inherited;
end;

procedure TEditLineNotifier.LineChanged(OldLine, NewLine, Data: Integer);
begin
  CodeCoverage.TrackedLineChanged(Target, OldLine, NewLine, Data);
end;

function TEditLineNotifier.NextID: Integer;
begin
  if Target.Count = 0 then begin
    FNextID := 0;
  end;
  Result := FNextID;
  Inc(FNextID);
end;

function TEditorNotifier.DoRegister: Integer;
begin
  Result := inherited DoRegister;
  if Target <> nil then begin
    Result := Target.AddNotifier(Self);
  end;
end;

procedure TEditorNotifier.DoUnregister(ID: Integer);
begin
  if Target <> nil then begin
    Target.RemoveNotifier(ID);
  end;
  inherited;
end;

function TEditorNotifier.HandlesTarget(const ATarget: IOTASourceEditor): Boolean;
begin
  Result := (ATarget.FileName = Target.FileName);
end;

procedure TEditorNotifier.InternalDestroyed;
begin
  if Target <> nil then begin
    CodeCoverage.RemoveEditor(Target);
  end;
  inherited;
end;

procedure TEditorNotifier.ViewActivated(const View: IOTAEditView);
begin
end;

procedure TEditorNotifier.ViewNotification(const View: IOTAEditView; Operation: TOperation);
begin
  case Operation of
    opInsert: CodeCoverage.CreateEditViewNotifier(View);
    opRemove: ;
  end;
end;

procedure TEditServicesNotifier.DockFormRefresh(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin
end;

procedure TEditServicesNotifier.DockFormUpdated(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin
end;

procedure TEditServicesNotifier.DockFormVisibleChanged(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin
end;

function TEditServicesNotifier.DoRegister: Integer;
begin
  Result := OTA.EditorServices.AddNotifier(Self);
end;

procedure TEditServicesNotifier.DoUnregister(ID: Integer);
begin
  OTA.EditorServices.RemoveNotifier(ID);
  inherited;
end;

procedure TEditServicesNotifier.EditorViewActivated(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
begin
  CodeCoverage.CreateEditViewNotifier(EditView);
  CodeCoverage.UpdateCurrentMethodState;
end;

procedure TEditServicesNotifier.EditorViewModified(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
begin
  CodeCoverage.MarkModified(EditView);
end;

procedure TEditServicesNotifier.WindowActivated(const EditWindow: INTAEditWindow);
begin
end;

procedure TEditServicesNotifier.WindowCommand(const EditWindow: INTAEditWindow; Command, Param: Integer;
  var Handled: Boolean);
begin
end;

procedure TEditServicesNotifier.WindowNotification(const EditWindow: INTAEditWindow; Operation: TOperation);
begin
end;

procedure TEditServicesNotifier.WindowShow(const EditWindow: INTAEditWindow; Show, LoadedFromDesktop: Boolean);
begin
end;

procedure TEditViewNotifier.BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);
begin
  if CodeCoverage.CheckFullRepaint(View) then begin
    FullRepaint := True;
  end;

  FCoveredMethodList := CodeCoverage.FindCoveredMethodList(View);

  if CodeCoverage.Valid then begin
    FCoveredLinesList := CodeCoverage.FindCoveredLinesList(View);
  end
  else begin
    FCoveredLinesList := nil;
  end;
end;

function TEditViewNotifier.DoRegister: Integer;
begin
  Result := inherited DoRegister;
  if Target <> nil then begin
    Result := Target.AddNotifier(Self);
  end;
end;

procedure TEditViewNotifier.DoUnregister(ID: Integer);
begin
  if Target <> nil then begin
    Target.RemoveNotifier(ID);
    Target := nil;
  end;
  inherited;
end;

procedure TEditViewNotifier.EditorIdle(const View: IOTAEditView);
begin
  if View.SameView(OTA.EditorServices.TopView) then begin
    CodeCoverage.UpdateCurrentMethodState;
  end;
end;

procedure TEditViewNotifier.EndPaint(const View: IOTAEditView);
begin
  FCoveredMethodList := nil;
  FCoveredLinesList := nil;
end;

function TEditViewNotifier.HandlesTarget(const ATarget: IOTAEditView): Boolean;
begin
  Result := ATarget.SameView(Target);
end;

procedure TEditViewNotifier.PaintLine(const View: IOTAEditView; LineNumber: Integer; const LineText: PAnsiChar;
  const TextWidth: Word; const LineAttributes: TOTAAttributeArray; const Canvas: TCanvas; const TextRect,
  LineRect: TRect; const CellSize: TSize);
var
  coveredMethod: TCoveredMethod;
  gutterPos: TPoint;
  PassCount: THitCount;
  S: string;
  canvasState: TCanvasState;
  afterText: TPoint;
  beforeText: TPoint;
  curID: TMethodID;
begin
  canvasState := TCanvasState.Create(Canvas);
  try
    gutterPos := TPoint.Create(LineRect.TopLeft);
    afterText := TPoint.Create(TextRect.Right + CellSize.cx, LineRect.Top);
    beforeText := TPoint.Create(TextRect.Left, LineRect.Top);

    if CoveredMethodList <> nil then begin
      if CodeCoverage.MethodIdByLineNumber(View.Buffer, LineNumber, curID) then begin
        if CoveredMethodList.Find(curID, coveredMethod) then begin
          CodeCoverage.DrawImage(Canvas, gutterPos.X, gutterPos.Y, CodeCoverage.ImageIndexCodeCoverage);
          if CodeCoverage.Valid then begin
            canvas.Brush.Style := bsClear;
            canvas.Font.Color := clLtGray;
            Canvas.TextOut(afterText.X, afterText.Y, Format('[%d%%]', [coveredMethod.Percent]));
          end;
        end;
      end;
    end;

    if CoveredLinesList <> nil then begin
      if CoveredLinesList.TryGetValue(LineNumber, PassCount) then begin
        S := IfThen(PassCount < 0, '○', '●');
        canvas.Brush.Style := bsClear;
        canvas.Font.Color := IfThen(PassCount = 0, clRed, clBlue);
        Canvas.TextOut(beforeText.X, beforeText.Y, S);
        if PassCount = 0 then begin
          CodeCoverage.DrawImage(Canvas, afterText.X, afterText.Y, CodeCoverage.ImageIndexNoCoverage);
        end
        else if PassCount > 0 then begin
          canvas.Font.Color := clLtGray;
          Canvas.TextOut(afterText.X, afterText.Y, Format('[%d]', [PassCount]));
        end;
      end;
    end;

  finally
    canvasState.Free;
  end;
end;

function TModuleNotifier.DoRegister: Integer;
begin
  Result := inherited DoRegister;
  if Target <> nil then begin
    Result := Target.AddNotifier(Self);
    FileName := Target.FileName;
  end;
end;

procedure TModuleNotifier.DoUnregister(ID: Integer);
begin
  if Target <> nil then begin
    Target.RemoveNotifier(ID);
    Target := nil;
  end;
  inherited;
end;

function TModuleNotifier.CheckOverwrite: Boolean;
begin
  Result := True;
end;

function TModuleNotifier.HandlesTarget(const ATarget: IOTAModule): Boolean;
begin
  Result := (ATarget = Target);
end;

procedure TModuleNotifier.ModuleRenamed(const NewName: string);
begin
  if FileName <> NewName then begin
    CodeCoverage.ModuleRenamed(FileName, NewName);
    FileName := NewName;
  end;
end;

constructor TCodeCoverageNotifier<T>.Create(AParentInstance: TNotifierHost; const ATarget: T);
begin
  inherited Create(AParentInstance);
  FTarget := ATarget;
end;

constructor TCanvasState.Create(ACanvas: TCanvas);
begin
  inherited Create;
  FPen := TPenRecall.Create(ACanvas.Pen);
  FFont := TFontRecall.Create(ACanvas.Font);
  FBrush := TBrushRecall.Create(ACanvas.Brush);
end;

destructor TCanvasState.Destroy;
begin
  FBrush.Free;
  FFont.Free;
  FPen.Free;
  inherited;
end;

end.
