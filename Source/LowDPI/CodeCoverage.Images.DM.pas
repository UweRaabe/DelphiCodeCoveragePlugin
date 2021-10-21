unit CodeCoverage.Images.DM;

interface

uses
  System.ImageList, System.Classes, System.Actions,
  Vcl.ImgList, Vcl.Controls, Vcl.Menus, Vcl.ActnList, Vcl.Graphics,
  PngImageList;

type
  TdmCodeCoverageImages = class(TDatamodule)
    Images: TPngImageList;
  public
    function FindImageIndexByName(const AImageName: string): Integer;
  end;

var
  dmCodeCoverageImages: TdmCodeCoverageImages;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TdmCodeCoverageImages.FindImageIndexByName(const AImageName: string): Integer;
begin
  Result := Images.FindIndexByName(AImageName);
end;

end.

