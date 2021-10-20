unit CodeCoverage.SyntaxTypes;

interface

uses
  System.SysUtils,
  DelphiAST.Classes,
  CodeCoverage.Types,
  ToolsAPI;

type
  TCodeSyntaxTree = class
  private
    FFileName: string;
    FNodeImplementation: TSyntaxNode;
    FSyntaxTree: TSyntaxNode;
    procedure InitNodes;
    procedure SetSyntaxTree(const Value: TSyntaxNode);
  protected
    function FindMethod(ALineNumber: Integer): TCompoundSyntaxNode; overload;
    function FindMethod(const AMethod: TCoveredMethod): TCompoundSyntaxNode; overload;
    function FindMethod(APredicate: TPredicate<TCompoundSyntaxNode>): TCompoundSyntaxNode; overload;
    function SelectMethod(ANode: TCompoundSyntaxNode; out LineMin, LineMax: Integer): Boolean; overload;
    property NodeImplementation: TSyntaxNode read FNodeImplementation;
    property SyntaxTree: TSyntaxNode read FSyntaxTree write SetSyntaxTree;
  public
    destructor Destroy; override;
    procedure Clear;
    function FindCurrentMethod(EditView: IOTAEditView; out AMethodName: string; out LineMin, LineMax: Integer): Boolean;
    function LoadFrom(Editor: IOTASourceEditor): Boolean;
    function SelectMethod(ALineNumber: Integer; out LineMin, LineMax: Integer): Boolean; overload;
    function SelectMethod(const AMethod: TCoveredMethod; out LineMin, LineMax: Integer): Boolean; overload;
    property FileName: string read FFileName;
  end;

  TCodeSyntaxTreeDict = class(TFileNameDict<TCodeSyntaxTree>);

  TCodeSyntaxTrees = class
  private
    FData: TCodeSyntaxTreeDict;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(Editor: IOTASourceEditor): TCodeSyntaxTree;
    function Find(const AFileName: string; out Value: TCodeSyntaxTree): Boolean;
    procedure Remove(const AFileName: string);
    procedure RenameFile(const OldName, NewName: string);
  end;

implementation

uses
  System.Math, System.Classes, System.Generics.Collections,
  DelphiAST.Consts, DelphiAST;

destructor TCodeSyntaxTree.Destroy;
begin
  FSyntaxTree.Free;
  inherited Destroy;
end;

procedure TCodeSyntaxTree.Clear;
begin
  FFileName := '';
  FNodeImplementation := nil;
  FSyntaxTree.Free;
  FSyntaxTree := nil;
end;

function TCodeSyntaxTree.FindCurrentMethod(EditView: IOTAEditView; out AMethodName: string; out LineMin, LineMax:
    Integer): Boolean;
var
  curPos: TOTAEditPos;
  node: TCompoundSyntaxNode;
begin
  Result := False;

  curPos := EditView.CursorPos;
  node := FindMethod(curPos.Line);
  if node <> nil then begin
    if (node.Line = curPos.Line) and (curPos.Col < node.Col) then Exit;
    if (node.EndLine = curPos.Line) and (node.EndCol <= curPos.Col) then Exit;

    AMethodName := node.GetAttribute(anName);
    LineMin := node.Line;
    LineMax := node.EndLine;
    Result := True;
  end;
end;

function TCodeSyntaxTree.FindMethod(ALineNumber: Integer): TCompoundSyntaxNode;
begin
  Result := FindMethod(
    function (Arg: TCompoundSyntaxNode): Boolean
    begin
      Result := InRange(ALineNumber, Arg.Line, Arg.EndLine - 1);
    end);
end;

function TCodeSyntaxTree.FindMethod(const AMethod: TCoveredMethod): TCompoundSyntaxNode;
var
  targetLine: Integer;
  targetName: string;
begin
  targetName := AMethod.Name;
  targetLine := AMethod.Line;
  Result := FindMethod(
    function (Arg: TCompoundSyntaxNode): Boolean
    begin
      Result := SameText(Arg.GetAttribute(anName), targetName) and (Arg.Line = targetLine);
    end);
end;

function TCodeSyntaxTree.FindMethod(APredicate: TPredicate<TCompoundSyntaxNode>): TCompoundSyntaxNode;
var
  compNode: TCompoundSyntaxNode;
  node: TSyntaxNode;
begin
  Result := nil;
  if NodeImplementation <> nil then begin
    for node in NodeImplementation.ChildNodes do begin
      if node is TCompoundSyntaxNode then begin
        compNode := node as TCompoundSyntaxNode;
        if (compNode.Typ = ntMethod) and APredicate(compNode) then begin
          Exit(compNode);
        end;
      end;
    end;
  end;
end;

procedure TCodeSyntaxTree.InitNodes;
begin
  if SyntaxTree <> nil then begin
    FNodeImplementation := SyntaxTree.FindNode(ntImplementation);
  end
  else begin
    FNodeImplementation := nil;
  end;
end;

function TCodeSyntaxTree.LoadFrom(Editor: IOTASourceEditor): Boolean;
const
  cBufferSize = 16*1024;
var
  buffer: TBytes;
  cntRead: Integer;
  curPos: Integer;
  stream: TStringStream;
  builder: TPasSyntaxTreeBuilder;
  reader: IOTAEditReader;
begin
  Result := False;
  Clear;
  if Editor = nil then Exit;

  FFileName := Editor.FileName;

  stream := TStringStream.Create('', TEncoding.UTF8);
  try
    SetLength(buffer, cBufferSize);
    curPos := 0;
    reader := Editor.CreateReader;
    repeat
      cntRead := reader.GetText(curPos, PAnsiChar(@buffer[0]), cBufferSize);
      if cntRead > 0 then begin
        stream.Write(buffer, cntRead);
        curPos := curPos + cntRead;
      end;
    until cntRead < cBufferSize;
    reader := nil;

    stream.Position := 0;
    builder := TPasSyntaxTreeBuilder.Create;
    try
      builder.InitDefinesDefinedByCompiler;
      try
        SyntaxTree := builder.Run(stream);
        Result := True;
      except
        { We can log the exception somehow, f.i. with CodeSite, but we don't show it!
          It is just code that cannot be parsed. Returning False is sufficient. }
        on E: Exception do begin
//          CodeSite.SendException(E);
        end;
      end;
    finally
      builder.Free;
    end;
  finally
    stream.Free;
  end;
end;

function TCodeSyntaxTree.SelectMethod(ALineNumber: Integer; out LineMin, LineMax: Integer): Boolean;
begin
  Result := SelectMethod(FindMethod(ALineNumber), LineMin, LineMax);
end;

function TCodeSyntaxTree.SelectMethod(ANode: TCompoundSyntaxNode; out LineMin, LineMax: Integer): Boolean;
var
  compNode: TCompoundSyntaxNode;
begin
  Result := False;
  if ANode <> nil then begin
    compNode := ANode.FindNode(ntStatements) as TCompoundSyntaxNode;
    if compNode <> nil then begin
      LineMin := compNode.Line;
      LineMax := compNode.EndLine;
      Result := True;
    end;
  end;
end;

function TCodeSyntaxTree.SelectMethod(const AMethod: TCoveredMethod; out LineMin, LineMax: Integer): Boolean;
begin
  Result := SelectMethod(FindMethod(AMethod), LineMin, LineMax);
end;

procedure TCodeSyntaxTree.SetSyntaxTree(const Value: TSyntaxNode);
begin
  if FSyntaxTree <> Value then
  begin
    FSyntaxTree.Free;
    FSyntaxTree := Value;
    InitNodes;
  end;
end;

constructor TCodeSyntaxTrees.Create;
begin
  inherited Create;
  FData := TCodeSyntaxTreeDict.Create();
end;

destructor TCodeSyntaxTrees.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

function TCodeSyntaxTrees.Add(Editor: IOTASourceEditor): TCodeSyntaxTree;
var
  tree: TCodeSyntaxTree;
begin
  if not FData.TryGetValue(Editor.FileName, Result) then begin
    Result := nil;
    tree := TCodeSyntaxTree.Create;
    try
      if tree.LoadFrom(Editor) then begin
        Result := tree;
        tree := nil;
        FData.Add(Editor.FileName, Result);
      end
    finally
      tree.Free;
    end;
  end;
end;

function TCodeSyntaxTrees.Find(const AFileName: string; out Value: TCodeSyntaxTree): Boolean;
begin
  Result := FData.TryGetValue(AFileName, Value);
end;

procedure TCodeSyntaxTrees.Remove(const AFileName: string);
begin
  FData.Remove(AFileName);
end;

procedure TCodeSyntaxTrees.RenameFile(const OldName, NewName: string);
begin
  FData.RenameFile(OldName, NewName);
end;

end.
