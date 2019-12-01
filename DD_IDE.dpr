program DD_IDE;

{$D DelphiDoom Script IDE}

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
  Forms,
  main in 'DD_IDE\main.pas' {Form1},
  ide_baseframe in 'DD_IDE\ide_baseframe.pas',
  ide_binary in 'DD_IDE\ide_binary.pas',
  ide_project in 'DD_IDE\ide_project.pas',
  ide_undo in 'DD_IDE\ide_undo.pas',
  ide_utils in 'DD_IDE\ide_utils.pas',
  zlibpas in 'DD_IDE\zlibpas.pas',
  SynEdit in 'DD_IDE\SynEdit\SynEdit.pas',
  SynEditHighlighter in 'DD_IDE\SynEdit\SynEditHighlighter.pas',
  SynEditHighlighterOptions in 'DD_IDE\SynEdit\SynEditHighlighterOptions.pas',
  SynEditKbdHandler in 'DD_IDE\SynEdit\SynEditKbdHandler.pas',
  SynEditKeyCmds in 'DD_IDE\SynEdit\SynEditKeyCmds.pas',
  SynEditKeyConst in 'DD_IDE\SynEdit\SynEditKeyConst.pas',
  SynEditMiscClasses in 'DD_IDE\SynEdit\SynEditMiscClasses.pas',
  SynEditMiscProcs in 'DD_IDE\SynEdit\SynEditMiscProcs.pas',
  SynEditStrConst in 'DD_IDE\SynEdit\SynEditStrConst.pas',
  SynEditTextBuffer in 'DD_IDE\SynEdit\SynEditTextBuffer.pas',
  SynEditTypes in 'DD_IDE\SynEdit\SynEditTypes.pas',
  SynEditWordWrap in 'DD_IDE\SynEdit\SynEditWordWrap.pas',
  SynHighlighterMulti in 'DD_IDE\SynEdit\SynHighlighterMulti.pas',
  SynRegExpr in 'DD_IDE\SynEdit\SynRegExpr.pas',
  SynTextDrawer in 'DD_IDE\SynEdit\SynTextDrawer.pas',
  SynUnicode in 'DD_IDE\SynEdit\SynUnicode.pas',
  SynHighlighterActorDef in 'DD_IDE\SynEdit\SynHighlighterActorDef.pas',
  SynHighlighterDDDisasm in 'DD_IDE\SynEdit\SynHighlighterDDDisasm.pas',
  SynEditRegexSearch in 'DD_IDE\SynEdit\SynEditRegexSearch.pas',
  SynEditSearch in 'DD_IDE\SynEdit\SynEditSearch.pas',
  SynEditPrintTypes in 'DD_IDE\SynEdit\SynEditPrintTypes.pas',
  SynEditPrint in 'DD_IDE\SynEdit\SynEditPrint.pas',
  SynEditPrinterInfo in 'DD_IDE\SynEdit\SynEditPrinterInfo.pas',
  SynEditPrintHeaderFooter in 'DD_IDE\SynEdit\SynEditPrintHeaderFooter.pas',
  SynEditPrintMargins in 'DD_IDE\SynEdit\SynEditPrintMargins.pas',
  SynEditPrintPreview in 'DD_IDE\SynEdit\SynEditPrintPreview.pas',
  SynCompletionProposal in 'DD_IDE\SynEdit\SynCompletionProposal.pas',
  frm_projectmanager in 'DD_IDE\frm_projectmanager.pas' {Frame_ProjectManager: TFrame},
  frm_scripteditor in 'DD_IDE\frm_scripteditor.pas' {Frame_ScriptEditor: TFrame},
  frm_GotoLine in 'DD_IDE\frm_GotoLine.pas' {frmGotoLine},
  ide_version in 'DD_IDE\ide_version.pas',
  ide_zipfile in 'DD_IDE\ide_zipfile.pas',
  ide_defs in 'DD_IDE\ide_defs.pas',
  frm_SearchText in 'DD_IDE\frm_SearchText.pas' {TextSearchDialog},
  frm_ReplaceText in 'DD_IDE\frm_ReplaceText.pas' {TextReplaceDialog},
  frm_ConfirmReplace in 'DD_IDE\frm_ConfirmReplace.pas' {ConfirmReplaceDialog},
  frm_message in 'DD_IDE\frm_message.pas' {frmMessage},
  ide_tmpfiles in 'DD_IDE\ide_tmpfiles.pas',
  ddc_base in 'SCRIPT\ddc_base.pas',
  frm_unitfunctions in 'DD_IDE\frm_unitfunctions.pas' {Frame_UnitFunctions: TFrame},
  frm_PageSetup in 'DD_IDE\SynEdit\frm_PageSetup.pas' {PageSetupDlg},
  frm_PrintPreview in 'DD_IDE\SynEdit\frm_PrintPreview.pas' {ScriptPrintPreviewDlg},
  frm_constants in 'DD_IDE\frm_constants.pas' {Frame_Constants: TFrame},
  frm_variables in 'DD_IDE\frm_variables.pas' {Frame_Variables: TFrame},
  frm_classes in 'DD_IDE\frm_classes.pas' {Frame_Classes: TFrame},
  frm_types in 'DD_IDE\frm_types.pas' {Frame_Types: TFrame},
  SynHighlighterDDScript in 'DD_IDE\SynEdit\SynHighlighterDDScript.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'DelphiDOOM Script IDE';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPageSetupDlg, PageSetupDlg);
  Application.CreateForm(TScriptPrintPreviewDlg, ScriptPrintPreviewDlg);
  Application.Run;
end.
