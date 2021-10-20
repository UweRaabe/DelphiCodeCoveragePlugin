unit TestedUnit1;

interface

type
  TTestedClass = class
  public
    procedure TestedMethod1(A, B: Integer; out C: Integer);
    procedure TestedMethod2(A, B: Integer; out C: Integer);
  end;

implementation

procedure TTestedClass.TestedMethod1(A, B: Integer; out C: Integer);
begin
  if A < 0 then begin
    A := -A;
  end;

  if B < 0 then
  begin
    B := -B;
  end;

  if B < A then begin
    C := A - B;
  end
  else begin
    C := B - A;
  end;
end;

procedure TTestedClass.TestedMethod2(A, B: Integer; out C: Integer);
begin
  if A < 0 then begin
    A := -A;
  end;

  if B < 0 then
  begin
    B := -B;
  end;

  if B < A then begin
    C := A - B;
  end
  else begin
    C := B - A;
  end;
end;

end.
