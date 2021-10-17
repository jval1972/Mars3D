//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars3D" based on DelphiDoom
//
//  Copyright (C) 1997 by Engine Technology CO. LTD
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2018 by Retro Fans of Mars3D
//  Copyright (C) 2004-2021 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit i_threads;

interface

type
  threadfunc_t = function(p: pointer): integer; stdcall;

type
  TDThread = class;

  threadinfo_t = record
    thread: TDThread;
  end;
  Pthreadinfo_t = ^threadinfo_t;

  TDThread = class
  private
    suspended: boolean;
  protected
    ffunc: threadfunc_t;
    fparms: Pointer;
    fid: Integer;
    info: threadinfo_t;
    fstatus: integer;
    fterminated: boolean;
  public
    constructor Create(const func: threadfunc_t = nil);
    destructor Destroy; override;
    procedure Activate(const parms: pointer); overload;
    procedure Activate(const func: threadfunc_t; const parms: pointer); overload;
    procedure Wait;
    function CheckJobDone: Boolean;
    function IsIdle: Boolean;
  end;

const
  THR_DEAD = 0;
  THR_ACTIVE = 1;
  THR_IDLE = 2;

implementation

uses
  Windows,
  i_system;

function ThreadWorker(p: Pointer): integer; stdcall;
var
  th: TDThread;
begin
  result := 0;
  th := Pthreadinfo_t(p).thread;
  while true do
  begin
    while (th.fstatus = THR_IDLE) and not th.fterminated do
    begin
      I_Sleep(0);
    end;
    if th.fterminated then
      exit;
    th.ffunc(th.fparms);
    if th.fterminated then
      exit;
    th.fstatus := THR_IDLE;
  end;
end;

constructor TDThread.Create(const func: threadfunc_t = nil);
begin
  fterminated := false;
  ffunc := func;
  fparms := nil;
  fstatus := THR_IDLE;
  info.thread := Self;
  fid := I_CreateProcess(@ThreadWorker, @info, true);
  suspended := true;
end;

destructor TDThread.Destroy;
begin
  fterminated := true;
  fstatus := THR_DEAD;
  I_WaitForProcess(fid, 100);
  Inherited Destroy;
end;

// JVAL: Should check for fstatus, but it is not called while active
procedure TDThread.Activate(const parms: pointer);
begin
  if not Assigned(ffunc) then
    I_Error('TDThread.Activate(): Null function pointer');
  fparms := parms;
  fstatus := THR_ACTIVE;
  suspended := false;
  ResumeThread(fid);
end;

procedure TDThread.Activate(const func: threadfunc_t; const parms: pointer);
begin
  ffunc := func;
  Activate(parms);
end;

procedure TDThread.Wait;
begin
  if suspended then
    Exit;

  while fstatus = THR_ACTIVE do
  begin
    I_Sleep(0);
  end;
  suspended := true;
  SuspendThread(fid);
end;

function TDThread.CheckJobDone: Boolean;
begin
  if fstatus = THR_IDLE then
  begin
    if not suspended then
    begin
      suspended := true;
      SuspendThread(fid);
    end;
    result := true;
  end
  else
    result := false;
end;

function TDThread.IsIdle: Boolean;
begin
  result := fstatus = THR_IDLE;
end;

end.

