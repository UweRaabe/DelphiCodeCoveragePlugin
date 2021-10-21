unit CodeCoverage.Images.DM;

interface

uses
  Winapi.Windows,
  System.ImageList, System.Classes, System.Actions, System.Messaging,
  Vcl.ImgList, Vcl.Controls, Vcl.Menus, Vcl.ActnList, Vcl.Graphics, Vcl.VirtualImageList, Vcl.BaseImageCollection,
  Vcl.ImageCollection, Vcl.Forms;

type
  TdmCodeCoverageImages = class(TDatamodule)
    Images: TVirtualImageList;
    MainImageCollection: TImageCollection;
  private
    FDPIChangedMessageID: Integer;
    procedure DPIChangedMessageHandler(const Sender: TObject; const M: System.Messaging.TMessage);
    function GetImageArray(const AImageName: string): TGraphicArray;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FindImageIndexByName(const AImageName: string): Integer;
    property ImageArray[const AImageName: string]: TGraphicArray read GetImageArray;
  end;

var
  dmCodeCoverageImages: TdmCodeCoverageImages;

implementation

uses
  CodeCoverage.ApiHelper;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

constructor TdmCodeCoverageImages.Create(AOwner: TComponent);
begin
  inherited;
  FDPIChangedMessageID := TMessageManager.DefaultManager.SubscribeToMessage(TChangeScaleMessage, DPIChangedMessageHandler);
end;

destructor TdmCodeCoverageImages.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TChangeScaleMessage, FDPIChangedMessageID);
  inherited;
end;

procedure TdmCodeCoverageImages.DPIChangedMessageHandler(const Sender: TObject; const M: System.Messaging.TMessage);
var
  size: Integer;
begin
  size := NTA.Services.ImageList.Width;
  Images.SetSize(size, size);
end;

function TdmCodeCoverageImages.FindImageIndexByName(const AImageName: string): Integer;
begin
  Result := Images.GetIndexByName(AImageName);
end;

function TdmCodeCoverageImages.GetImageArray(const AImageName: string): TGraphicArray;
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

end.

