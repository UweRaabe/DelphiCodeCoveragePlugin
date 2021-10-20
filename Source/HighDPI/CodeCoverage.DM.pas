unit CodeCoverage.DM;

interface

uses
  Winapi.Windows,
  System.ImageList, System.Classes, System.Actions, System.Messaging,
  Vcl.ImgList, Vcl.Controls, Vcl.Menus, Vcl.ActnList, Vcl.Graphics, Vcl.VirtualImageList, Vcl.BaseImageCollection,
  Vcl.ImageCollection, Vcl.Forms,
  CodeCoverage.Base.DM;

type
  TdmCodeCoverage = class(TdmCodeCoverageBase)
    Images: TVirtualImageList;
    MainImageCollection: TImageCollection;
  private
    FDPIChangedMessageID: Integer;
    procedure DPIChangedMessageHandler(const Sender: TObject; const M: System.Messaging.TMessage);
    function GetImageArray(const AImageName: string): TGraphicArray;
  strict protected
    function FindImageIndexByName(const AImageName: string): Integer; override;
  protected
     function GetImageList: TCustomImageList; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ImageArray[const AImageName: string]: TGraphicArray read GetImageArray;
  end;

var
  dmCodeCoverage: TdmCodeCoverage;

implementation

uses
  CodeCoverage.ApiHelper;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

constructor TdmCodeCoverage.Create(AOwner: TComponent);
begin
  inherited;
  FDPIChangedMessageID := TMessageManager.DefaultManager.SubscribeToMessage(TChangeScaleMessage, DPIChangedMessageHandler);
end;

destructor TdmCodeCoverage.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TChangeScaleMessage, FDPIChangedMessageID);
  inherited;
end;

procedure TdmCodeCoverage.DPIChangedMessageHandler(const Sender: TObject; const M: System.Messaging.TMessage);
var
  size: Integer;
begin
  size := NTA.Services.ImageList.Width;
  Images.SetSize(size, size);
end;

function TdmCodeCoverage.FindImageIndexByName(const AImageName: string): Integer;
begin
  Result := Images.GetIndexByName(AImageName);
end;

function TdmCodeCoverage.GetImageArray(const AImageName: string): TGraphicArray;
var
  idx: Integer;
  item: TImageCollectionItem;
  I: Integer;
begin
  idx := MainImageCollection.GetIndexByName(AImageName);
  if idx < 0 then
    Exit(nil);
  item := MainImageCollection.Images[idx];
  SetLength(Result, item.SourceImages.Count);
  for I := 0 to item.SourceImages.Count - 1 do
    Result[I] := item.SourceImages[I].Image;
end;

function TdmCodeCoverage.GetImageList: TCustomImageList;
begin
  Result := Images;
end;

end.

