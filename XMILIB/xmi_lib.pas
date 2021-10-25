unit xmi_lib;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface    

function XMI_OpenMusicFile(const fname: string): Boolean;
function XMI_GetNumTracks: Integer;
function XMI_ConvertTrack(const trNo: integer; const fname: string): Boolean;
function XMI_PlayTrack(const trNo: integer): Boolean;
procedure XMI_StopPlayback;

implementation

uses
  SysUtils, xmi_core;

var
  XMIfile: string = '';

function XMI_OpenMusicFile(const fname: string): Boolean;
begin
  if fname = '' then
  begin
    Result := False;
    Exit;
  end;
  if not FileExists(fname) then
  begin
    Result := False;
    Exit;
  end;

  XMIfile := fname;
  Result := XMICore.LoadFile(fname, '');
  if XMICore.TrkCh.Items.Count > 0 then
  begin
    XMICore.TrkCh.ItemIndex := 0;
    XMICore.FillEvents(XMICore.TrkCh.ItemIndex);
  end;
  XMICore.ChkButtons;
end;

function XMI_GetNumTracks: integer;
begin
  Result := XMICore.TrkCh.Items.Count;
end;

function XMI_ConvertTrack(const trNo: integer; const fname: string): Boolean;
var
  Idx, I: Integer;
begin
  XMI_StopPlayback;
  Result := XMI_OpenMusicFile(XMIfile);
  if not Result then
    Exit;

  LoopEnabled := True;
  Idx := trNo;
  XMICore.TrkCh.ItemIndex := Idx;
  XMICore.FillEvents(XMICore.TrkCh.ItemIndex);
  XMICore.ChkButtons;

  for I := Length(TrackData) - 1 downto 0 do
    if I <> Idx then
      XMICore.DelTrack(I);
  XMICore.RefTrackList;
  if Length(TrackData) > 0 then
  begin
    XMICore.TrkCh.ItemIndex := 0;
    XMICore.FillEvents(XMICore.TrkCh.ItemIndex);
  end;

  XMICore.ChkButtons;
  Result := XMICore.SaveFile(fname);
end;

function XMI_PlayTrack(const trNo: integer): Boolean;
var
  Idx, I: Integer;
begin
  XMI_StopPlayback;
  Result := XMI_OpenMusicFile(XMIfile);
  if not Result then
    Exit;

  LoopEnabled := True;
  Idx := trNo;
  XMICore.TrkCh.ItemIndex := Idx;
  XMICore.FillEvents(XMICore.TrkCh.ItemIndex);
  XMICore.ChkButtons;

  for I := Length(TrackData) - 1 downto 0 do
    if I <> Idx then
      XMICore.DelTrack(I);
  XMICore.RefTrackList;
  if Length(TrackData) > 0 then
  begin
    XMICore.TrkCh.ItemIndex := 0;
    XMICore.FillEvents(XMICore.TrkCh.ItemIndex);
  end;

  XMICore.ChkButtons;
  XMICore.bPlayClick(nil);

  Result := True;
end;

procedure XMI_StopPlayback;
begin
  XMICore.bStopClick(nil);
end;

end.
