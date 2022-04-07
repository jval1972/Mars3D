//------------------------------------------------------------------------------
//
//  Mars3D: A source port of the game "Mars - The Ultimate Fighter"
//
//  Copyright (C) 1997 by Engine Technology CO. LTD
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2018 by Retro Fans of Mars3D
//  Copyright (C) 2004-2022 by Jim Valavanis
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//   Notifications
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

{$I Mars3D.inc}

unit d_notifications;

interface

//==============================================================================
//
// D_NotifyVideoModeChange
//
//==============================================================================
procedure D_NotifyVideoModeChange(const newwidth, newheight: integer);

{$IFDEF OPENGL}

//==============================================================================
//
// D_NotifyGLDisplayMode
//
//==============================================================================
procedure D_NotifyGLDisplayMode;
{$ENDIF}

//==============================================================================
//
// D_RunNotifications
//
//==============================================================================
procedure D_RunNotifications;

implementation

uses
{$IFDEF OPENGL}
  gl_main
{$ELSE}
  v_displaymode
{$ENDIF}
  ;

var
  n_changevideomode: boolean = false;
  n_screenwidth: integer;
  n_screenheight: integer;
  {$IFDEF OPENGL}
  n_notifyglwindow: boolean = false;
  {$ENDIF}

//==============================================================================
//
// D_NotifyVideoModeChange
//
//==============================================================================
procedure D_NotifyVideoModeChange(const newwidth, newheight: integer);
begin
  n_changevideomode := true;
  n_screenwidth := newwidth;
  n_screenheight := newheight;
end;

{$IFDEF OPENGL}

//==============================================================================
//
// D_NotifyGLDisplayMode
//
//==============================================================================
procedure D_NotifyGLDisplayMode;
begin
  n_notifyglwindow := true;
end;
{$ENDIF}

//==============================================================================
//
// D_RunNotifications
//
//==============================================================================
procedure D_RunNotifications;
begin
  if n_changevideomode then
  begin
    {$IFDEF OPENGL}
    GL_SetDisplayMode
    {$ELSE}
    V_SetDisplayMode
    {$ENDIF}
      (n_screenwidth, n_screenheight);
    n_changevideomode := false;
  end;
  {$IFDEF OPENGL}
  if n_notifyglwindow then
  begin
    GL_NotifyDisplayMode;
    n_notifyglwindow := false;
  end;
  {$ENDIF}
end;

end.
