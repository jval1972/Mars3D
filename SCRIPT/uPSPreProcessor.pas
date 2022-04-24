unit uPSPreProcessor;
{$I PascalScript.inc}

interface

uses
  Classes, SysUtils, ps_compiler, ps_utils, ps_defs;

type
  EPSPreProcessor = class(Exception); //- jgv
  TPSPreProcessor = class;
  TPSPascalPreProcessorParser = class;

  TPSOnNeedFile = function (Sender: TPSPreProcessor;
    const callingfilename: TbtString; var FileName, Output: TbtString): Boolean;
  TPSOnProcessDirective = procedure (
                            Sender: TPSPreProcessor;
                            Parser: TPSPascalPreProcessorParser;
                            const Active: Boolean;
                            const DirectiveName, DirectiveParam: TbtString;
                            var Continue: Boolean); //- jgv - application set continue to false to stop the normal directive processing

  TPSLineInfo = class(TObject)
  private
    function GetLineOffset(I: Integer): Cardinal;
    function GetLineOffsetCount: Longint;
  protected
    FEndPos: Cardinal;
    FStartPos: Cardinal;
    FFileName: TbtString;
    FLineOffsets: TIfList;
  public
    property FileName: TbtString read FFileName;
    property StartPos: Cardinal read FStartPos;
    property EndPos: Cardinal read FEndPos;
    property LineOffsetCount: Longint read GetLineOffsetCount;
    property LineOffset[I: Longint]: Cardinal read GetLineOffset;
    constructor Create;
    destructor Destroy; override;
  end;

  TPSLineInfoResults = record
    Row: Cardinal;
    Col: Cardinal;
    Pos: Cardinal;
    Name: TbtString;
  end;

  TPSLineInfoList = class(TObject)
  private
    FItems: TIfList;
    FCurrent: Longint;
    function GetCount: Longint;
    function GetItem(I: Integer): TPSLineInfo;
  protected
    function Add: TPSLineInfo;
  public
    property Count: Longint read GetCount;
    property Items[I: Longint]: TPSLineInfo read GetItem; default;
    procedure Clear;
    function GetLineInfo(const ModuleName: TbtString; Pos: Cardinal; var Res: TPSLineInfoResults): Boolean;
    property Current: Longint read FCurrent write FCurrent;
    constructor Create;
    destructor Destroy; override;
  end;
  TPSDefineStates = class;

  TPSPreProcessor = class(TObject)
  private
    FID: Pointer;
    FCurrentDefines, FDefines: TStringList;
    FCurrentLineInfo: TPSLineInfoList;
    FOnNeedFile: TPSOnNeedFile;
    FAddedPosition: Cardinal;
    FDefineState: TPSDefineStates;
    FMaxLevel: Longint;
    FMainFileName: TbtString;
    FMainFile: TbtString;
    FOnProcessDirective: TPSOnProcessDirective;
    FOnProcessUnknowDirective: TPSOnProcessDirective;
    procedure ParserNewLine(Sender: TPSPascalPreProcessorParser; Row, Col, Pos: Cardinal);
    procedure IntPreProcess(Level: Integer; const OrgFileName: TbtString; FileName: TbtString; Dest: TStream);
  protected
    procedure doAddStdPredefines; virtual; // jgv
  public
    {The maximum number of levels deep the parser will go, defaults to 20}
    property MaxLevel: Longint read FMaxLevel write FMaxLevel;
    property CurrentLineInfo: TPSLineInfoList read FCurrentLineInfo;
    property OnNeedFile: TPSOnNeedFile read FOnNeedFile write FOnNeedFile;
    property Defines: TStringList read FDefines write FDefines;
    property MainFile: TbtString read FMainFile write FMainFile;
    property MainFileName: TbtString read FMainFileName write FMainFileName;
    property ID: Pointer read FID write FID;
    procedure AdjustMessages(Comp: TPSPascalCompiler);
    procedure AdjustMessage(Msg: TPSPascalCompilerMessage); //-jgv
    procedure PreProcess(const Filename: TbtString; var Output: TbtString);
    procedure Clear;
    constructor Create;
    destructor Destroy; override;
    property OnProcessDirective: TPSOnProcessDirective read fOnProcessDirective write fOnProcessDirective;
    property OnProcessUnknowDirective: TPSOnProcessDirective read fOnProcessUnknowDirective write fOnProcessUnknowDirective;
  end;

  TPSPascalPreProcessorType = (ptEOF, ptOther, ptDefine);

  TPSOnNewLine = procedure (Sender: TPSPascalPreProcessorParser; Row, Col, Pos: Cardinal) of object;

  TPSPascalPreProcessorParser = class(TObject)
  private
    FData: TbtString;
    FText: PAnsichar;
    FToken: TbtString;
    FTokenId: TPSPascalPreProcessorType;
    FLastEnterPos, FLen, FRow, FCol, FPos: Cardinal;
    FOnNewLine: TPSOnNewLine;
  public
    procedure SetText(const dta: TbtString);
    procedure Next;
    property Token: TbtString read FToken;
    property TokenId: TPSPascalPreProcessorType read FTokenId;
    property Row: Cardinal read FRow;
    property Col: Cardinal read FCol;
    property Pos: Cardinal read FPos;
    property OnNewLine: TPSOnNewLine read FOnNewLine write FOnNewLine;
  end;

  TPSDefineState = class(TObject)
  private
    FInElse: Boolean;
    FDoWrite: Boolean;
  public
    property InElse: Boolean read FInElse write FInElse;
    property DoWrite: Boolean read FDoWrite write FDoWrite;
  end;

  TPSDefineStates = class(TObject)
  private
    FItems: TIfList;
    function GetCount: Longint;
    function GetItem(I: Integer): TPSDefineState;
    function GetWrite: Boolean;
    function GetPrevWrite: Boolean; //JeromeWelsh - nesting fix
  public
    property Count: Longint read GetCount;
    property Item[I: Longint]: TPSDefineState read GetItem; default;
    function Add: TPSDefineState;
    procedure Delete(I: Longint);
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    property DoWrite: Boolean read GetWrite;
    property DoPrevWrite: Boolean read GetPrevWrite; //JeromeWelsh - nesting fix
  end;

implementation

uses
  d_delphi;

{$IFDEF DELPHI3UP }
resourceString
{$ELSE }
const
{$ENDIF }
  RPS_TooManyNestedInclude = 'Too many nested include files while processing ''%s'' from ''%s''';
  RPS_IncludeNotFound = 'Unable to find file ''%s'' used from ''%s''';
  RPS_DefineTooManyParameters = 'Too many parameters at %d:%d';
  RPS_NoIfdefForEndif = 'No IFDEF for ENDIF at %d:%d';
  RPS_NoIfdefForElse = 'No IFDEF for ELSE at %d:%d';
  RPS_ElseTwice = 'Can''t use ELSE twice at %d:%d';
  RPS_UnknownCompilerDirective = 'Unknown compiler directives at %d:%d';
  RPs_DefineNotClosed = 'Define not closed';

{ TPSLineInfoList }

//==============================================================================
//
// TPSLineInfoList.Add
//
//==============================================================================
function TPSLineInfoList.Add: TPSLineInfo;
begin
  Result := TPSLineInfo.Create;
  FItems.Add(Result);
end;

//==============================================================================
//
// TPSLineInfoList.Clear
//
//==============================================================================
procedure TPSLineInfoList.Clear;
var
  i: Longint;
begin
  for i := FItems.count - 1 downto 0 do
    TPSLineInfo(FItems[i]).Free;
  FItems.Clear;
end;

//==============================================================================
//
// TPSLineInfoList.Create
//
//==============================================================================
constructor TPSLineInfoList.Create;
begin
  inherited Create;
  FItems := TIfList.Create;
end;

//==============================================================================
//
// TPSLineInfoList.Destroy
//
//==============================================================================
destructor TPSLineInfoList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

//==============================================================================
//
// TPSLineInfoList.GetCount
//
//==============================================================================
function TPSLineInfoList.GetCount: Longint;
begin
  Result := FItems.Count;
end;

//==============================================================================
//
// TPSLineInfoList.GetItem
//
//==============================================================================
function TPSLineInfoList.GetItem(I: Integer): TPSLineInfo;
begin
  Result := TPSLineInfo(FItems[i]);
end;

//==============================================================================
//
// TPSLineInfoList.GetLineInfo
//
//==============================================================================
function TPSLineInfoList.GetLineInfo(const ModuleName: TbtString; Pos: Cardinal; var Res: TPSLineInfoResults): Boolean;
var
  i,j: Longint;
  linepos: Cardinal;
  Item: TPSLineInfo;
  lModuleName: TbtString;
begin
  lModuleName := FastUpperCase(ModuleName);

  for i := FItems.Count - 1 downto 0 do
  begin
    Item := FItems[i];
    if (Pos >= Item.StartPos) and (Pos < Item.EndPos) and
      (lModuleName = '') or (lModuleName = Item.FileName) then
    begin
      Res.Name := Item.FileName;
      Pos := Pos - Item.StartPos;
      Res.Pos := Pos;
      Res.Col := 1;
      Res.Row := 1;
      LinePos := 0;
      for j := 0 to Item.LineOffsetCount - 1 do
      begin
        if Pos >= Item.LineOffset[j] then
        begin
          linepos := Item.LineOffset[j];
        end
        else
        begin
          Res.Row := j; // j - 1, but line counting starts at 1
          Res.Col := pos - linepos + 1;
          Break;
        end;
      end;
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

{ TPSLineInfo }

//==============================================================================
//
// TPSLineInfo.Create
//
//==============================================================================
constructor TPSLineInfo.Create;
begin
  inherited Create;
  FLineOffsets := TIfList.Create;
end;

//==============================================================================
//
// TPSLineInfo.Destroy
//
//==============================================================================
destructor TPSLineInfo.Destroy;
begin
  FLineOffsets.Free;
  inherited Destroy;
end;

//==============================================================================
//
// TPSLineInfo.GetLineOffset
//
//==============================================================================
function TPSLineInfo.GetLineOffset(I: Integer): Cardinal;
begin
  Result := Longint(FLineOffsets[I]);
end;

//==============================================================================
//
// TPSLineInfo.GetLineOffsetCount
//
//==============================================================================
function TPSLineInfo.GetLineOffsetCount: Longint;
begin
  Result := FLineOffsets.Count;
end;

{ TPSPascalPreProcessorParser }

//==============================================================================
//
// TPSPascalPreProcessorParser.Next
//
//==============================================================================
procedure TPSPascalPreProcessorParser.Next;
var
  ci: Cardinal;
begin
  FPos := FPos + FLen;
  case FText[FPos] of
    #0:
      begin
        FLen := 0;
        FTokenId := ptEof;
      end;
    '''':
      begin
        ci := FPos;
        while (FText[ci] <> #0) do
        begin
          Inc(ci);
          while FText[ci] = '''' do
          begin
            if FText[ci+1] <> '''' then
              Break;
            inc(ci);
            inc(ci);
          end;
          if FText[ci] = '''' then
            Break;
          if FText[ci] = #13 then
          begin
            inc(FRow);
            if FText[ci] = #10 then
              inc(ci);
            FLastEnterPos := ci - 1;
            if @FOnNewLine <> nil then
              FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
            break;
          end
          else if FText[ci] = #10 then
          begin
            inc(FRow);
            FLastEnterPos := ci - 1;
            if @FOnNewLine <> nil then
              FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
            break;
          end;
        end;
        FLen := ci - FPos + 1;
        FTokenId := ptOther;
      end;
    '(':
      begin
        if FText[FPos + 1] = '*' then
        begin
          ci := FPos + 1;
          while (FText[ci] <> #0) do
          begin
            if (FText[ci] = '*') and (FText[ci + 1] = ')') then
              Break;
            if FText[ci] = #13 then
            begin
              inc(FRow);
              if FText[ci + 1] = #10 then
                inc(ci);
              FLastEnterPos := ci - 1;
              if @FOnNewLine <> nil then
                FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
            end
            else if FText[ci] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := ci - 1;
              if @FOnNewLine <> nil then
                FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
            end;
            Inc(ci);
          end;
          FTokenId := ptOther;
          if (FText[ci] <> #0) then
            Inc(ci, 2);
          FLen := ci - FPos;
        end
        else
        begin
          FTokenId := ptOther;
          FLen := 1;
        end;
      end;
      '/':
        begin
          if FText[FPos + 1] = '/' then
          begin
            ci := FPos + 1;
            while (FText[ci] <> #0) and (FText[ci] <> #13) and (FText[ci] <> #10) do
            begin
              Inc(ci);
            end;
            FTokenId := ptOther;
            FLen := ci - FPos;
          end
          else
          begin
            FTokenId := ptOther;
            FLen := 1;
          end;
        end;
      '{':
        begin
          ci := FPos + 1;
          while (FText[ci] <> #0) and (FText[ci] <> '}') do
          begin
            if FText[ci] = #13 then
            begin
              inc(FRow);
              if FText[ci + 1] = #10 then
                inc(ci);
              FLastEnterPos := ci - 1;
              if @FOnNewLine <> nil then
                FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
            end
            else if FText[ci] = #10 then
            begin
              inc(FRow);
              FLastEnterPos := ci - 1;
              if @FOnNewLine <> nil then
                FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
            end;
            Inc(ci);
          end;
          if FText[FPos + 1] = '$' then
            FTokenId := ptDefine
          else
            FTokenId := ptOther;

          FLen := ci - FPos + 1;
        end;
      else
      begin
        ci := FPos + 1;
        while not (FText[ci] in [#0,'{', '(', '''', '/']) do
        begin
          if FText[ci] = #13 then
          begin
            inc(FRow);
            if FText[ci + 1] = #10 then
              inc(ci);
            FLastEnterPos := ci - 1;
            if @FOnNewLine <> nil then
              FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
          end
          else if FText[ci] = #10 then
          begin
            inc(FRow);
            FLastEnterPos := ci - 1 ;
            if @FOnNewLine <> nil then
              FOnNewLine(Self, FRow, FPos - FLastEnterPos + 1, ci + 1);
          end;
          Inc(Ci);
        end;
        FTokenId := ptOther;
        FLen := ci - FPos;
      end;
  end;
  FCol := FPos - FLastEnterPos + 1;
  FToken := Copy(FData, FPos + 1, FLen);
end;

//==============================================================================
//
// TPSPascalPreProcessorParser.SetText
//
//==============================================================================
procedure TPSPascalPreProcessorParser.SetText(const dta: TbtString);
begin
  FData := dta;
  FText := pAnsichar(FData);
  FLen := 0;
  FPos := 0;
  FCol := 1;
  FLastEnterPos := 0;
  FRow := 1;
  if @FOnNewLine <> nil then
    FOnNewLine(Self, 1, 1, 0);
  Next;
end;

{ TPSPreProcessor }

//==============================================================================
//
// TPSPreProcessor.AdjustMessage
//
//==============================================================================
procedure TPSPreProcessor.AdjustMessage(Msg: TPSPascalCompilerMessage);
var
  Res: TPSLineInfoResults;
begin
  if CurrentLineInfo.GetLineInfo(Msg.ModuleName, Msg.Pos, Res) then
  begin
    Msg.SetCustomPos(res.Pos, Res.Row, Res.Col);
    Msg.ModuleName := Res.Name;
  end;
end;

//==============================================================================
//
// TPSPreProcessor.AdjustMessages
//
//==============================================================================
procedure TPSPreProcessor.AdjustMessages(Comp: TPSPascalCompiler);
var
  i: Longint;
begin
  for i := 0 to Comp.MsgCount - 1 do
    AdjustMessage (Comp.Msg[i]);
end;

//==============================================================================
//
// TPSPreProcessor.Clear
//
//==============================================================================
procedure TPSPreProcessor.Clear;
begin
  FDefineState.Clear;
  FDefines.Clear;
  FCurrentDefines.Clear;
  FCurrentLineInfo.Clear;
  FMainFile := '';
end;

//==============================================================================
//
// TPSPreProcessor.Create
//
//==============================================================================
constructor TPSPreProcessor.Create;
begin
  inherited Create;
  FDefines := TStringList.Create;
  FCurrentLineInfo := TPSLineInfoList.Create;
  FCurrentDefines := TStringList.Create;
  FDefines.Duplicates := dupIgnore;
  FCurrentDefines.Duplicates := dupIgnore;
  FDefineState := TPSDefineStates.Create;
  FMaxLevel := 20;

  doAddStdPredefines;
end;

//==============================================================================
//
// TPSPreProcessor.Destroy
//
//==============================================================================
destructor TPSPreProcessor.Destroy;
begin
  FDefineState.Free;
  FCurrentDefines.Free;
  FDefines.Free;
  FCurrentLineInfo.Free;
  inherited Destroy;
end;

//==============================================================================
//
// TPSPreProcessor.doAddStdPredefines
//
//==============================================================================
procedure TPSPreProcessor.doAddStdPredefines;
begin
  //--- 20050708_jgv
  FCurrentDefines.Add (Format ('VER%d', [PSCurrentBuildNo]));
  {$IFDEF CPU386 }
  FCurrentDefines.Add ('CPU386');
  {$ENDIF }
  {$IFDEF MSWINDOWS }
    FCurrentDefines.Add ('MSWINDOWS');
    FCurrentDefines.Add ('WIN32');
  {$ENDIF }
  {$IFDEF LINUX }
    FCurrentDefines.Add ('LINUX');
  {$ENDIF }
end;

//==============================================================================
//
// TPSPreProcessor.IntPreProcess
//
//==============================================================================
procedure TPSPreProcessor.IntPreProcess(Level: Integer; const OrgFileName: TbtString; FileName: TbtString; Dest: TStream);
var
  Parser: TPSPascalPreProcessorParser;
  dta: TbtString;
  item: TPSLineInfo;
  s, name: TbtString;
  current, i: Longint;
  ds: TPSDefineState;
  AppContinue: Boolean;
  ADoWrite: Boolean;
begin
  if Level > MaxLevel then
    raise EPSPreProcessor.CreateFmt(RPS_TooManyNestedInclude, [FileName, OrgFileName]);
  Parser := TPSPascalPreProcessorParser.Create;
  try
    Parser.OnNewLine := ParserNewLine;
    if FileName = MainFileName then
    begin
      dta := MainFile;
    end
    else if (@OnNeedFile = nil) or (not OnNeedFile(Self, OrgFileName, FileName, dta)) then
      raise EPSPreProcessor.CreateFmt(RPS_IncludeNotFound, [FileName, OrgFileName]);
    Item := FCurrentLineInfo.Add;
    current := FCurrentLineInfo.Count - 1;
    FCurrentLineInfo.Current := current;
    Item.FStartPos := Dest.Position;
    Item.FFileName := FileName;
    Parser.SetText(dta);
    while Parser.TokenId <> ptEOF do
    begin
      s := Parser.Token;
      if Parser.TokenId = ptDefine then
      begin
        Delete(s, 1, 2);  // delete the {$
        Delete(s, Length(s), 1); // delete the }

        //-- 20050707_jgv trim right
        i := Length(s);
        while (i > 0) and (s[i] = ' ') do
        begin
          Delete(s, i, 1);
          Dec(i);
        end;
        //-- end_jgv

        if Pos(tbtChar(' '), s) = 0 then
        begin
          name := uppercase(s);
          s := '';
        end
        else
        begin
          Name := uppercase(Copy(s, 1, CharPos(' ', s) - 1));
          Delete(s, 1, CharPos(' ', s));
        end;

        //-- 20050707_jgv - ask the application
        AppContinue := True;
        if @OnProcessDirective <> nil then OnProcessDirective (Self, Parser, FDefineState.DoWrite, name, s, AppContinue);

        if AppContinue then
        //-- end jgv

          if (Name = 'I') or (Name = 'INCLUDE') then
          begin
            if FDefineState.DoWrite then
            begin
              FAddedPosition := 0;
              IntPreProcess(Level + 1, FileName, s, Dest);
              FCurrentLineInfo.Current := current;
              FAddedPosition := Cardinal(Dest.Position) - Item.StartPos - Parser.Pos;
            end;
          end
          else if (Name = 'DEFINE') then
          begin
            if FDefineState.DoWrite then
            begin
              if CharPos(' ', s) <> 0 then
                raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [Parser.Row, Parser.Col]);
              FCurrentDefines.Add(Uppercase(S));
            end;
          end
          else if (Name = 'UNDEF') then
          begin
            if FDefineState.DoWrite then
            begin
              if CharPos(' ', s) <> 0 then
                raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [Parser.Row, Parser.Col]);
              i := FCurrentDefines.IndexOf(Uppercase(s));
              if i <> - 1 then
                FCurrentDefines.Delete(i);
            end;
          end
          else if (Name = 'IFDEF') then
          begin
            if CharPos(' ', s) <> 0 then
              raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [Parser.Row, Parser.Col]);
            //JeromeWelsh - nesting fix
            ADoWrite := (FCurrentDefines.IndexOf(Uppercase(s)) >= 0) and FDefineState.DoWrite;
            FDefineState.Add.DoWrite := ADoWrite;
          end
          else if (Name = 'IFNDEF') then
          begin
            if CharPos(' ', s) <> 0 then
              raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [Parser.Row, Parser.Col]);
            //JeromeWelsh - nesting fix
            ADoWrite := (FCurrentDefines.IndexOf(Uppercase(s)) < 0) and FDefineState.DoWrite;
            FDefineState.Add.DoWrite := ADoWrite;
          end
          else if (Name = 'ENDIF') then
          begin
            //- jgv remove - borland use it (sysutils.pas)
            //- if s <> '' then raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [Parser.Row, Parser.Col]);
            if FDefineState.Count = 0 then
              raise EPSPreProcessor.CreateFmt(RPS_NoIfdefForEndif, [Parser.Row, Parser.Col]);
            FDefineState.Delete(FDefineState.Count - 1); // remove define from list
          end
          else if (Name = 'ELSE') then
          begin
            if s<> '' then
              raise EPSPreProcessor.CreateFmt(RPS_DefineTooManyParameters, [Parser.Row, Parser.Col]);
            if FDefineState.Count = 0 then
              raise EPSPreProcessor.CreateFmt(RPS_NoIfdefForElse, [Parser.Row, Parser.Col]);
            ds := FDefineState[FDefineState.Count - 1];
            if ds.InElse then
              raise EPSPreProcessor.CreateFmt(RPS_ElseTwice, [Parser.Row, Parser.Col]);
            ds.FInElse := True;
            //JeromeWelsh - nesting fix
            ds.DoWrite := not ds.DoWrite and FDefineState.DoPrevWrite;
          end

          //-- 20050710_jgv custom application error process
          else
          begin
            If @OnProcessUnknowDirective <> Nil then
            begin
              OnProcessUnknowDirective (Self, Parser, FDefineState.DoWrite, name, s, AppContinue);
            end;
            If AppContinue then
            //-- end jgv

              raise EPSPreProcessor.CreateFmt(RPS_UnknownCompilerDirective, [Parser.Row, Parser.Col]);
          end;
      end;

      if (not FDefineState.DoWrite) or (Parser.TokenId = ptDefine) then
      begin
        SetLength(s, Length(Parser.Token));
        for i := Length(s) downto 1 do
          s[i] := #32; // space
      end;
      Dest.Write(s[1], Length(s));
      Parser.Next;
    end;
    Item.FEndPos := Dest.Position;
  finally
    Parser.Free;
  end;
end;

//==============================================================================
//
// TPSPreProcessor.ParserNewLine
//
//==============================================================================
procedure TPSPreProcessor.ParserNewLine(Sender: TPSPascalPreProcessorParser; Row, Col, Pos: Cardinal);
begin
  if FCurrentLineInfo.Current >= FCurrentLineInfo.Count then
    Exit; //errr ???
  with FCurrentLineInfo.Items[FCurrentLineInfo.Current] do
  begin
    Pos := Pos + FAddedPosition;
    FLineOffsets.Add(Pointer(Pos));
  end;
end;

//==============================================================================
//
// TPSPreProcessor.PreProcess
//
//==============================================================================
procedure TPSPreProcessor.PreProcess(const Filename: TbtString; var Output: TbtString);
var
  Stream: TMemoryStream;
begin
  FAddedPosition := 0;
  {$IFDEF FPC}
  FCurrentDefines.AddStrings(FDefines);
  {$ELSE}
  FCurrentDefines.Assign(FDefines);
  {$ENDIF}
  Stream := TMemoryStream.Create;
  try
    IntPreProcess(0, '', FileName, Stream);
    Stream.Position := 0;
    SetLength(Output, Stream.Size);
    Stream.Read(Output[1], Length(Output));
  finally
    Stream.Free;
  end;
  if FDefineState.Count <> 0 then
    raise EPSPreProcessor.Create(RPs_DefineNotClosed);
end;

{ TPSDefineStates }

//==============================================================================
//
// TPSDefineStates.Add
//
//==============================================================================
function TPSDefineStates.Add: TPSDefineState;
begin
  Result := TPSDefineState.Create;
  FItems.Add(Result);
end;

//==============================================================================
//
// TPSDefineStates.Clear
//
//==============================================================================
procedure TPSDefineStates.Clear;
var
  i: Longint;
begin
  for i := Longint(FItems.Count) - 1 downto 0 do
    TPSDefineState(FItems[i]).Free;
  FItems.Clear;
end;

//==============================================================================
//
// TPSDefineStates.Create
//
//==============================================================================
constructor TPSDefineStates.Create;
begin
  inherited Create;
  FItems := TIfList.Create;
end;

//==============================================================================
//
// TPSDefineStates.Delete
//
//==============================================================================
procedure TPSDefineStates.Delete(I: Integer);
begin
  TPSDefineState(FItems[i]).Free;
  FItems.Delete(i);
end;

//==============================================================================
//
// TPSDefineStates.Destroy
//
//==============================================================================
destructor TPSDefineStates.Destroy;
var
  i: Longint;
begin
  for i := Longint(FItems.Count) - 1 downto 0 do
    TPSDefineState(FItems[i]).Free;
  FItems.Free;
  inherited Destroy;
end;

//==============================================================================
//
// TPSDefineStates.GetCount
//
//==============================================================================
function TPSDefineStates.GetCount: Longint;
begin
  Result := FItems.Count;
end;

//==============================================================================
//
// TPSDefineStates.GetItem
//
//==============================================================================
function TPSDefineStates.GetItem(I: Integer): TPSDefineState;
begin
  Result := FItems[i];
end;

//==============================================================================
//
// TPSDefineStates.GetWrite
//
//==============================================================================
function TPSDefineStates.GetWrite: Boolean;
begin
  if FItems.Count = 0 then
    Result := True
  else
    Result := TPSDefineState(FItems[FItems.Count - 1]).DoWrite;
end;

//==============================================================================
// TPSDefineStates.GetPrevWrite
//
//JeromeWelsh - nesting fix
//
//==============================================================================
function TPSDefineStates.GetPrevWrite: Boolean;
begin
  if FItems.Count < 2 then
    Result := True
  else
    Result := TPSDefineState(FItems[FItems.Count - 2]).DoWrite;
end;

end.
