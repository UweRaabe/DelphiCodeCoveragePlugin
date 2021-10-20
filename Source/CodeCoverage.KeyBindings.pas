unit CodeCoverage.KeyBindings;

interface

uses
  System.Classes,
  CodeCoverage.Notifier,
  ToolsAPI;

type
  TKeyboardBinding = class(TCodeCoverageNotifier, IOTAKeyboardBinding)
  private
    FSwitchKeyCode: TShortCut;
    procedure SwitchCodeCoverage(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
  protected
    function DoRegister: Integer; override;
    procedure DoUnregister(ID: Integer); override;
  public
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
  end;

implementation

uses
  Winapi.Windows,
  CodeCoverage.ApiHelper;

resourcestring
  SCodeCoverageBindings = 'Code Coverage Bindings';

const
  cCodeCoverageBindings = 'CodeCoverageBindings';

procedure TKeyboardBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  FSwitchKeyCode := scCtrl or scAlt or VK_F5;
  BindingServices.AddKeyBinding([FSwitchKeyCode], SwitchCodeCoverage, nil)
end;

function TKeyboardBinding.DoRegister: Integer;
begin
  Result := OTA.KeyboardServices.AddKeyboardBinding(Self);
end;

procedure TKeyboardBinding.DoUnregister(ID: Integer);
begin
  OTA.KeyboardServices.RemoveKeyboardBinding(ID);
  inherited;
end;

function TKeyboardBinding.GetBindingType: TBindingType;
begin
  result := btPartial;
end;

function TKeyboardBinding.GetDisplayName: string;
begin
  result := SCodeCoverageBindings;
end;

function TKeyboardBinding.GetName: string;
begin
  result := cCodeCoverageBindings;
end;

procedure TKeyboardBinding.SwitchCodeCoverage(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
  CodeCoverage.SwitchCodeCoverage;
  BindingResult := krHandled;
end;

end.
