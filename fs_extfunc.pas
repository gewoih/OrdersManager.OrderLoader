unit fs_extfunc;

interface

uses
  fs_ipascal,
  fs_iinterpreter;

type
  txUDFClass = class
    class function DoUserFunction(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
  end;

procedure InitFunctions(Script: tfsScript); overload;

var fCon: oleVariant;

implementation

uses
  SysUtils,
  StrUtils,
  DateUtils,
  Variants,
  ActiveX,
  Windows,
  Classes,
  Math,
  uxHelpers;

function Period(DS, DE: TDate): string;
var E, R, M, Q, P, Y: cardinal;
label F;
const Months: array[1..12] of string = ('€нварь','февраль','март','апрель','май','июнь','июль','август','сент€брь','окт€брь','но€брь','декабрь');
const Months2: array[1..12] of string = ('€нвар€','феврал€','марта','апрел€','ма€','июн€','июл€','августа','сент€бр€','окт€бр€','но€бр€','декабр€');
begin
  R := 0; Q := 0; M := 0;
  E := StrToInt(FormatDateTime('mmdd', DE));
  Y := YearOf(DS);

  if Y<>YearOf(DE) then goto F;
  if DayOf(DS) = 1 then M := MonthOf(DS) else goto F;
  case M of
    01: Q := 1;
    04: Q := 2;
    07: Q := 3;
    10: Q := 4;
  end;

  if Q = 1 then
  case E of
    1231: R := 1;
    0630: R := 2;
    0331: R := 3;
    0131: R := 4;
  else
    R := 0;
    goto F;
  end;

  if Q = 2 then
  case E of
    0630: R := 3;
    0430: R := 4;
  else
    R := 0;
    goto F;
  end;

  if Q = 3 then
  case E of
    1231: R := 2;
    0930: R := 3;
    0731: R := 4;
  else
    R := 0;
    goto F;
  end;

  if Q = 4 then
  case E of
    1231: R := 3;
    1031: R := 4;
  else
    R := 0;
    goto F;
  end;

  if R = 2 then
  case Q of
    1, 2: P :=1;
    3, 4: P :=2;
  end;

F:case R of
    1: Result := format(' за %d год', [Y]);
    2: Result := format(' за %d полугодие %d года', [P, Y]);
    3: Result := format(' за %d квартал %d года', [Q, Y]);
    4: Result := format(' за %s %d года', [Months[M], Y]);
  else
    if Ds=De then
      Result := format(' за %d %s %d г.', [DayOf(Ds), Months2[MonthOf(Ds)], YearOf(Ds)])
    else
      Result := format(' за период с %d %s %d г. по %d %s %d г.', [DayOf(Ds), Months2[MonthOf(Ds)], YearOf(Ds), DayOf(De), Months2[MonthOf(De)], YearOf(De)]);
  end;
end;

function Propis(Value: int64): string;
var
  Rend: boolean;
  ValueTemp: int64;
  procedure Num(Value: byte);
  begin
    case Value of
      1: if Rend = true then Result := Result + 'один ' else Result := Result + 'одна ';
      2: if Rend = true then Result := Result + 'два ' else Result := Result + 'две ';
      3: Result := Result + 'три ';
      4: Result := Result + 'четыре ';
      5: Result := Result + 'п€ть ';
      6: Result := Result + 'шесть ';
      7: Result := Result + 'семь ';
      8: Result := Result + 'восемь ';
      9: Result := Result + 'дев€ть ';
      10: Result := Result + 'дес€ть ';
      11: Result := Result + 'одиннадцать ';
      12: Result := Result + 'двенадцать ';
      13: Result := Result + 'тринадцать ';
      14: Result := Result + 'четырнадцать ';
      15: Result := Result + 'п€тнадцать ';
      16: Result := Result + 'шестнадцать ';
      17: Result := Result + 'семнадцать ';
      18: Result := Result + 'восемнадцать ';
      19: Result := Result + 'дев€тнадцать ';
    end
  end;

  procedure Num10(Value: byte);
  begin
    case Value of
      2: Result := Result + 'двадцать ';
      3: Result := Result + 'тридцать ';
      4: Result := Result + 'сорок ';
      5: Result := Result + 'п€тьдес€т ';
      6: Result := Result + 'шестьдес€т ';
      7: Result := Result + 'семьдес€т ';
      8: Result := Result + 'восемьдес€т ';
      9: Result := Result + 'дев€носто ';
    end;
  end;

  procedure Num100(Value: byte);
  begin
    case Value of
      1: Result := Result + 'сто ';
      2: Result := Result + 'двести ';
      3: Result := Result + 'триста ';
      4: Result := Result + 'четыреста ';
      5: Result := Result + 'п€тьсот ';
      6: Result := Result + 'шестьсот ';
      7: Result := Result + 'семьсот ';
      8: Result := Result + 'восемьсот ';
      9: Result := Result + 'дев€тьсот ';
    end
  end;

  procedure Num00;
  begin
    Num100(ValueTemp div 100);
    ValueTemp := ValueTemp mod 100;
    if ValueTemp < 20 then Num(ValueTemp)
    else
    begin
      Num10(ValueTemp div 10);
      ValueTemp := ValueTemp mod 10;
      Num(ValueTemp);
    end;
  end;

  procedure NumMult(Mult: int64; s1, s2, s3: string);
  var ValueRes: int64;
  begin
    if Value >= Mult then
    begin
      ValueTemp := Value div Mult;
      ValueRes := ValueTemp;
      Num00;
      if ValueTemp = 1 then Result := Result + s1
      else if (ValueTemp > 1) and (ValueTemp < 5) then Result := Result + s2
      else Result := Result + s3;
      Value := Value - Mult * ValueRes;
    end;
  end;

begin
  if (Value = 0) then Result := 'ноль '
  else
  begin
    Result := '';
    Rend := true;
    NumMult(1000000000000, 'триллион ', 'триллиона ', 'триллионов ');
    NumMult(1000000000, 'миллиард ', 'миллиарда ', 'миллиардов ');
    NumMult(1000000, 'миллион ', 'миллиона ', 'миллионов ');
    Rend := false;
    NumMult(1000, 'тыс€ча ', 'тыс€чи ', 'тыс€ч ');
    Rend := true;
    ValueTemp := Value;
    Num00;
    Result[1]:=AnsiUpperCase(Result[1])[1];
  end;
end;

procedure Fst(S: string; Var  S1: string; Var  S2: string; Var  S3: string);
var
  pos: integer;
begin
  S1 := '';
  S2 := '';
  S3 := '';

  pos := 1;

  while ((pos <= Length(S)) and (S[pos] <> ';'))do
  begin
    S1 := S1 + S[pos];
    inc(pos);
  end;
  inc(pos);

  while ((pos <= Length(S)) and (S[pos] <> ';'))do
  begin
    S2 := S2 + S[pos];
    inc(pos);
  end;
  inc(pos);

  while ((pos <= Length(S)) and (S[pos] <> ';'))do
  begin
    S3 := S3 + S[pos];
    inc(pos);
  end;
end;

function Ruble(Value: int64; Skl: string=''): string;
var
  hk10, hk20: integer;
  Skl1,Skl2,Skl3: string;
begin
  Skl1:='рубль';
  Skl2:='рубл€';
  Skl3:='рублей';
  hk10 := Value mod 10;
  hk20 := Value mod 100;
  if (hk20 > 10) and (hk20 < 20) then result := result + Skl3
  else if (hk10 = 1) then result := result + Skl1
  else if (hk10 > 1) and (hk10 < 5) then result := result + Skl2
  else result := result + Skl3;
end;

function Kopeika(Value: integer; Skp: string=''): string;
var
  hk10, hk20: integer;
  Skp1,Skp2,Skp3: string;
begin
  Result:=RightStr(IntToStr(100+Value),2)+' ';
  Skp1:='копейка';
  Skp2:='копейки';
  Skp3:='копеек';
  hk10 := Value mod 10;
  hk20 := Value mod 100;
  if (hk20 > 10) and (hk20 < 20) then result := result + Skp3
  else if (hk10 = 1) then result := result + Skp1
  else if (hk10 > 1) and (hk10 < 5) then result := result + Skp2
  else result := result + Skp3;
end;

function SummaPropis(S: ansistring): string;
var  R, K: integer; V: Integer;
begin
  S := StringReplace(S, '.', '', [rfReplaceAll]);
  S := StringReplace(S, #$A0, '', [rfReplaceAll]);
  S := StringReplace(S, ' ', '', [rfReplaceAll]);
  S := StringReplace(S, ',', '', [rfReplaceAll]);
  V := StrToIntDef(S, 0);
  R := (V div 100);
  K := (V mod 100);
  Result := Propis(R) + Ruble(R) + ' ' + Kopeika(K);
end;

function IfThen(B: Boolean; Vt, Vf: variant): Variant;
begin
  if B then Result := Vt else Result := Vf;
end;

function DatePropis(Value: TDateTime): string;
var D, M, Y: word; S: string;
begin
  DecodeDate(Value, Y, M, D);
  S := LowerCase(FormatSettings.LongMonthNames[1]);
  if M in [3,8] then S := S + 'а' else S := LeftStr(S, Length(S)-1) + '€';
  Result := Format('%2d %s %d', [D, S, Y]);
end;

function IsNull(A,B:variant):variant;
begin
  if VarIsNull(A) then Result := B else Result := A;
end;

function AsVar(Rec: Olevariant; Fld: variant): Variant;
begin
  If Rec.EOF then
    Result := Null
  else if VarType(Fld) in [varByte, varInteger, varShortInt] then
    Result := Rec.Fields[integer(Fld)].Value
  else
    Result := Rec.Fields[string(Fld)].Value;
  if tVarData(Result).VType = 8209 then
    tVarData(Result).VType := varUInt32
  else if tVarData(Result).VType=14 then
  begin
    if TDecimal(Result).Scale = 0 then
      tVarData(Result).VType := varInt64
    else
      Result := RoundTo(Power10(TDecimal(Result).Lo64, -TDecimal(Result).scale), -TDecimal(Result).scale);
  end;
end;

function AsBin(Rec: Olevariant; Fld: variant): int64;
var V: Variant;
begin
  V := Rec.Fields[integer(Fld)].Value;
  Result := 0;
  Move(tVarData(V).VArray.Data^, Result, tVarData(V).VArray.Bounds[0].ElementCount);
end;

function AsInt(Rec: Olevariant; Fld: variant): Integer;
begin
  If Rec.EOF then Result := 0 else Result := isnull(AsVar(Rec, Fld),0);
end;

function AsStr(Rec: Olevariant; Fld: variant): AnsiString;
begin
  If Rec.EOF then Result := '' else Result := isnull(AsVar(Rec, Fld),'');
end;

function AsBol(Rec: Olevariant; Fld: variant): Boolean;
begin
  If Rec.EOF then Result := False else Result := isnull(AsVar(Rec, Fld),false);
end;

function AsDat(Rec: Olevariant; Fld: variant): TDateTime;
begin
  If Rec.EOF then Result := 0 else Result := isnull(AsVar(Rec, Fld), 0);
end;

function AsExt(Rec: Olevariant; Fld: variant): Extended;
begin
  If Rec.EOF then Result := 0 else Result := isnull(AsVar(Rec, Fld),0);
end;

function IntToDate(Rec: Olevariant; Fld: variant): AnsiString;
var V: AnsiString;
begin
  Result := '';
  If Rec.EOF then Exit;
  V := isnull(AsStr(Rec, Fld), '');
  if Length(V)<>8 then Exit;
  Result := Copy(V, 7, 2) + '.' + Copy(V, 5, 2) + '.' + Copy(V, 1, 4);
end;

function NewRecordset(SQL: string; P: string): Variant;
begin
  SQL := 'declare @docid int = ' + P + #13#10 + SQL;
  fCon.CommandTimeout := 30000;
  Result := fCon.Execute(SQL);
end;

function ExecuteSQL(SQL: string; P: string): Variant;
begin
  Result := fCon.Execute(SQL);
end;

function GetPicture(PictID: integer): variant;
var
fTemp:	pChar;
V: 		variant;
L:		integer;
begin
  Result := 'Error';
  V := fCon.Execute('select data from spr_blob where tid=1 and lid=' + PictID.AsStr).Fields[0].Value;
  if V=Null then Exit;
  GetMem(fTemp, 1000);
  Windows.GetEnvironmentVariable('TEMP', fTemp, 1000);
  Result := fTemp + '\temp.jpg';
  with TFileStream.Create(Result, fmCreate) do
  try
    if tVarData(V).VArray.Bounds[0].ElementCount=0 then Exit;
    L := TVarData(V).VArray.Bounds[0].ElementCount;
    Write(TVarData(V).VArray.Data^, L);
  finally
    FreeMem(fTemp, 1000);
    Free;
  end;
end;

function IIFEx(A: boolean; B, C: variant): variant;
begin
  if A then Result := B else Result := C;
end;

function Replace(A, B, C: string): string;
begin
  Result := ReplaceStr(A, B, C);
end;

procedure InitFunctions(Script: tfsScript);
begin
  Script.AddMethod('function GetParam(Sum:string):string', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function SummaPropis(Sum:string):string', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function Propis(Sum:integer):string', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function DatePropis(Date:TDateTime):string',  txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function AsVar(Rec: variant; Fld: variant):variant', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function AsBin(Rec: variant; Fld: variant):int64', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function AsInt(Rec: variant; Fld: variant):integer', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function AsStr(Rec: variant; Fld: variant):string', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function AsBol(Rec: variant; Fld: variant):boolean', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function AsDat(Rec: variant; Fld: variant):tDateTime', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function AsExt(Rec: variant; Fld: variant):extended', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function IntToDate(Rec: variant; Fld: variant):extended', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function NewRecordset(SQL: string; Param: integer):OleVariant', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function ExecuteSQL(SQL: string; Param: integer):OleVariant', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function StrToFloatDef(Str: string; DefValue: extended):extended', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function IsNull(A, B: variant): variant', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function DataOpen(M, I, P, O: integer): boolean', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function DataNext(M: integer): boolean', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function Data(M: integer; P: string): variant', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function DataEx(M: integer; P: string): variant', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function DataInt(M: Integer; P: string): variant', txUDFClass.DoUserFunction, 'ctFormat');
  Script.AddMethod('function Replace(Str, From, To: string): variant', txUDFClass.DoUserFunction, 'ctString');
  Script.AddMethod('function IIF(A: boolean; B, C: variant): variant', txUDFClass.DoUserFunction, 'ctString');
  Script.AddMethod('function Period(DateFrom, DateTo: tDateTime): variant', txUDFClass.DoUserFunction, 'ctString');
  Script.AddMethod('function GetPicture(PictID: variant): variant', txUDFClass.DoUserFunction, 'ctString');
end;

{ txUDFClass }

class function txUDFClass.DoUserFunction(Instance: TObject; ClassType: TClass; const MethodName: String; var Params: Variant): Variant;
begin
  If MethodName = 'SUMMAPROPIS' then Result := SummaPropis(Params[0]);
  If MethodName = 'PROPIS' then Result := Propis(Params[0]);
  If MethodName = 'DATEPROPIS' then Result := DatePropis(Params[0]);
  If MethodName = 'ASVAR' then Result := AsVar(Params[0], Params[1]);
  If MethodName = 'ASBIN' then Result := AsBin(Params[0], Params[1]);
  If MethodName = 'ASINT' then Result := AsInt(Params[0], Params[1]);
  If MethodName = 'ASSTR' then Result := AsStr(Params[0], Params[1]);
  If MethodName = 'ASBOL' then Result := AsBol(Params[0], Params[1]);
  If MethodName = 'ASDAT' then Result := AsDat(Params[0], Params[1]);
  If MethodName = 'ASEXT' then Result := AsExt(Params[0], Params[1]);
  If MethodName = 'NEWRECORDSET' then Result := NewRecordset(Params[0], Params[1]);
  If MethodName = 'EXECUTESQL' then Result := ExecuteSQL(Params[0], Params[1]);
  If MethodName = 'STRTOFLOATDEF' then Result := StrToFloatDef(Trim(Params[0]), Params[1]);
  If MethodName = 'ISNULL' then Result := IsNull(Params[0], Params[1]);
  If MethodName = 'REPLACE' then Result := Replace(Params[0], Params[1], Params[2]);
  If MethodName = 'INTTODATE' then Result := IntToDate(Params[0], Params[1]);
  If MethodName = 'IIF' then Result := IIFEx(Params[0], Params[1], Params[2]);
  If MethodName = 'PERIOD' then Result := Period(Params[0], Params[1]);
  If MethodName = 'GETPICTURE' then Result := GetPicture(Params[0]);
end;

end.

