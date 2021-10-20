unit TestUnit1;

interface
uses
  DUnitX.TestFramework, TestedUnit1;

type

  [TestFixture]
  TMyTestObject = class(TObject)
  private
    FInstance: TTestedClass;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('Test1', '2,1,1')]
//    [TestCase('Test2', '1,2,1')]
//    [TestCase('Test3', '-2,1,1')]
//    [TestCase('Test4', '1,-2,1')]
    procedure TestMethod1(A, B, C: Integer);
    [Test]
    [TestCase('Test1a', '2,1,1')]
//    [TestCase('Test2a', '1,2,1')]
//    [TestCase('Test3a', '-2,1,1')]
//    [TestCase('Test4a', '1,-2,1')]
    procedure TestMethod2(A, B, C: Integer);
  end;

implementation

procedure TMyTestObject.Setup;
begin
  FInstance := TTestedClass.Create;
end;

procedure TMyTestObject.TearDown;
begin
  FInstance.Free;
  FInstance := nil;
end;


procedure TMyTestObject.TestMethod1(A, B, C: Integer);
var
  res: Integer;
begin
  FInstance.TestedMethod1(A, B, res);
  Assert.AreEqual(C, res);
end;

procedure TMyTestObject.TestMethod2(A, B, C: Integer);
var
  res: Integer;
begin
  FInstance.TestedMethod2(A, B, res);
  Assert.AreEqual(C, res);
end;

initialization
  TDUnitX.RegisterTestFixture(TMyTestObject);
end.
