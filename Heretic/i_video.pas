//------------------------------------------------------------------------------
//
//  DelphiHeretic: A modified and improved Heretic port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2007 by Jim Valavanis
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
//------------------------------------------------------------------------------
//  E-Mail: jimmyvalavanis@yahoo.gr
//  Site  : http://delphidoom.sitesled.com/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_video;

interface

uses
  SysUtils,
  Windows,
  d_delphi;

// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// $Id:$
//
// Copyright (C) 1993-1996 by id Software, Inc.
//
// This source is available for distribution and/or modification
// only under the terms of the DOOM Source Code License as
// published by id Software. All rights reserved.
//
// The source is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License
// for more details.
//
// DESCRIPTION:
//  System specific interface stuff.
//  DirectX DOOM graphics
//
//-----------------------------------------------------------------------------

// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
procedure I_InitGraphics;

procedure I_ChangeFullScreen;

procedure I_ShutDownGraphics;

// Takes full 8 bit values.
procedure I_SetPalette(const palette: PByteArray);

procedure I_FinishUpdate;

procedure I_ReadScreen32(dest: pointer);

procedure I_RestoreWindowPos;

var
  fixstallhack: boolean = true;

implementation

uses
  doomdef,
  DirectX,
  i_system, i_main,
  r_hires,
  v_data, v_video;

var
  g_pDD: IDirectDraw7 = nil; // DirectDraw object
  g_pDDSPrimary: IDirectDrawSurface7 = nil;// DirectDraw primary surface
  g_pDDScreen: IDirectDrawSurface7 = nil;   // DirectDraw surface

var
  bpp: integer;

var
  s_alttab_disabled: boolean = false;

var
  screen16: PWordArray;
  screen: PLongWordArray;
  oscreen: pointer;

procedure I_RestoreWindowPos;
begin
  SetWindowPos(hMainWnd, HWND_TOP, 0, 0, SCREENWIDTH, SCREENHEIGHT, SWP_SHOWWINDOW);
end;

procedure I_DisableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
    Exit;

  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if isLibrary then
      RegisterHotKey(0, $C000, MOD_ALT, VK_TAB)
    else
      RegisterHotKey(0, 0, MOD_ALT, VK_TAB)
  end
  else
    SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @old, 0);

  s_alttab_disabled := true;
end;

procedure I_EnableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
  begin
    if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
      if isLibrary then
        UnregisterHotKey(0, $C000)
      else
        UnregisterHotKey(0, 0)
    end
    else
      SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @old, 0);

    s_alttab_disabled := false;
  end;
end;

var
  allocscreensize: integer;

procedure I_ShutDownGraphics;
begin
  I_ClearInterface(IInterface(g_pDDScreen));
  I_ClearInterface(IInterface(g_pDDSPrimary));
  I_ClearInterface(IInterface(g_pDD));
  I_EnableAltTab;
  memfree(oscreen, allocscreensize);
  if screen16 <> nil then
    memfree(pointer(screen16), SCREENWIDTH * SCREENHEIGHT * 2);
end;

var
  stallhack: boolean;

type
  finishupdateparms_t = record
    start, stop: integer;
  end;
  Pfinishupdateparms_t = ^finishupdateparms_t;

//
// I_FinishUpdate
//
procedure I_FinishUpdate8(parms: Pfinishupdateparms_t);
var
  dest: PLongWord;
  destw: PWord;
  pixel: LongWord;
  r, g, b: LongWord;
  src: PByte;
  srcstop: PByte;
begin
  src := @(screens[SCN_FG][parms.start]);
  srcstop := @(screens[SCN_FG][parms.stop]);
  if bpp = 32 then
  begin
    dest := @screen[parms.start];
    while integer(src) < integer(srcstop) do
    begin
      dest^ := curpal[src^];
      inc(dest);
      inc(src);
    end;
  end
  else if bpp = 16 then
  begin
    destw := @screen16[parms.start];
    while integer(src) < integer(srcstop) do
    begin
      pixel := curpal[src^];
      r := (pixel shr 19) and 31;
      g := (pixel shr 11) and 31;
      b := (pixel shr 3) and 31;
      destw^ := (r shl 11) or (g shl 6) or b;
      inc(destw);
      inc(src);
    end;
  end;
end;

function I_Thr_FinishUpdate8(parms: pointer): integer; stdcall;
begin
  I_FinishUpdate8(Pfinishupdateparms_t(parms));
  result := 0;
end;

procedure I_FinishUpdate16;
var
  i: integer;
  destw: PWord;
  pixel: LongWord;
  r, g, b: LongWord;
  srcl: PLongWord;
begin
  destw := @screen16[0];
  srcl := @screen[0];
  for i := 0 to SCREENWIDTH * SCREENHEIGHT - 1 do
  begin
    pixel := srcl^;
    r := (pixel shr 19) and 31;
    g := (pixel shr 11) and 31;
    b := (pixel shr 3) and 31;
    destw^ := (r shl 11) or (g shl 6) or b;
    inc(destw);
    inc(srcl);
  end;
end;

procedure I_FinishUpdate;
var
  srcrect: TRect;
  destrect: TRect;
  h1: integer;
  parms1, parms2: finishupdateparms_t;
  stretch: boolean;
begin
  if (hMainWnd = 0) or (screens[SCN_FG] = nil) or (screen32 = nil) then
    exit;

  if videomode = vm32bit then
  begin
    if bpp = 16 then
    begin
    // JVAL
    // Internal DelphiDoom hi-color rendering engine works in 32 bits
    // If we have a 16 bit depth desktop we get a bit slower performance ....
      I_FinishUpdate16;
    end;
    // if bpp = 32 <- we don't do nothing, directly drawing was performed
  end
  else
  begin
    parms1.start := 0;
    if usemultithread then
    begin
      parms1.stop := SCREENWIDTH * SCREENHEIGHT div 2;
      parms2.start := parms1.stop + 1;
      parms2.stop := SCREENWIDTH * SCREENHEIGHT - 1;
      h1 := I_CreateProcess(@I_Thr_FinishUpdate8, @parms2);
      I_FinishUpdate8(@parms1);
      I_WaitForProcess(h1);
    end
    else
    begin
      parms1.stop := SCREENWIDTH * SCREENHEIGHT - 1;
      I_FinishUpdate8(@parms1);
    end;
  end;

  srcrect.Left := 0;
  srcrect.Top := 0;
  srcrect.Right := SCREENWIDTH;
  srcrect.Bottom := SCREENHEIGHT;

  stretch := stallhack and fixstallhack and (WINDOWHEIGHT = SCREENHEIGHT);
  if not stretch then
    stretch := (WINDOWWIDTH <> SCREENWIDTH) or (WINDOWHEIGHT <> SCREENHEIGHT);
  if stretch then
  begin
    destrect.Left := 0;
    destrect.Top := 0;
    destrect.Right := WINDOWWIDTH;
    destrect.Bottom := WINDOWHEIGHT;

    if g_pDDSPrimary.Blt(destrect, g_pDDScreen, srcrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
      g_pDDSPrimary.Restore;

  end
  else
  begin
    if g_pDDSPrimary.BltFast(0, 0, g_pDDScreen, srcrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY) = DDERR_SURFACELOST then
      g_pDDSPrimary.Restore;
  end;
end;

//
// Palette stuff.
//

//
// I_SetPalette
//
procedure I_SetPalette(const palette: PByteArray);
var
  dest: PLongWord;
  src: PByteArray;
  curgamma: PByteArray;
begin
  dest := @curpal[0];
  src := palette;
  curgamma := @gammatable[usegamma];
  while integer(src) < integer(@palette[256 * 3]) do
  begin
    dest^ := (LongWord(curgamma[src[0]]) shl 16) or
             (LongWord(curgamma[src[1]]) shl 8) or
             (LongWord(curgamma[src[2]]));
    inc(dest);
    src := PByteArray(integer(src) + 3);
  end;
end;

function I_AdjustWindowMode: boolean;
begin
  result := false;
  if SCREENWIDTH > GetSystemMetrics(SM_CXSCREEN) then
  begin
    SCREENWIDTH := GetSystemMetrics(SM_CXSCREEN);
    result := true;
  end;
  if SCREENHEIGHT > GetSystemMetrics(SM_CYSCREEN) then
  begin
    SCREENHEIGHT := GetSystemMetrics(SM_CYSCREEN);
    result := true;
  end;
end;

function I_MemoryStallHack: boolean;
// JVAL: Memory stall can dramatically reduce performance in inc operation of
// esi register of value 4096 etc
// e.g.
//  mov [esp], 4096 (=SCREENWIDTH(=1024) * SizeOf(LongWord)(=4)
//  add esi, [esp]
// The above code is dramatically slower than:
//  mov [esp], 4088 (=SCREENWIDTH(=1022) * SizeOf(LongWord)(=4)
//  add esi, [esp]
// It's crazy!
begin
  if (SCREENWIDTH = 1024) or (SCREENWIDTH = 1152) or (SCREENWIDTH = 1280) then
  begin
    dec(SCREENWIDTH, 2);
    stallhack := true;
  end
  else
    stallhack := false;
  result := stallhack;
end;

const
  ERROR_OFFSET = 20;

// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
procedure I_InitGraphics;
var
  hres: HRESULT;
  ddsd: DDSURFACEDESC2;

  procedure I_ErrorInitGraphics(const procname: string);
  begin
    I_Error('I_InitGraphics(): %s failed, result = %d', [procname, hres]);
  end;

begin
  if g_pDD <> nil then
    exit;

  ShowWindow(hMainWnd, SW_SHOW);
  UpdateWindow(hMainWnd);

  printf('I_InitGraphics: Initialize directdraw.' + #13#10);

///////////////////////////////////////////////////////////////////////////
// Create the main DirectDraw object
///////////////////////////////////////////////////////////////////////////
  hres := DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);
  if hres <> DD_OK then
    I_ErrorInitGraphics('DirectDrawCreateEx');

  if fullscreen then
  begin
    // Get exclusive mode
    hres := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_ALLOWMODEX or DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
    if hres <> DD_OK then
      I_ErrorInitGraphics('SetCooperativeLevel');

    // Set the video mode to SCREENWIDTH x SCREENHEIGHT x 32
    hres := g_pDD.SetDisplayMode(SCREENWIDTH, SCREENHEIGHT, 32, 0, 0);
    if hres <> DD_OK then
    begin
    // Fullscreen mode failed, trying window mode
      fullscreen := false;

      I_RestoreWindowPos;

      printf('SetDisplayMode(): Failed to fullscreen %dx%dx%d, trying window mode...'#13#10,
        [SCREENWIDTH, SCREENHEIGHT, 32]);
      if I_AdjustWindowMode then
        V_ReInit;
      printf('Window Mode %dx%d' + #13#10, [SCREENWIDTH, SCREENHEIGHT]);

      hres := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_NORMAL);
      if hres <> DD_OK then
      begin
        printf('SetDisplayMode(): Failed to window mode %dx%d...' + #13#10, [SCREENWIDTH, SCREENHEIGHT]);
        SCREENWIDTH := 640;
        SCREENHEIGHT := 480;
        V_ReInit;
        hres := g_pDD.SetDisplayMode(SCREENWIDTH, SCREENHEIGHT, 32, 0, 0);
        if hres <> DD_OK then
          I_ErrorInitGraphics('SetDisplayMode');
        printf('SetDisplayMode(): %dx%d...'#13#10, [SCREENWIDTH, SCREENHEIGHT]);
      end;
    end
    else
      I_DisableAltTab;
  end
  else
  begin
    if I_AdjustWindowMode then
      V_ReInit;
    I_RestoreWindowPos;
    hres := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_NORMAL);
    if hres <> DD_OK then
      I_ErrorInitGraphics('SetCooperativeLevel');
  end;

  WINDOWWIDTH := SCREENWIDTH;
  WINDOWHEIGHT := SCREENHEIGHT;
  if I_MemoryStallHack then
    V_ReInit;

  ZeroMemory(@ddsd, SizeOf(ddsd));
  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_VIDEOMEMORY;
  hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
  if hres <> DD_OK then
  begin
    I_Warning('I_InitGraphics(): Usage of video memory failed, trying system memory.'#13#10);
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
    hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
    if hres <> DD_OK then
      I_ErrorInitGraphics('CreateSurface');
  end;


  ZeroMemory(@ddsd, SizeOf(ddsd));
  ZeroMemory(@ddsd.ddpfPixelFormat, SizeOf(ddsd.ddpfPixelFormat));

  ddsd.ddpfPixelFormat.dwSize := SizeOf(ddsd.ddpfPixelFormat);
  g_pDDSPrimary.GetPixelFormat(ddsd.ddpfPixelFormat);

  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_WIDTH or DDSD_HEIGHT or DDSD_LPSURFACE or
                  DDSD_PITCH or DDSD_PIXELFORMAT or DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;

  bpp := ddsd.ddpfPixelFormat.dwRGBBitCount;

  ddsd.dwWidth := SCREENWIDTH;
  ddsd.dwHeight := SCREENHEIGHT;

  if bpp = 32 then
  begin
    ddsd.lPitch := 4 * SCREENWIDTH; // Display is true color
    screen16 := nil;
  end
  else if bpp = 16 then
  begin
    ddsd.lPitch := 2 * SCREENWIDTH;
    screen16 := malloc(SCREENWIDTH * SCREENHEIGHT * 2);
    I_Warning('I_InitGraphics(): using 16 bit color depth desktop in non fullscreen mode reduces performance'#13#10);
  end
  else
    I_Error('I_InitGraphics(): invalid colordepth = %d, only 16 and 32 bit color depth allowed', [bpp]);

  allocscreensize := SCREENWIDTH * (SCREENHEIGHT + ERROR_OFFSET) * SizeOf(LongWord) and not (4095);
  screen := mallocA(allocscreensize, $10000, oscreen); // JVAL: Memory padding may increase performance until 4%
  screen32 := screen;

  if bpp = 16 then
    ddsd.lpSurface := screen16
  else
    ddsd.lpSurface := screen32;

  hres := g_pDD.CreateSurface(ddsd, g_pDDScreen, nil);
  if hres <> DD_OK then
    I_ErrorInitGraphics('CreateSurface');
end;

const
  NUNSTDRESOLUTIONS = 8;
  STANDARDSCREENRESOLUTIONS: array[0..NUNSTDRESOLUTIONS - 1, 0..1] of integer = (
    (1280, 1024), (1280, 800), (1024, 768), (800, 600), (640, 480), (512, 384), (400, 300), (320, 200)
  );

procedure I_ChangeFullScreen;

  procedure I_ChangeFullScreenError(full: boolean);
  begin
    if full then
      I_Warning('I_ChangeFullScreen(): Can not change to fullscreen mode'#13#10)
    else
      I_Warning('I_ChangeFullScreen(): Can not change to window mode'#13#10);
  end;

var
  hres: HRESULT;
  ddsd: DDSURFACEDESC2;
  i: integer;

begin
  if fullscreen then
  begin
    hres := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_NORMAL);
    if hres <> DD_OK then
    begin
      I_ChangeFullScreenError(false);
      exit;
    end;
  end
  else
  begin
    hres := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
    if hres <> DD_OK then
    begin
      I_ChangeFullScreenError(true);
      exit;
    end;
  end;

  WINDOWWIDTH := SCREENWIDTH;
  WINDOWHEIGHT := SCREENHEIGHT;

  hres := g_pDD.SetDisplayMode(WINDOWWIDTH, WINDOWHEIGHT, 32, 0, 0);
  if hres <> DD_OK then
  begin

    i := 0;

    // Determine a standard screen resolution
    WINDOWWIDTH := STANDARDSCREENRESOLUTIONS[NUNSTDRESOLUTIONS - 1, 0];
    WINDOWHEIGHT := STANDARDSCREENRESOLUTIONS[NUNSTDRESOLUTIONS - 1, 1];
    while i < NUNSTDRESOLUTIONS - 1 do
    begin
      if (SCREENWIDTH <= STANDARDSCREENRESOLUTIONS[i, 0]) and
         (SCREENHEIGHT <= STANDARDSCREENRESOLUTIONS[i, 1]) and
         (SCREENWIDTH >= STANDARDSCREENRESOLUTIONS[i + 1, 0]) then
      begin
        WINDOWWIDTH := STANDARDSCREENRESOLUTIONS[i, 0];
        WINDOWHEIGHT := STANDARDSCREENRESOLUTIONS[i, 1];
        break;
      end;
      inc(i);
    end;

    hres := g_pDD.SetDisplayMode(WINDOWWIDTH, WINDOWHEIGHT, 32, 0, 0);
    if hres <> DD_OK then
    begin
      I_ChangeFullScreenError(fullscreen);
      // Restore original window state
      if fullscreen then
        g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN)
      else
        g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_NORMAL);
      exit;
    end;
  end;

//  I_ClearInterface(IInterface(g_pDDSPrimary));
//  I_ClearInterface(IInterface(g_pDD));

  if fullscreen then
  begin
    g_pDD.RestoreDisplayMode;
    I_RestoreWindowPos;
    WINDOWWIDTH := SCREENWIDTH;
    WINDOWHEIGHT := SCREENHEIGHT;
  end;
  fullscreen := not fullscreen;

  ZeroMemory(@ddsd, SizeOf(ddsd));
  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_VIDEOMEMORY;
  hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
  if hres <> DD_OK then
  begin
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
    hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
    if hres <> DD_OK then
      I_Error('I_ChangeFullScreen(): CreateSurface failed');
  end;

  ZeroMemory(@ddsd, SizeOf(ddsd));
  ZeroMemory(@ddsd.ddpfPixelFormat, SizeOf(ddsd.ddpfPixelFormat));

  ddsd.ddpfPixelFormat.dwSize := SizeOf(ddsd.ddpfPixelFormat);
  g_pDDSPrimary.GetPixelFormat(ddsd.ddpfPixelFormat);

  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_WIDTH or DDSD_HEIGHT or DDSD_LPSURFACE or
                  DDSD_PITCH or DDSD_PIXELFORMAT or DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;

  bpp := ddsd.ddpfPixelFormat.dwRGBBitCount;

  ddsd.dwWidth := SCREENWIDTH;
  ddsd.dwHeight := SCREENHEIGHT;

  if bpp = 32 then
  begin
    ddsd.lPitch := 4 * SCREENWIDTH; // Display is true color
    if screen16 <> nil then
      memfree(pointer(screen16), SCREENWIDTH * SCREENHEIGHT * 2);
  end
  else if bpp = 16 then
  begin
    ddsd.lPitch := 2 * SCREENWIDTH;
    if screen16 <> nil then
      screen16 := malloc(SCREENWIDTH * SCREENHEIGHT * 2);
    I_Warning('I_ChangeFullScreen(): using 16 bit color depth desktop in non fullscreen mode reduces performance'#13#10);
  end
  else
    I_Error('I_ChangeFullScreen(): invalid colordepth = %d, only 16 and 32 bit color depth allowed', [bpp]);

  if bpp = 16 then
    ddsd.lpSurface := screen16
  else
    ddsd.lpSurface := screen32;

  hres := g_pDD.CreateSurface(ddsd, g_pDDScreen, nil);
  if hres <> DD_OK then
    I_Error('I_ChangeFullScreen(): CreateSurface failed');
end;

procedure I_ReadScreen32(dest: pointer);
var
  i: integer;
  destl: PLongWord;
  src: PByte;
begin
  if videomode = vm8bit then
  begin
    src := @(screens[SCN_FG]^);
    destl := dest;
    for i := 0 to SCREENWIDTH * SCREENHEIGHT - 1 do
    begin
      destl^ := curpal[src^];
      inc(destl);
      inc(src);
    end;
  end
  else
    memcpy(dest, screen32, SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
end;

end.
