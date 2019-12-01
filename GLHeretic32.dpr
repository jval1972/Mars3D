//------------------------------------------------------------------------------
//
//  DelphiHeretic: A modified and improved Heretic port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2016 by Jim Valavanis
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
//  Site  : http://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$IFDEF FPC}
{$Error: Use you must use Delphi to compile this project. }
{$ENDIF}

{$IFNDEF OPENGL}
{$Error: This project uses opengl renderer, please define "OPENGL"}
{$ENDIF}

{$IFNDEF HERETIC}
{$Error: To compile this project you must define "HERETIC"}
{$ENDIF}

{$I Doom32.inc}
{$D Heretic to Delphi Total Conversion}

program GLHeretic32;

{$R *.RES}

uses
  FastMM4 in 'FASTMM4\FastMM4.pas',
  FastMM4Messages in 'FASTMM4\FastMM4Messages.pas',
  FastCode in 'FASTCODE\FastCode.pas',
  FastMove in 'FASTCODE\FastMove.pas',
  AnsiStringReplaceJOHIA32Unit12 in 'FASTCODE\AnsiStringReplaceJOHIA32Unit12.pas',
  AnsiStringReplaceJOHPASUnit12 in 'FASTCODE\AnsiStringReplaceJOHPASUnit12.pas',
  FastcodeAnsiStringReplaceUnit in 'FASTCODE\FastcodeAnsiStringReplaceUnit.pas',
  FastcodeCompareMemUnit in 'FASTCODE\FastcodeCompareMemUnit.pas',
  FastcodeCompareStrUnit in 'FASTCODE\FastcodeCompareStrUnit.pas',
  FastcodeCompareTextUnit in 'FASTCODE\FastcodeCompareTextUnit.pas',
  FastcodeCPUID in 'FASTCODE\FastcodeCPUID.pas',
  FastcodeFillCharUnit in 'FASTCODE\FastcodeFillCharUnit.pas',
  FastcodeLowerCaseUnit in 'FASTCODE\FastcodeLowerCaseUnit.pas',
  FastcodePatch in 'FASTCODE\FastcodePatch.pas',
  FastcodePosExUnit in 'FASTCODE\FastcodePosExUnit.pas',
  FastcodePosUnit in 'FASTCODE\FastcodePosUnit.pas',
  FastcodeStrCompUnit in 'FASTCODE\FastcodeStrCompUnit.pas',
  FastcodeStrCopyUnit in 'FASTCODE\FastcodeStrCopyUnit.pas',
  FastcodeStrICompUnit in 'FASTCODE\FastcodeStrICompUnit.pas',
  FastCodeStrLenUnit in 'FASTCODE\FastCodeStrLenUnit.pas',
  FastcodeStrToInt32Unit in 'FASTCODE\FastcodeStrToInt32Unit.pas',
  FastcodeUpperCaseUnit in 'FASTCODE\FastcodeUpperCaseUnit.pas',
  gl_clipper in 'OPENGL\gl_clipper.pas',
  gl_tex in 'OPENGL\gl_tex.pas',
  gl_defs in 'OPENGL\gl_defs.pas',
  gl_main in 'OPENGL\gl_main.pas',
  gl_misc in 'OPENGL\gl_misc.pas',
  gl_render in 'OPENGL\gl_render.pas',
  gl_sky in 'OPENGL\gl_sky.pas',
  gl_lights in 'OPENGL\gl_lights.pas',
  jpg_utils in 'JPEGLIB\jpg_utils.pas',
  jpg_comapi in 'JPEGLIB\jpg_comapi.pas',
  jpg_dapimin in 'JPEGLIB\jpg_dapimin.pas',
  jpg_dapistd in 'JPEGLIB\jpg_dapistd.pas',
  jpg_dcoefct in 'JPEGLIB\jpg_dcoefct.pas',
  jpg_dcolor in 'JPEGLIB\jpg_dcolor.pas',
  jpg_dct in 'JPEGLIB\jpg_dct.pas',
  jpg_ddctmgr in 'JPEGLIB\jpg_ddctmgr.pas',
  jpg_deferr in 'JPEGLIB\jpg_deferr.pas',
  jpg_dhuff in 'JPEGLIB\jpg_dhuff.pas',
  jpg_dinput in 'JPEGLIB\jpg_dinput.pas',
  jpg_dmainct in 'JPEGLIB\jpg_dmainct.pas',
  jpg_dmarker in 'JPEGLIB\jpg_dmarker.pas',
  jpg_dmaster in 'JPEGLIB\jpg_dmaster.pas',
  jpg_dmerge in 'JPEGLIB\jpg_dmerge.pas',
  jpg_dphuff in 'JPEGLIB\jpg_dphuff.pas',
  jpg_dpostct in 'JPEGLIB\jpg_dpostct.pas',
  jpg_dsample in 'JPEGLIB\jpg_dsample.pas',
  jpg_error in 'JPEGLIB\jpg_error.pas',
  jpg_idctasm in 'JPEGLIB\jpg_idctasm.pas',
  jpg_idctflt in 'JPEGLIB\jpg_idctflt.pas',
  jpg_idctfst in 'JPEGLIB\jpg_idctfst.pas',
  jpg_IDctRed in 'JPEGLIB\jpg_IDctRed.pas',
  jpg_lib in 'JPEGLIB\jpg_lib.pas',
  jpg_memmgr in 'JPEGLIB\jpg_memmgr.pas',
  jpg_memnobs in 'JPEGLIB\jpg_memnobs.pas',
  jpg_morecfg in 'JPEGLIB\jpg_morecfg.pas',
  jpg_quant1 in 'JPEGLIB\jpg_quant1.pas',
  jpg_quant2 in 'JPEGLIB\jpg_quant2.pas',
  mp3_SynthFilter in 'MP3LIB\mp3_SynthFilter.pas',
  mp3_Args in 'MP3LIB\mp3_Args.pas',
  mp3_BitReserve in 'MP3LIB\mp3_BitReserve.pas',
  mp3_BitStream in 'MP3LIB\mp3_BitStream.pas',
  mp3_CRC in 'MP3LIB\mp3_CRC.pas',
  mp3_Header in 'MP3LIB\mp3_Header.pas',
  mp3_Huffman in 'MP3LIB\mp3_Huffman.pas',
  mp3_InvMDT in 'MP3LIB\mp3_InvMDT.pas',
  mp3_L3Tables in 'MP3LIB\mp3_L3Tables.pas',
  mp3_L3Type in 'MP3LIB\mp3_L3Type.pas',
  mp3_Layer3 in 'MP3LIB\mp3_Layer3.pas',
  mp3_MPEGPlayer in 'MP3LIB\mp3_MPEGPlayer.pas',
  mp3_OBuffer in 'MP3LIB\mp3_OBuffer.pas',
  mp3_OBuffer_MCI in 'MP3LIB\mp3_OBuffer_MCI.pas',
  mp3_OBuffer_Wave in 'MP3LIB\mp3_OBuffer_Wave.pas',
  mp3_Player in 'MP3LIB\mp3_Player.pas',
  mp3_ScaleFac in 'MP3LIB\mp3_ScaleFac.pas',
  mp3_Shared in 'MP3LIB\mp3_Shared.pas',
  mp3_SubBand1 in 'MP3LIB\mp3_SubBand1.pas',
  mp3_SubBand2 in 'MP3LIB\mp3_SubBand2.pas',
  mp3_SubBand in 'MP3LIB\mp3_SubBand.pas',
  t_tga in 'TEXLIB\t_tga.pas',
  t_bmp in 'TEXLIB\t_bmp.pas',
  t_colors in 'TEXLIB\t_colors.pas',
  t_draw in 'TEXLIB\t_draw.pas',
  t_jpeg in 'TEXLIB\t_jpeg.pas',
  t_main in 'TEXLIB\t_main.pas',
  t_png in 'TEXLIB\t_png.pas',
  d_delphi in 'Common\d_delphi.pas',
  DirectX in 'Common\DirectX.pas',
  am_map in 'Heretic\am_map.pas',
  c_cmds in 'Base\c_cmds.pas',
  c_con in 'Base\c_con.pas',
  c_utils in 'Base\c_utils.pas',
  d_fpc in 'Base\d_fpc.pas',
  d_event in 'Base\d_event.pas',
  d_main in 'Heretic\d_main.pas',
  d_net in 'Heretic\d_net.pas',
  d_net_h in 'Base\d_net_h.pas',
  d_player in 'Heretic\d_player.pas',
  d_think in 'Base\d_think.pas',
  d_ticcmd in 'Base\d_ticcmd.pas',
  deh_main in 'Heretic\deh_main.pas',
  doomdata in 'Heretic\doomdata.pas',
  doomdef in 'Heretic\doomdef.pas',
  doomstat in 'Heretic\doomstat.pas',
  doomtype in 'Base\doomtype.pas',
  f_finale in 'Heretic\f_finale.pas',
  g_game in 'Heretic\g_game.pas',
  h_strings in 'Heretic\h_strings.pas',
  hu_lib in 'Base\hu_lib.pas',
  hu_stuff in 'Heretic\hu_stuff.pas',
  i_input in 'Base\i_input.pas',
  i_io in 'Base\i_io.pas',
  i_midi in 'Base\i_midi.pas',
  i_mp3 in 'Base\i_mp3.pas',
  i_music in 'Base\i_music.pas',
  i_net in 'Base\i_net.pas',
  i_sound in 'Base\i_sound.pas',
  i_system in 'Base\i_system.pas',
  in_stuff in 'Heretic\in_stuff.pas',
  info in 'Heretic\info.pas',
  info_h in 'Heretic\info_h.pas',
  info_rnd in 'Heretic\info_rnd.pas',
  m_argv in 'Base\m_argv.pas',
  m_base in 'Base\m_base.pas',
  m_bbox in 'Base\m_bbox.pas',
  m_cheat in 'Base\m_cheat.pas',
  m_defs in 'Heretic\m_defs.pas',
  m_fixed in 'Base\m_fixed.pas',
  m_menu in 'Heretic\m_menu.pas',
  m_misc in 'Base\m_misc.pas',
  m_rnd in 'Base\m_rnd.pas',
  m_stack in 'Base\m_stack.pas',
  m_vectors in 'Base\m_vectors.pas',
  p_ambient in 'Heretic\p_ambient.pas',
  p_ceilng in 'Heretic\p_ceilng.pas',
  p_doors in 'Heretic\p_doors.pas',
  p_enemy in 'Heretic\p_enemy.pas',
  p_extra in 'Heretic\p_extra.pas',
  p_floor in 'Heretic\p_floor.pas',
  p_inter in 'Heretic\p_inter.pas',
  p_lights in 'Heretic\p_lights.pas',
  p_local in 'Heretic\p_local.pas',
  p_map in 'Heretic\p_map.pas',
  p_maputl in 'Heretic\p_maputl.pas',
  p_mobj in 'Heretic\p_mobj.pas',
  p_mobj_h in 'Heretic\p_mobj_h.pas',
  p_plats in 'Heretic\p_plats.pas',
  p_pspr in 'Heretic\p_pspr.pas',
  p_pspr_h in 'Heretic\p_pspr_h.pas',
  p_saveg in 'Heretic\p_saveg.pas',
  p_setup in 'Heretic\p_setup.pas',
  p_sight in 'Heretic\p_sight.pas',
  p_sounds in 'Heretic\p_sounds.pas',
  p_spec in 'Heretic\p_spec.pas',
  p_switch in 'Heretic\p_switch.pas',
  p_telept in 'Heretic\p_telept.pas',
  p_terrain in 'Heretic\p_terrain.pas',
  p_tick in 'Heretic\p_tick.pas',
  p_user in 'Heretic\p_user.pas',
  r_bsp in 'Heretic\r_bsp.pas',
  r_data in 'Heretic\r_data.pas',
  r_defs in 'Heretic\r_defs.pas',
  r_draw in 'Heretic\r_draw.pas',
  r_hires in 'Base\r_hires.pas',
  r_intrpl in 'Base\r_intrpl.pas',
  r_lights in 'Base\r_lights.pas',
  r_main in 'Heretic\r_main.pas',
  r_mmx in 'Base\r_mmx.pas',
  r_plane in 'Heretic\r_plane.pas',
  r_segs in 'Heretic\r_segs.pas',
  r_sky in 'Heretic\r_sky.pas',
  r_things in 'Heretic\r_things.pas',
  rtl_types in 'Base\rtl_types.pas',
  s_sound in 'Heretic\s_sound.pas',
  sb_bar in 'Heretic\sb_bar.pas',
  sc_actordef in 'Base\sc_actordef.pas',
  sc_engine in 'Base\sc_engine.pas',
  sc_params in 'Base\sc_params.pas',
  sounds in 'Heretic\sounds.pas',
  tables in 'Base\tables.pas',
  v_data in 'Heretic\v_data.pas',
  v_video in 'Base\v_video.pas',
  w_pak in 'Base\w_pak.pas',
  w_utils in 'Base\w_utils.pas',
  w_wad in 'Base\w_wad.pas',
  z_zone in 'Base\z_zone.pas',
  z_files in 'ZLIB\z_files.pas',
  dglOpenGL in 'OPENGL\dglOpenGL.pas',
  gl_dlights in 'OPENGL\gl_dlights.pas',
  sc_tokens in 'Base\sc_tokens.pas',
  i_exec in 'Base\i_exec.pas',
  i_tmp in 'Base\i_tmp.pas',
  gl_frustum in 'OPENGL\gl_frustum.pas',
  i_startup in 'Base\i_startup.pas' {StartUpConsoleForm},
  sc_states in 'Base\sc_states.pas',
  gl_types in 'OPENGL\gl_types.pas',
  gl_models in 'OPENGL\gl_models.pas',
  gl_lightmaps in 'OPENGL\gl_lightmaps.pas',
  gl_md2 in 'OPENGL\gl_md2.pas',
  t_material in 'TEXLIB\t_material.pas',
  gl_shadows in 'OPENGL\gl_shadows.pas',
  p_adjust in 'Base\p_adjust.pas',
  w_autoload in 'Base\w_autoload.pas',
  p_common in 'Base\p_common.pas',
  r_aspect in 'Base\r_aspect.pas',
  i_threads in 'Base\i_threads.pas',
  z_memmgr in 'Base\z_memmgr.pas',
  gl_voxels in 'OPENGL\gl_voxels.pas',
  vx_base in 'Base\vx_base.pas',
  info_fnd in 'Base\info_fnd.pas',
  mt_utils in 'Base\mt_utils.pas',
  p_params in 'Base\p_params.pas',
  nd_main in 'Base\nd_main.pas',
  p_udmf in 'Base\p_udmf.pas',
  m_crc32 in 'Base\m_crc32.pas',
  am_textured in 'Base\am_textured.pas',
  m_sshot_jpg in 'Base\m_sshot_jpg.pas',
  ps_import in 'SCRIPT\ps_import.pas',
  ps_main in 'SCRIPT\ps_main.pas',
  uPSC_dateutils in 'SCRIPT\uPSC_dateutils.pas',
  uPSC_dll in 'SCRIPT\uPSC_dll.pas',
  uPSCompiler in 'SCRIPT\uPSCompiler.pas',
  uPSR_dateutils in 'SCRIPT\uPSR_dateutils.pas',
  uPSR_dll in 'SCRIPT\uPSR_dll.pas',
  uPSRuntime in 'SCRIPT\uPSRuntime.pas',
  uPSUtils in 'SCRIPT\uPSUtils.pas',
  info_common in 'Base\info_common.pas',
  sc_thinker in 'Base\sc_thinker.pas',
  m_hash in 'Base\m_hash.pas',
  p_ladder in 'Base\p_ladder.pas',
  p_3dfloors in 'Base\p_3dfloors.pas',
  r_visplanes in 'Base\r_visplanes.pas',
  r_camera in 'Base\r_camera.pas',
  p_slopes in 'Base\p_slopes.pas',
  gl_slopes in 'OPENGL\gl_slopes.pas',
  ps_proclist in 'SCRIPT\ps_proclist.pas',
  uPSPreProcessor in 'SCRIPT\uPSPreProcessor.pas',
  psi_system in 'SCRIPT\psi_system.pas',
  ddc_base in 'SCRIPT\ddc_base.pas',
  psi_globals in 'SCRIPT\psi_globals.pas',
  p_mobjlist in 'Base\p_mobjlist.pas',
  m_smartpointerlist in 'Base\m_smartpointerlist.pas',
  psi_game in 'SCRIPT\psi_game.pas',
  ps_events in 'SCRIPT\ps_events.pas',
  ps_serializer in 'SCRIPT\ps_serializer.pas',
  psi_overlay in 'SCRIPT\psi_overlay.pas',
  r_earthquake in 'Base\r_earthquake.pas',
  p_affectees in 'Base\p_affectees.pas';

var
  Saved8087CW: Word;

begin
  { Save the current FPU state and then disable FPU exceptions }
  Saved8087CW := Default8087CW;
  Set8087CW($133f); { Disable all fpu exceptions }

  D_DoomMain;

  { Reset the FPU to the previous state }
  Set8087CW(Saved8087CW);

end.
