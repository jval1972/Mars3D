//------------------------------------------------------------------------------
//
//  DelphiHexen: A modified and improved Hexen port for Windows
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and on DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2011 by Jim Valavanis
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

{$IFDEF FPC}
{$Error: Use you must use Delphi to compile this project. }
{$ENDIF}

{$IFNDEF HEXEN}
{$Error: To compile this project you must define "HEXEN"}
{$ENDIF}

{$I Doom32.inc}
{$D Hexen to Delphi Total Conversion}

program Hexen32;

{$R *.RES}

uses
  FastMM4 in 'FASTMM4\FastMM4.pas',
  FastMM4Messages in 'FASTMM4\FastMM4Messages.pas',
  v_video in 'Hexen\v_video.pas',
  w_utils in 'Hexen\w_utils.pas',
  xn_defs in 'Hexen\xn_defs.pas',
  xn_strings in 'Hexen\xn_strings.pas',
  a_action in 'Hexen\a_action.pas',
  am_map in 'Hexen\am_map.pas',
  c_cmds in 'Base\c_cmds.pas',
  c_con in 'Hexen\c_con.pas',
  c_utils in 'Hexen\c_utils.pas',
  d_delphi in 'Common\d_delphi.pas',
  d_event in 'Hexen\d_event.pas',
  d_fpc in 'Hexen\d_fpc.pas',
  d_main in 'Hexen\d_main.pas',
  d_net in 'Hexen\d_net.pas',
  d_net_h in 'Hexen\d_net_h.pas',
  d_player in 'Hexen\d_player.pas',
  d_think in 'Hexen\d_think.pas',
  d_ticcmd in 'Hexen\d_ticcmd.pas',
  deh_main in 'Hexen\deh_main.pas',
  DirectX in 'Common\DirectX.pas',
  doomdata in 'Hexen\doomdata.pas',
  doomstat in 'Hexen\doomstat.pas',
  doomtype in 'Hexen\doomtype.pas',
  f_finale in 'Hexen\f_finale.pas',
  f_wipe in 'Hexen\f_wipe.pas',
  g_demo in 'Hexen\g_demo.pas',
  g_game in 'Hexen\g_game.pas',
  hu_lib in 'Hexen\hu_lib.pas',
  hu_stuff in 'Hexen\hu_stuff.pas',
  i_input in 'Hexen\i_input.pas',
  i_io in 'Base\i_io.pas',
  i_main in 'Hexen\i_main.pas',
  i_midi in 'Hexen\i_midi.pas',
  i_mp3 in 'Hexen\i_mp3.pas',
  i_music in 'Hexen\i_music.pas',
  i_net in 'Hexen\i_net.pas',
  i_sound in 'Hexen\i_sound.pas',
  i_system in 'Hexen\i_system.pas',
  i_video in 'Hexen\i_video.pas',
  in_stuff in 'Hexen\in_stuff.pas',
  info in 'Hexen\info.pas',
  info_h in 'Hexen\info_h.pas',
  info_rnd in 'Hexen\info_rnd.pas',
  jpg_utils in 'JPEGLIB\jpg_utils.pas',
  jpg_COMapi in 'JPEGLIB\jpg_comapi.pas',
  jpg_dAPImin in 'JPEGLIB\jpg_dapimin.pas',
  jpg_dAPIstd in 'JPEGLIB\jpg_dapistd.pas',
  jpg_DCoefCt in 'JPEGLIB\jpg_dcoefct.pas',
  jpg_dColor in 'JPEGLIB\jpg_dcolor.pas',
  jpg_dct in 'JPEGLIB\jpg_dct.pas',
  jpg_dDctMgr in 'JPEGLIB\jpg_ddctmgr.pas',
  jpg_defErr in 'JPEGLIB\jpg_deferr.pas',
  jpg_dHuff in 'JPEGLIB\jpg_dhuff.pas',
  jpg_dInput in 'JPEGLIB\jpg_dinput.pas',
  jpg_dMainCt in 'JPEGLIB\jpg_dmainct.pas',
  jpg_dMarker in 'JPEGLIB\jpg_dmarker.pas',
  jpg_dMaster in 'JPEGLIB\jpg_dmaster.pas',
  jpg_dMerge in 'JPEGLIB\jpg_dmerge.pas',
  jpg_dpHuff in 'JPEGLIB\jpg_dphuff.pas',
  jpg_dPostCt in 'JPEGLIB\jpg_dpostct.pas',
  jpg_dSample in 'JPEGLIB\jpg_dsample.pas',
  jpg_error in 'JPEGLIB\jpg_error.pas',
  jpg_IDctAsm in 'JPEGLIB\jpg_idctasm.pas',
  jpg_IDctFlt in 'JPEGLIB\jpg_idctflt.pas',
  jpg_IDctFst in 'JPEGLIB\jpg_idctfst.pas',
  jpg_IDctRed in 'JPEGLIB\jpg_IDctRed.pas',
  jpg_Lib in 'JPEGLIB\jpg_lib.pas',
  jpg_MemMgr in 'JPEGLIB\jpg_memmgr.pas',
  jpg_memnobs in 'JPEGLIB\jpg_memnobs.pas',
  jpg_moreCfg in 'JPEGLIB\jpg_morecfg.pas',
  jpg_Quant1 in 'JPEGLIB\jpg_quant1.pas',
  jpg_Quant2 in 'JPEGLIB\jpg_quant2.pas',
  m_argv in 'Hexen\m_argv.pas',
  m_bbox in 'Hexen\m_bbox.pas',
  m_cheat in 'Hexen\m_cheat.pas',
  m_defs in 'Hexen\m_defs.pas',
  m_fixed in 'Base\m_fixed.pas',
  m_menu in 'Hexen\m_menu.pas',
  m_misc in 'Hexen\m_misc.pas',
  m_rnd in 'Base\m_rnd.pas',
  m_stack in 'Base\m_stack.pas',
  m_vectors in 'Base\m_vectors.pas',
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
  mp3_SynthFilter in 'MP3LIB\mp3_SynthFilter.pas',
  p_acs in 'Hexen\p_acs.pas',
  p_anim in 'Hexen\p_anim.pas',
  p_ceilng in 'Hexen\p_ceilng.pas',
  p_doors in 'Hexen\p_doors.pas',
  p_enemy in 'Hexen\p_enemy.pas',
  p_extra in 'Hexen\p_extra.pas',
  p_floor in 'Hexen\p_floor.pas',
  p_inter in 'Hexen\p_inter.pas',
  p_lights in 'Hexen\p_lights.pas',
  p_local in 'Hexen\p_local.pas',
  p_map in 'Hexen\p_map.pas',
  p_maputl in 'Hexen\p_maputl.pas',
  p_mobj in 'Hexen\p_mobj.pas',
  p_mobj_h in 'Hexen\p_mobj_h.pas',
  p_plats in 'Hexen\p_plats.pas',
  p_pspr in 'Hexen\p_pspr.pas',
  p_pspr_h in 'Hexen\p_pspr_h.pas',
  p_setup in 'Hexen\p_setup.pas',
  p_sight in 'Hexen\p_sight.pas',
  p_sounds in 'Hexen\p_sounds.pas',
  p_spec in 'Hexen\p_spec.pas',
  p_switch in 'Hexen\p_switch.pas',
  p_telept in 'Hexen\p_telept.pas',
  p_terrain in 'Hexen\p_terrain.pas',
  p_things in 'Hexen\p_things.pas',
  p_tick in 'Hexen\p_tick.pas',
  p_user in 'Hexen\p_user.pas',
  po_man in 'Hexen\po_man.pas',
  r_bsp in 'Hexen\r_bsp.pas',
  r_cache in 'Hexen\r_cache.pas',
  r_camera in 'Hexen\r_camera.pas',
  r_ccache in 'Hexen\r_ccache.pas',
  r_col_al in 'Hexen\r_col_al.pas',
  r_col_av in 'Hexen\r_col_av.pas',
  r_col_fog in 'Hexen\r_col_fog.pas',
  r_col_fz in 'Hexen\r_col_fz.pas',
  r_col_l in 'Hexen\r_col_l.pas',
  r_col_ms in 'Hexen\r_col_ms.pas',
  r_col_ms_fog in 'Hexen\r_col_ms_fog.pas',
  r_col_sk in 'Hexen\r_col_sk.pas',
  r_col_tr in 'Hexen\r_col_tr.pas',
  r_column in 'Hexen\r_column.pas',
  r_data in 'Hexen\r_data.pas',
  r_defs in 'Hexen\r_defs.pas',
  r_draw in 'Hexen\r_draw.pas',
  r_fake3d in 'Hexen\r_fake3d.pas',
  r_grow in 'Hexen\r_grow.pas',
  r_hires in 'Base\r_hires.pas',
  r_intrpl in 'Hexen\r_intrpl.pas',
  r_lights in 'Hexen\r_lights.pas',
  r_main in 'Hexen\r_main.pas',
  r_mmx in 'Hexen\r_mmx.pas',
  r_plane in 'Hexen\r_plane.pas',
  r_scache in 'Hexen\r_scache.pas',
  r_segs in 'Hexen\r_segs.pas',
  r_sky in 'Hexen\r_sky.pas',
  r_skycache1 in 'Hexen\r_skycache1.pas',
  r_skycache2 in 'Hexen\r_skycache2.pas',
  r_skycache in 'Hexen\r_skycache.pas',
  r_span32 in 'Hexen\r_span32.pas',
  r_span32_fog in 'Hexen\r_span32_fog.pas',
  r_span in 'Hexen\r_span.pas',
  r_things in 'Hexen\r_things.pas',
  rtl_types in 'Hexen\rtl_types.pas',
  s_sndseq in 'Hexen\s_sndseq.pas',
  s_sound in 'Hexen\s_sound.pas',
  sb_bar in 'Hexen\sb_bar.pas',
  sc_decorate in 'Hexen\sc_decorate.pas',
  sc_engine in 'Hexen\sc_engine.pas',
  sc_params in 'Base\sc_params.pas',
  sounds in 'Hexen\sounds.pas',
  sv_save in 'Hexen\sv_save.pas',
  tables in 'Hexen\tables.pas',
  v_data in 'Hexen\v_data.pas',
  z_files in 'ZLIB\z_files.pas',
  t_tga in 'TEXLIB\t_tga.pas',
  t_bmp in 'TEXLIB\t_bmp.pas',
  t_colors in 'TEXLIB\t_colors.pas',
  t_draw in 'TEXLIB\t_draw.pas',
  t_jpeg in 'TEXLIB\t_jpeg.pas',
  t_main in 'TEXLIB\t_main.pas',
  t_png in 'TEXLIB\t_png.pas',
  z_zone in 'Base\z_zone.pas',
  w_pak in 'Base\w_pak.pas',
  w_wad in 'Base\w_wad.pas',
  i_startup in 'Base\i_startup.pas' {StartUpConsoleForm},
  t_material in 'TEXLIB\t_material.pas';

var
  Saved8087CW: Word;

begin
  { Save the current FPU state and then disable FPU exceptions }
  Saved8087CW := Default8087CW;
  Set8087CW($133f); { Disable all fpu exceptions }

  DoomMain;

  { Reset the FPU to the previous state }
  Set8087CW(Saved8087CW);

end.
