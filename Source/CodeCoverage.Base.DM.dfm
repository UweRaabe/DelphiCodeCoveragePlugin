object dmCodeCoverageBase: TdmCodeCoverageBase
  OldCreateOrder = True
  Height = 302
  Width = 584
  object Actions: TActionList
    Left = 120
    Top = 40
    object actSwitchCodeCoverage: TAction
      Category = 'Code Coverage'
      Caption = 'Switch Code Coverage'
      Hint = 'Switch code coverage for current method'
      ImageIndex = 1
      OnExecute = actSwitchCodeCoverageExecute
      OnUpdate = actSwitchCodeCoverageUpdate
    end
    object actRunCodeCoverage: TAction
      Category = 'Code Coverage'
      Caption = 'Run Code Coverage'
      Hint = 'Runs the test project for code coverage'
      ImageIndex = 2
      OnExecute = actRunCodeCoverageExecute
      OnUpdate = actRunCodeCoverageUpdate
    end
  end
  object MenuItems: TPopupMenu
    Left = 296
    Top = 40
    object mnuRunCodeCoverage: TMenuItem
      Action = actRunCodeCoverage
    end
  end
end
