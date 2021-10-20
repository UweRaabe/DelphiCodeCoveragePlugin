unit CodeCoverage.DM;

interface

uses
  System.ImageList, System.Classes, System.Actions,
  Vcl.ImgList, Vcl.Controls, Vcl.Menus, Vcl.ActnList, Vcl.Graphics,
  PngImageList,
  CodeCoverage.Base.DM;

type
  TdmCodeCoverage = class(TdmCodeCoverageBase)
    Images: TPngImageList;
  private
  strict protected
    function FindImageIndexByName(const AImageName: string): Integer; override;
  public
  end;

var
  dmCodeCoverage: TdmCodeCoverage;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TdmCodeCoverage.FindImageIndexByName(const AImageName: string): Integer;
begin
  Result := Images.FindIndexByName(AImageName);
end;

end.

