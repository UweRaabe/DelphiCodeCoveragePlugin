unit CodeCoverage.Handler;

interface

uses
  ToolsAPI,
  System.Classes,
  Vcl.Menus, Vcl.Graphics, Vcl.ImgList,
  CodeCoverage.ApiHelper, CodeCoverage.Types, CodeCoverage.SyntaxTypes, CodeCoverage.Notifier;

type
{$SCOPEDENUMS ON}
  TCoverState = (noncoverable, coverable, covered);
{$SCOPEDENUMS OFF}

type
  TCodeCoverage = class(TNotifierHost, ICodeCoverage)
  private const
    cBreakpointGroupName = 'CodeCoverage';
  private
    FActive: Boolean;
    FCodeSyntaxTrees: TCodeSyntaxTrees;
    FCoveredLines: TCoveredLines;
    FCoveredMethods: TCoveredMethods;
    FCurFileName: string;
    FCurLineMax: Integer;
    FCurLineMin: Integer;
    FCurProcess: IOTAProcess;
    FCurrentMethodState: TCoverState;
    FFullRepaint: TStringList;
    FImageIndexCodeCoverage: Integer;
    FImageIndexNoCoverage: Integer;
    FImageList: TCustomImageList;
    FRunMenuItem: TMenuItem;
    FValid: Boolean;
    function AddBreakpoint(ALineNumber: Integer): IOTABreakpoint;
    procedure AddCoverage(const AFileName: string; ALineNumber, ACount: Integer);
    function AddLineTracker(const EditBuffer: IOTAEditBuffer; ALineNumber: Integer): Integer;
    procedure CalcCoverage(const AFileName: string; const Data: TCoveredMethod);
    procedure CheckCodeCoverage;
    function CheckFullRepaint(const EditView: IOTAEditView): Boolean;
    procedure ClearAllCodeCoverage;
    procedure CoverMethod(const AFileName: string; const Data: TCoveredMethod);
    function CreateEditLineNotifier(const Tracker: IOTAEditLineTracker): Integer;
    procedure CreateEditorNotifier(const Editor: IOTASourceEditor);
    procedure CreateEditViewNotifier(const View: IOTAEditView);
    procedure CreateModuleNotifier(const Module: IOTAModule);
    function CreateSyntaxTree(const Editor: IOTASourceEditor): TCodeSyntaxTree;
    procedure DrawImage(ACanvas: TCanvas; X, Y, Index: Integer);
    procedure EnableCodeCoverage(const AProcess: IOTAProcess);
    function FindCoveredLinesList(const EditView: IOTAEditView): TCoveredLinesList;
    function FindCoveredMethodList(const EditView: IOTAEditView): TCoveredMethodList;
    function FindEditLineNotifier(const Tracker: IOTAEditLineTracker): TEditLineNotifier;
    function FindMethod(const EditBuffer: IOTAEditBuffer; Line: Integer; out Data: TCoveredMethod): Boolean;
    function FindSourceEditor(const AFileName: string): IOTASourceEditor;
    function FindSyntaxTree(const AFileName: string): TCodeSyntaxTree; overload;
    function FindSyntaxTree(const Editor: IOTASourceEditor): TCodeSyntaxTree; overload;
    function GetHasCodeCoverage: Boolean;
    function GetImageIndexCodeCoverage: Integer;
    function GetImageIndexNoCoverage: Integer;
    function GetValid: Boolean;
    function HandleSourceLine(ALineNumber: Integer): Boolean;
    function HasNotifier<T>(const Target: T): Boolean; overload;
    procedure MarkFullRepaint(const AFileName: string);
    procedure MarkModified(const EditView: IOTAEditView);
    function MethodIdByLineNumber(const EditBuffer: IOTAEditBuffer; Line: Integer; out AID: TMethodID): Boolean;
    procedure ModuleRenamed(const OldName: string; const NewName: string);
    procedure RemoveEditLineNotifier(const Tracker: IOTAEditLineTracker);
    procedure RemoveEditor(const Editor: IOTASourceEditor);
    procedure RemoveLineTracker(const EditBuffer: IOTAEditBuffer); overload;
    procedure RemoveLineTracker(const EditBuffer: IOTAEditBuffer; ALineNumber, AID: Integer); overload;
    procedure RetrieveResults;
    function SelectCurrentMethod(const EditBuffer: IOTAEditBuffer; out AFileName, AMethodName: string; out LineMin,
        LineMax: Integer): Boolean; overload;
    function SelectMethod(const AFileName: string; const AMethod: TCoveredMethod;
      out LineMin, LineMax: Integer): Boolean;
    procedure TrackedLineChanged(const Tracker: IOTAEditLineTracker; OldLine, NewLine, Data: Integer);
    procedure UpdateCurrentMethodState;
  protected
    property Active: Boolean read FActive write FActive;
    property CodeSyntaxTrees: TCodeSyntaxTrees read FCodeSyntaxTrees;
    property CoveredLines: TCoveredLines read FCoveredLines;
    property CoveredMethods: TCoveredMethods read FCoveredMethods;
    property CurFileName: string read FCurFileName write FCurFileName;
    property CurLineMax: Integer read FCurLineMax write FCurLineMax;
    property CurLineMin: Integer read FCurLineMin write FCurLineMin;
    property CurProcess: IOTAProcess read FCurProcess write FCurProcess;
    property FullRepaint: TStringList read FFullRepaint;
    property Valid: Boolean read GetValid write FValid;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Execute;
    procedure Initialize;
    function IsAvailable: Boolean;
    function SwitchCodeCoverage: Boolean;
    property CurrentMethodState: TCoverState read FCurrentMethodState;
    property HasCodeCoverage: Boolean read GetHasCodeCoverage;
    property ImageIndexCodeCoverage: Integer read GetImageIndexCodeCoverage write FImageIndexCodeCoverage;
    property ImageIndexNoCoverage: Integer read GetImageIndexNoCoverage write FImageIndexNoCoverage;
    property ImageList: TCustomImageList read FImageList write FImageList;
    property RunMenuItem: TMenuItem read FRunMenuItem write FRunMenuItem;
  end;

implementation

uses
  System.Math, System.StrUtils, System.Types, System.SysUtils,
  Vcl.Dialogs;

function GetSourceLines(LineNum: Integer; ClientArg: Pointer): Integer pascal;
begin
  Result := 0;
  if TCodeCoverage(ClientArg).HandleSourceLine(LineNum) then begin
    Result := 1;
  end;
end;

constructor TCodeCoverage.Create;
begin
  inherited Create;
  FCoveredLines := TCoveredLines.Create();
  FCoveredMethods := TCoveredMethods.Create();
  FCodeSyntaxTrees := TCodeSyntaxTrees.Create();

  FFullRepaint := TStringList.Create(dupIgnore, true, false);

  TDebuggerNotifier.Create(Self);
  TEditServicesNotifier.Create(Self);

  CreateEditViewNotifier(OTA.EditorServices.TopView);
end;

destructor TCodeCoverage.Destroy;
begin
  FFullRepaint.Free;
  FCodeSyntaxTrees.Free;
  FCoveredMethods.Free;
  FCoveredLines.Free;
  inherited;
end;

procedure TCodeCoverage.DrawImage(ACanvas: TCanvas; X, Y, Index: Integer);
begin
  ImageList.Draw(ACanvas, X, Y, Index);
end;

function TCodeCoverage.AddBreakpoint(ALineNumber: Integer): IOTABreakpoint;
begin
  Result := OTA.DebuggerServices.NewSourceBreakpoint(CurFileName, ALineNumber, CurProcess);
  if Result <> nil then begin
    Result.DoBreak := false;
    Result.GroupName := cBreakpointGroupName;
    if ALineNumber = CurLineMin then begin
      Result.DoIgnoreExceptions := True;
    end
    else if ALineNumber = CurLineMax then begin
      Result.DoHandleExceptions := True;
    end
    else begin
      Result.PassCount := MaxInt;
      CoveredLines.Initialize(CurFileName, ALineNumber, 0);
    end;
  end;
end;

procedure TCodeCoverage.AddCoverage(const AFileName: string; ALineNumber, ACount: Integer);
begin
  CoveredLines.Add(AFileName, ALineNumber, ACount);
end;

function TCodeCoverage.AddLineTracker(const EditBuffer: IOTAEditBuffer; ALineNumber: Integer): Integer;
var
  Tracker: IOTAEditLineTracker;
begin
  Tracker := EditBuffer.GetEditLineTracker;
  Result := CreateEditLineNotifier(Tracker);
  Tracker.AddLine(ALineNumber, Result);
end;

procedure TCodeCoverage.CalcCoverage(const AFileName: string; const Data: TCoveredMethod);
var
  Count: Integer;
  covered: Integer;
  I: Integer;
  percent: Integer;
  total: Integer;
begin
  total := 0;
  covered := 0;
  for I := Data.LineMin to Data.LineMax do begin
    Count := CoveredLines.Find(AFileName, I);
    if Count >= 0 then begin
      Inc(total);
      if Count > 0 then begin
        Inc(covered);
      end;
    end;
  end;
  if total = covered then begin
    percent := 100;
  end
  else if covered = 0 then begin
    percent := 0;
  end
  else begin
    percent := EnsureRange(Round(100*covered/total), 1, 99);
  end;
  CoveredMethods.UpdatePercent(AFileName, Data.ID, percent);
end;

procedure TCodeCoverage.CheckCodeCoverage;
var
  bp: IOTABreakpoint;
  I: Integer;
begin
  for I := 0 to OTA.DebuggerServices.SourceBkptCount - 1 do begin
    bp := OTA.DebuggerServices.SourceBkpts[I];
    if MatchStr(bp.GroupName, [cBreakpointGroupName]) then begin
      if not (bp.DoHandleExceptions or bp.DoIgnoreExceptions) then begin
        AddCoverage(bp.FileName, bp.LineNumber, bp.CurPassCount);
      end;
    end;
  end;
  CoveredMethods.Iterate(CalcCoverage);

  Valid := true;
end;

function TCodeCoverage.CheckFullRepaint(const EditView: IOTAEditView): Boolean;
var
  idx: Integer;
begin
  Result := FullRepaint.Find(EditView.Buffer.FileName, idx);
  if Result then begin
    FullRepaint.Delete(idx);
  end;
end;

procedure TCodeCoverage.ClearAllCodeCoverage;
var
  bp: IOTABreakpoint;
  I: Integer;
begin
  for I := OTA.DebuggerServices.SourceBkptCount - 1 downto 0 do begin
    bp := OTA.DebuggerServices.SourceBkpts[I];
    if bp.GroupName = cBreakpointGroupName then begin
      OTA.DebuggerServices.RemoveBreakpoint(bp);
    end;
  end;

  FCurProcess := nil;
end;

procedure TCodeCoverage.CoverMethod(const AFileName: string; const Data: TCoveredMethod);
var
  I: Integer;
begin
  if CurProcess.SourceIsDebuggable[AFileName] then begin
    if SelectMethod(AFileName, Data, FCurLineMin, FCurLineMax) then begin
      CoveredMethods.Update(AFileName, Data.ID, FCurLineMin + 1, FCurLineMax - 1);
      FCurFileName := AFileName;
      for I := FCurLineMin + 1 to FCurLineMax - 1 do begin
        CoveredLines.Initialize(FCurFileName, I, -1);
      end;
      CurProcess.GetSourceLines(FCurFileName, FCurLineMin, GetSourceLines, Self);
    end;
  end;
end;

function TCodeCoverage.CreateEditLineNotifier(const Tracker: IOTAEditLineTracker): Integer;
var
  instance: TEditLineNotifier;
begin
  if Tracker = nil then
    Exit(-1);

  { check if Tracker already has a notifier }
  instance := FindEditLineNotifier(Tracker);
  if instance = nil then begin
    instance := TEditLineNotifier.Create(Self, Tracker);
  end;
  Result := instance.NextID;
end;

procedure TCodeCoverage.CreateEditorNotifier(const Editor: IOTASourceEditor);
begin
  if not HasNotifier(Editor) then begin
    TEditorNotifier.Create(Self, Editor);
  end;
end;

procedure TCodeCoverage.CreateEditViewNotifier(const View: IOTAEditView);
begin
  if not HasNotifier(View) then begin
    TEditViewNotifier.Create(Self, View);
  end;
end;

procedure TCodeCoverage.CreateModuleNotifier(const Module: IOTAModule);
begin
  if not HasNotifier(Module) then begin
    TModuleNotifier.Create(Self, Module);
  end;
end;

function TCodeCoverage.CreateSyntaxTree(const Editor: IOTASourceEditor): TCodeSyntaxTree;
begin
  Result := CodeSyntaxTrees.Add(Editor);
  if Result <> nil then begin
    CreateEditorNotifier(Editor);
    CreateModuleNotifier(Editor.Module);
  end;
end;

procedure TCodeCoverage.EnableCodeCoverage(const AProcess: IOTAProcess);
begin
  if not Active then
    Exit;

  CoveredLines.Clear;
  Valid := false;
  FCurProcess := AProcess;
  CoveredMethods.Iterate(CoverMethod);
  Active := not CoveredLines.IsEmpty;
end;

procedure TCodeCoverage.Execute;
var
  builder: IOTAProjectBuilder;
  project: IOTAProject;
begin
  project := OTA.ModuleServices.GetActiveProject;
  if project = nil then begin
    ShowMessage('No active project!');
    Exit;
  end;

  ClearAllCodeCoverage;

  builder := project.ProjectBuilder;
  if builder = nil then begin
    ShowMessage('Active project has no project buidler!');
    Exit;
  end;

  if builder.BuildProject(cmOTABuild, false, true) then begin
    //    OTADebuggerServices.CreateProcess(project.ProjectOptions.TargetName, '');
    if (RunMenuItem <> nil) and RunMenuItem.Enabled then begin
      Active := true;
      try
        RunMenuItem.Click;
      except
        Active := false;
      end;
    end;
  end;
end;

function TCodeCoverage.FindCoveredLinesList(const EditView: IOTAEditView): TCoveredLinesList;
begin
  Result := CoveredLines.Find(EditView.Buffer.FileName);
end;

function TCodeCoverage.FindCoveredMethodList(const EditView: IOTAEditView): TCoveredMethodList;
begin
  Result := CoveredMethods.Find(EditView.Buffer.FileName);
end;

function TCodeCoverage.FindEditLineNotifier(const Tracker: IOTAEditLineTracker): TEditLineNotifier;
var
  instance: TEditLineNotifier;
begin
  Result := nil;
  if Tracker = nil then
    Exit;


  if FindNotifier<TEditLineNotifier>(
    function(Arg: TEditLineNotifier): Boolean
    begin
      Result := Arg.HandlesTarget(Tracker);
    end,
    instance) then
  begin
    Result := instance;
  end;
end;

function TCodeCoverage.FindMethod(const EditBuffer: IOTAEditBuffer; Line: Integer; out Data: TCoveredMethod): Boolean;
var
  curID: TMethodID;
begin
  Result := MethodIdByLineNumber(EditBuffer, Line, curID) and CoveredMethods.Find(EditBuffer.FileName, curID, Data);
end;

function TCodeCoverage.FindSourceEditor(const AFileName: string): IOTASourceEditor;
var
  Editor: IOTAEditor;
  I: Integer;
  module: IOTAModule;
  sourceEditor: IOTASourceEditor;
begin
  Result := nil;

  module := OTA.ModuleServices.FindModule(AFileName);
  for I := 0 to module.ModuleFileCount - 1 do begin
    Editor := module.ModuleFileEditors[I];
    if Supports(Editor, IOTASourceEditor, sourceEditor) then begin
      Exit(sourceEditor);
    end;
  end;
end;

function TCodeCoverage.FindSyntaxTree(const AFileName: string): TCodeSyntaxTree;
begin
  if AFileName = '' then
    Exit(nil);

  if not CodeSyntaxTrees.Find(AFileName, Result) then begin
    Result := CreateSyntaxTree(FindSourceEditor(AFileName));
  end;
end;

function TCodeCoverage.FindSyntaxTree(const Editor: IOTASourceEditor): TCodeSyntaxTree;
begin
  if Editor = nil then
    Exit(nil);

  if not CodeSyntaxTrees.Find(Editor.FileName, Result) then begin
    Result := CreateSyntaxTree(Editor);
  end;
end;

function TCodeCoverage.GetHasCodeCoverage: Boolean;
begin
  Result := IsAvailable and not CoveredMethods.IsEmpty;
end;

function TCodeCoverage.GetImageIndexCodeCoverage: Integer;
begin
  Result := FImageIndexCodeCoverage;
end;

function TCodeCoverage.GetImageIndexNoCoverage: Integer;
begin
  Result := FImageIndexNoCoverage;
end;

function TCodeCoverage.GetValid: Boolean;
begin
  Result := FValid;
end;

function TCodeCoverage.HandleSourceLine(ALineNumber: Integer): Boolean;
begin
  Result := false;
  if ALineNumber <= CurLineMax then begin
    AddBreakpoint(ALineNumber);
    Result := true;
  end;
end;

function TCodeCoverage.HasNotifier<T>(const Target: T): Boolean;
begin
  Result := FindNotifier<TCodeCoverageNotifier<T>>(
    function(Arg: TCodeCoverageNotifier<T>): Boolean
    begin
      Result := Arg.HandlesTarget(Target);
    end);
end;

procedure TCodeCoverage.Initialize;
var
  Editor: IOTAEditor;
  I: Integer;
  J: Integer;
  K: Integer;
  module: IOTAModule;
  moduleServices: IOTAModuleServices;
  sourceEditor: IOTASourceEditor;
  view: IOTAEditView;
begin
  moduleServices := OTA.ModuleServices;
  for I := 0 to moduleServices.ModuleCount - 1 do begin
    module := moduleServices.Modules[I];
    for J := 0 to module.ModuleFileCount - 1 do begin
      Editor := module.ModuleFileEditors[J];
      if Supports(Editor, IOTASourceEditor, sourceEditor) then begin
        for K := 0 to sourceEditor.EditViewCount - 1 do begin
          view := sourceEditor.EditViews[K];
          CreateEditViewNotifier(view);
        end;
      end;
    end;
  end;
  UpdateCurrentMethodState;
end;

function TCodeCoverage.IsAvailable: Boolean;
var
  project: IOTAProject;
begin
  Result := False;

  project := OTA.ModuleServices.GetActiveProject;
  if project = nil then
    Exit;
  if not MatchText(project.ApplicationType, [sApplication, sConsole]) then
    Exit;

  Result := true;
end;

procedure TCodeCoverage.MarkFullRepaint(const AFileName: string);
begin
  FullRepaint.Add(AFileName);
end;

procedure TCodeCoverage.MarkModified(const EditView: IOTAEditView);
begin
  CodeSyntaxTrees.Remove(EditView.Buffer.FileName);
end;

function TCodeCoverage.MethodIdByLineNumber(const EditBuffer: IOTAEditBuffer; Line: Integer; out AID: TMethodID):
    Boolean;
var
  idx: Integer;
  Tracker: IOTAEditLineTracker;
begin
  Result := false;
  if EditBuffer = nil then
    Exit;

  Tracker := EditBuffer.GetEditLineTracker;
  if Tracker = nil then
    Exit;

  idx := Tracker.IndexOfLine(Line);
  if idx < 0 then
    Exit;

  AID := Tracker.Data[idx];
  Result := true;
end;

procedure TCodeCoverage.ModuleRenamed(const OldName, NewName: string);
var
  idx: Integer;
begin
  CoveredMethods.RenameFile(OldName, NewName);
  CoveredLines.RenameFile(OldName, NewName);
  CodeSyntaxTrees.RenameFile(OldName, NewName);
  if FullRepaint.Find(OldName, idx) then begin
    FullRepaint.Delete(idx);
    FullRepaint.Add(NewName);
  end;
end;

procedure TCodeCoverage.RemoveEditLineNotifier(const Tracker: IOTAEditLineTracker);
var
  instance: TEditLineNotifier;
begin
  instance := FindEditLineNotifier(Tracker);
  if instance <> nil then begin
    instance.Release;
  end;
end;

procedure TCodeCoverage.RemoveEditor(const Editor: IOTASourceEditor);
var
  EditBuffer: IOTAEditBuffer;
begin
  if Supports(Editor, IOTAEditBuffer, EditBuffer) then begin
    RemoveLineTracker(EditBuffer);
  end;
  CoveredLines.Remove(Editor.FileName);
  CoveredMethods.Remove(Editor.FileName);
  CodeSyntaxTrees.Remove(Editor.FileName);
end;

procedure TCodeCoverage.RemoveLineTracker(const EditBuffer: IOTAEditBuffer);
var
  Tracker: IOTAEditLineTracker;
begin
  Tracker := EditBuffer.GetEditLineTracker;
  RemoveEditLineNotifier(Tracker);
end;

procedure TCodeCoverage.RemoveLineTracker(const EditBuffer: IOTAEditBuffer; ALineNumber, AID: Integer);
var
  idx: Integer;
  Tracker: IOTAEditLineTracker;
begin
  Tracker := EditBuffer.GetEditLineTracker;
  idx := Tracker.IndexOfData(AID);
  if idx < 0 then begin
    idx := Tracker.IndexOfLine(ALineNumber);
  end;
  if idx >= 0 then begin
    Tracker.Delete(idx);
  end;
end;

procedure TCodeCoverage.RetrieveResults;
begin
  if not Active then
    Exit;

  CheckCodeCoverage;
  ClearAllCodeCoverage;
  Active := false;
end;

function TCodeCoverage.SelectCurrentMethod(const EditBuffer: IOTAEditBuffer; out AFileName, AMethodName: string; out
    LineMin, LineMax: Integer): Boolean;
var
  code: TCodeSyntaxTree;
begin
  Result := false;

  code := FindSyntaxTree(EditBuffer);
  if code <> nil then begin
    AFileName := code.FileName;
    Result := code.FindCurrentMethod(EditBuffer.TopView, AMethodName, LineMin, LineMax);
  end;
end;

function TCodeCoverage.SelectMethod(const AFileName: string; const AMethod: TCoveredMethod;
out LineMin, LineMax: Integer): Boolean;
var
  code: TCodeSyntaxTree;
begin
  Result := false;

  code := FindSyntaxTree(AFileName);
  if code <> nil then begin
    Result := code.SelectMethod(AMethod, LineMin, LineMax);
  end;
end;

function TCodeCoverage.SwitchCodeCoverage: Boolean;
var
  curLine: TLineNumber;
  curMethod: string;
  Data: TCoveredMethod;
  EditBuffer: IOTAEditBuffer;
  FileName: string;
  ID: Integer;
  LineMax: Integer;
  LineMin: Integer;
begin
  EditBuffer := OTA.EditorServices.TopBuffer;
  Result := SelectCurrentMethod(EditBuffer, FileName, curMethod, LineMin, LineMax);
  if Result then begin
    if FindMethod(EditBuffer, LineMin, Data) then begin
      CoveredMethods.Remove(FileName, Data.ID);
      CoveredLines.Remove(FileName, LineMin, LineMax);
      RemoveLineTracker(EditBuffer, Data.Line, Data.ID);
      FCurrentMethodState := TCoverState.coverable;
    end
    else begin
      curLine := LineMin;
      ID := AddLineTracker(EditBuffer, LineMin);
      CoveredMethods.Add(FileName, TCoveredMethod.Create(curMethod, curLine, ID));
      FCurrentMethodState := TCoverState.covered;
    end;
    MarkFullRepaint(FileName);
    EditBuffer.TopView.Paint;
  end
  else begin
    ShowMessage('No method body found at cursor!');
    FCurrentMethodState := TCoverState.noncoverable;
  end;
end;

procedure TCodeCoverage.TrackedLineChanged(const Tracker: IOTAEditLineTracker; OldLine, NewLine, Data: Integer);
var
  FileName: string;
  ID: TMethodID;
  newLineNumber: TLineNumber;
begin
  Valid := false;
  FileName := Tracker.GetEditBuffer.FileName;
  CoveredLines.Remove(FileName);
  ID := Data;
  newLineNumber := NewLine;
  CoveredMethods.ChangeLineNumber(FileName, ID, newLineNumber);
end;

procedure TCodeCoverage.UpdateCurrentMethodState;
var
  curMethod: string;
  Data: TCoveredMethod;
  EditBuffer: IOTAEditBuffer;
  FileName: string;
  LineMax: Integer;
  LineMin: Integer;
  state: TCoverState;
begin
  state := TCoverState.noncoverable;
  EditBuffer := OTA.EditorServices.TopBuffer;
  if SelectCurrentMethod(EditBuffer, FileName, curMethod, LineMin, LineMax) then begin
    state := TCoverState.coverable;
    if FindMethod(EditBuffer, LineMin, Data) then begin
      state := TCoverState.covered;
    end;
  end;
  FCurrentMethodState := state;
end;

end.

