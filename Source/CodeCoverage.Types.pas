unit CodeCoverage.Types;

interface

uses
  System.Generics.Collections;

type
  { Aliases to clarify the meaning of the type (especially with dictionaries) }
  TLineNumber = Integer;
  TMethodID = Integer;
  THitCount = Integer;
  TPercent = Integer;
  TFileName = string;

type
  TFileNameDict<T> = class(TObjectDictionary<TFileName, T>)
  public
    constructor Create;
    procedure RenameFile(const OldName, NewName: string);
  end;

type
  TCoveredLinesHandler = reference to procedure(const AFileName: string; ALineNumber, APassCount: Integer);

  TCoveredLinesList = class(TDictionary<TLineNumber, THitCount>);

  TCoveredLinesDict = class(TFileNameDict<TCoveredLinesList>);

  TCoveredLines = class
  private
    FData: TCoveredLinesDict;
    function FindOrAddList(const AFileName: string): TCoveredLinesList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFileName: string; const ALineNumber: TLineNumber; const ACount: THitCount);
    procedure Clear;
    function Find(const AFileName: string): TCoveredLinesList; overload;
    function Find(const AFileName: string; const ALineNumber: TLineNumber): THitCount; overload;
    procedure Initialize(const AFileName: string; const ALineNumber: TLineNumber; const ACount: THitCount);
    function IsEmpty: Boolean;
    procedure Iterate(Callback: TCoveredLinesHandler);
    procedure Remove(const AFileName: string; const LineMin, LineMax: TLineNumber); overload;
    procedure Remove(const AFileName: string); overload;
    procedure RenameFile(const OldName, NewName: string);
  end;

type
  TCoveredMethod = record
  private
    FID: TMethodID;
    FLine: TLineNumber;
    FLineMax: Integer;
    FLineMin: Integer;
    FName: string;
    FPercent: TPercent;
  public
    constructor Create(const AName: string; const ALine: TLineNumber; const AID: TMethodID);
    property ID: TMethodID read FID;
    property Line: TLineNumber read FLine write FLine;
    property LineMax: Integer read FLineMax write FLineMax;
    property LineMin: Integer read FLineMin write FLineMin;
    property Name: string read FName write FName;
    property Percent: TPercent read FPercent write FPercent;
  end;

  TCoveredMethodHandler = reference to procedure(const AFileName: string; const Data: TCoveredMethod);

  TCoveredMethodIndex = class(TDictionary<TMethodID, TCoveredMethod>);

  TCoveredMethodList = class
  private
    FData: TCoveredMethodIndex;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const Value: TCoveredMethod);
    procedure ChangeLineNumber(const AID: TMethodID; const ALineNumber: TLineNumber); overload;
    function Find(const AID: TMethodID; out Value: TCoveredMethod): Boolean;
    function IsEmpty: Boolean;
    procedure Iterate(const AFileName: string; Callback: TCoveredMethodHandler);
    procedure Remove(const AID: TMethodID); overload;
    procedure Update(const AID: TMethodID; ALineMin, ALineMax: Integer); overload;
    procedure UpdatePercent(const AID: TMethodID; const APercent: TPercent); overload;
  end;

  TCoveredMethodDict = class(TFileNameDict<TCoveredMethodList>);

  TCoveredMethods = class
  strict private
    function FindOrAddList(const AFileName: string): TCoveredMethodList;
  private
    FData: TCoveredMethodDict;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFileName: string; const Data: TCoveredMethod);
    procedure ChangeLineNumber(const AFileName: string; const AID: TMethodID; const ALineNumber: TLineNumber);
    function Find(const AFileName: string; const AID: TMethodID; out Value: TCoveredMethod): Boolean; overload;
    function Find(const AFileName: string): TCoveredMethodList; overload;
    function IsEmpty: Boolean;
    procedure Iterate(Callback: TCoveredMethodHandler);
    procedure Remove(const AFileName: string; const AID: TMethodID); overload;
    procedure Remove(const AFileName: string); overload;
    procedure RenameFile(const OldName, NewName: string);
    procedure Update(const AFileName: string; const AID: TMethodID; ALineMin, ALineMax: Integer); overload;
    procedure UpdatePercent(const AFileName: string; const AID: TMethodID; APercent: Integer); overload;
  end;

implementation

constructor TCoveredMethod.Create(const AName: string; const ALine: TLineNumber; const AID: TMethodID);
begin
  FName := AName;
  FLine := ALine;
  FID := AID;
end;

constructor TCoveredLines.Create;
begin
  inherited Create;
  FData := TCoveredLinesDict.Create;
end;

destructor TCoveredLines.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TCoveredLines.Add(const AFileName: string; const ALineNumber: TLineNumber; const ACount: THitCount);
var
  Count: THitCount;
  list: TCoveredLinesList;
begin
  list := FindOrAddList(AFileName);
  if not list.TryGetValue(ALineNumber, Count) then begin
    Count := ACount;
  end
  else begin
    Count := Count + ACount;
  end;
  list.AddOrSetValue(ALineNumber, Count);
end;

procedure TCoveredLines.Clear;
begin
  FData.Clear;
end;

function TCoveredLines.Find(const AFileName: string): TCoveredLinesList;
begin
  if not FData.TryGetValue(AFileName, Result) then begin
    Result := nil;
  end;
end;

function TCoveredLines.Find(const AFileName: string; const ALineNumber: TLineNumber): THitCount;
var
  count: THitCount;
  list: TCoveredLinesList;
begin
  Result := -1;
  list := FindOrAddList(AFileName);
  if list <> nil then begin
    if list.TryGetValue(ALineNumber, count) then begin
      Result := count;
    end;
  end;
end;

function TCoveredLines.FindOrAddList(const AFileName: string): TCoveredLinesList;
begin
  if not FData.TryGetValue(AFileName, Result) then begin
    Result := TCoveredLinesList.Create;
    FData.Add(AFileName, Result);
  end;
end;

procedure TCoveredLines.Initialize(const AFileName: string; const ALineNumber: TLineNumber; const ACount: THitCount);
var
  list: TCoveredLinesList;
begin
  list := FindOrAddList(AFileName);
  list.AddOrSetValue(ALineNumber, ACount);
end;

function TCoveredLines.IsEmpty: Boolean;
begin
  Result := (FData.Count = 0);
end;

procedure TCoveredLines.Iterate(Callback: TCoveredLinesHandler);
var
  arr: TArray<TLineNumber>;
  line: TLineNumber;
  passCount: TCoveredLinesList;
  pair: TPair<string, TCoveredLinesList>;
begin
  for pair in FData do begin
    passCount := pair.Value;
    arr := passCount.Keys.ToArray;
    TArray.Sort<TLineNumber>(arr);
    for line in arr do begin
      Callback(pair.Key, line, passCount[line]);
    end;
  end;
end;

procedure TCoveredLines.Remove(const AFileName: string; const LineMin, LineMax: TLineNumber);
var
  list: TCoveredLinesList;
  I: TLineNumber;
begin
  list := Find(AFileName);
  if list <> nil then begin
    for I := LineMin to LineMax do begin
      list.Remove(I);
    end;
    if list.Count = 0 then begin
      FData.Remove(AFileName);
    end;
  end;
end;

procedure TCoveredLines.Remove(const AFileName: string);
begin
  FData.Remove(AFileName);
end;

procedure TCoveredLines.RenameFile(const OldName, NewName: string);
begin
  FData.RenameFile(OldName, NewName);
end;

constructor TCoveredMethodList.Create;
begin
  inherited Create;
  FData := TCoveredMethodIndex.Create;
end;

destructor TCoveredMethodList.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TCoveredMethodList.Add(const Value: TCoveredMethod);
begin
  FData.AddOrSetValue(Value.ID, Value);
end;

procedure TCoveredMethodList.ChangeLineNumber(const AID: TMethodID; const ALineNumber: TLineNumber);
var
  value: TCoveredMethod;
begin
  if FData.TryGetValue(AID, value) then begin
    value.Line := ALineNumber;
    FData.Items[AID] := value;
  end;
end;

function TCoveredMethodList.Find(const AID: TMethodID; out Value: TCoveredMethod): Boolean;
begin
  Result := FData.TryGetValue(AID, Value);
end;

function TCoveredMethodList.IsEmpty: Boolean;
begin
  Result := (FData.Count = 0);
end;

procedure TCoveredMethodList.Iterate(const AFileName: string; Callback: TCoveredMethodHandler);
var
  pair: TPair<TMethodID, TCoveredMethod>;
begin
  for pair in FData do begin
    Callback(AFileName, pair.Value);
  end;
end;

procedure TCoveredMethodList.Remove(const AID: TMethodID);
var
  data: TCoveredMethod;
begin
  if FData.TryGetValue(AID, data) then begin
    FData.Remove(AID);
  end;
end;

procedure TCoveredMethodList.Update(const AID: TMethodID; ALineMin, ALineMax: Integer);
var
  data: TCoveredMethod;
begin
  if FData.TryGetValue(AID, data) then begin
    data.LineMin := ALineMin;
    data.LineMax := ALineMax;
    FData[AID] := data;
  end;
end;

procedure TCoveredMethodList.UpdatePercent(const AID: TMethodID; const APercent: TPercent);
var
  data: TCoveredMethod;
begin
  if FData.TryGetValue(AID, data) then begin
    data.Percent := APercent;
    FData[AID] := data;
  end;
end;

constructor TCoveredMethods.Create;
begin
  inherited Create;
  FData := TCoveredMethodDict.Create;
end;

destructor TCoveredMethods.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TCoveredMethods.Add(const AFileName: string; const Data: TCoveredMethod);
var
  list: TCoveredMethodList;
begin
  list := FindOrAddList(AFileName);
  list.Add(Data);
end;

procedure TCoveredMethods.ChangeLineNumber(const AFileName: string; const AID: TMethodID; const ALineNumber:
    TLineNumber);
var
  list: TCoveredMethodList;
begin
  list := Find(AFileName);
  if list <> nil then begin
    list.ChangeLineNumber(AID, ALineNumber);
  end;
end;

function TCoveredMethods.Find(const AFileName: string; const AID: TMethodID; out Value: TCoveredMethod): Boolean;
var
  list: TCoveredMethodList;
begin
  Result := False;
  list := Find(AFileName);
  if list <> nil then begin
    Result := list.Find(AID, Value);
  end;
end;

function TCoveredMethods.Find(const AFileName: string): TCoveredMethodList;
begin
  if not FData.TryGetValue(AFileName, Result) then begin
    Result := nil;
  end;
end;

function TCoveredMethods.FindOrAddList(const AFileName: string): TCoveredMethodList;
begin
  if not FData.TryGetValue(AFileName, Result) then begin
    Result := TCoveredMethodList.Create;
    FData.Add(AFileName, Result);
  end;
end;

function TCoveredMethods.IsEmpty: Boolean;
begin
  Result := (FData.Count = 0);
end;

procedure TCoveredMethods.Iterate(Callback: TCoveredMethodHandler);
var
  pair: TPair<string, TCoveredMethodList>;
begin
  for pair in FData do begin
    pair.Value.Iterate(pair.Key, Callback);
  end;
end;

procedure TCoveredMethods.Remove(const AFileName: string; const AID: TMethodID);
var
  list: TCoveredMethodList;
begin
  list := Find(AFileName);
  if list <> nil then begin
    list.Remove(AID);
    if list.IsEmpty then begin
      FData.Remove(AFileName);
    end;
  end;
end;

procedure TCoveredMethods.Remove(const AFileName: string);
begin
  FData.Remove(AFileName);
end;

procedure TCoveredMethods.RenameFile(const OldName, NewName: string);
begin
  FData.RenameFile(OldName, NewName);
end;

procedure TCoveredMethods.Update(const AFileName: string; const AID: TMethodID; ALineMin, ALineMax: Integer);
var
  list: TCoveredMethodList;
begin
  list := Find(AFileName);
  if list <> nil then begin
    list.Update(AID, ALineMin, ALineMax);
  end;
end;

procedure TCoveredMethods.UpdatePercent(const AFileName: string; const AID: TMethodID; APercent: Integer);
var
  list: TCoveredMethodList;
begin
  list := Find(AFileName);
  if list <> nil then begin
    list.UpdatePercent(AID, APercent);
  end;
end;

constructor TFileNameDict<T>.Create;
begin
  inherited Create([doOwnsValues]);
end;

procedure TFileNameDict<T>.RenameFile(const OldName, NewName: string);
var
  pair: TPair<string, T>;
begin
  if ContainsKey(OldName) then begin
    if ContainsKey(NewName) then begin
      Remove(OldName);
    end
    else begin
      pair := ExtractPair(OldName);
      Add(NewName, pair.Value);
    end;
  end;
end;

end.
