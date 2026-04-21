/**
 * 把 Sheet 4B 的「SP Full Definition」欄內容轉成「SP Name」欄的 Note，
 * 然後清掉 SP Full Definition 欄。滑鼠 hover 在 SP Name 上就能看到完整定義。
 *
 * 預期欄位順序：
 *   A: Current Database
 *   B: SP Name
 *   C: SP Created
 *   D: SP Last Modified
 *   E: SP Definition Length
 *   F: SP Full Definition
 *
 * 使用方式：
 *   1. 先把 Sheet 4B 的 SQL 結果貼到 Google Sheet
 *   2. 修改下方 SHEET_NAME 為你的工作表實際名稱
 *   3. 執行 convertSPDefinitionToNote 函式 (第一次會要授權)
 *   4. 完成後 SP Name 右上會出現黑色三角形，hover 顯示完整定義
 *
 * 若需還原，執行 restoreSPDefinitionFromNote 即可把 Note 寫回 SP Full Definition 欄。
 */

function convertSPDefinitionToNote() {
  const SHEET_NAME  = '工作表 4B';   // ← 改成你的 Sheet 4B 實際名稱
  const SP_NAME_COL = 2;            // B 欄
  const SP_DEF_COL  = 6;            // F 欄
  const HEADER_ROWS = 1;            // 標題列數量

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    SpreadsheetApp.getUi().alert('找不到工作表：' + SHEET_NAME);
    return;
  }

  const lastRow = sheet.getLastRow();
  if (lastRow <= HEADER_ROWS) {
    SpreadsheetApp.getUi().alert('沒有資料列');
    return;
  }

  const numRows = lastRow - HEADER_ROWS;

  const nameRange = sheet.getRange(HEADER_ROWS + 1, SP_NAME_COL, numRows, 1);
  const defRange  = sheet.getRange(HEADER_ROWS + 1, SP_DEF_COL,  numRows, 1);

  const defs = defRange.getValues();
  const notes = defs.map(row => [row[0] ? String(row[0]) : '']);

  nameRange.setNotes(notes);
  defRange.clearContent();

  SpreadsheetApp.getUi().alert(
    '完成！共處理 ' + numRows + ' 列。\n' +
    '滑鼠 hover 在 SP Name 上即可看到完整定義。\n' +
    '（SP Full Definition 欄已清空，可手動隱藏或刪除整欄）'
  );
}

function restoreSPDefinitionFromNote() {
  const SHEET_NAME  = '工作表 4B';
  const SP_NAME_COL = 2;
  const SP_DEF_COL  = 6;
  const HEADER_ROWS = 1;

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    SpreadsheetApp.getUi().alert('找不到工作表：' + SHEET_NAME);
    return;
  }

  const lastRow = sheet.getLastRow();
  const numRows = lastRow - HEADER_ROWS;
  if (numRows <= 0) {
    SpreadsheetApp.getUi().alert('沒有資料列');
    return;
  }

  const nameRange = sheet.getRange(HEADER_ROWS + 1, SP_NAME_COL, numRows, 1);
  const defRange  = sheet.getRange(HEADER_ROWS + 1, SP_DEF_COL,  numRows, 1);

  const notes = nameRange.getNotes();
  defRange.setValues(notes.map(row => [row[0] || '']));
  nameRange.clearNotes();

  SpreadsheetApp.getUi().alert('已還原 ' + numRows + ' 列的 SP Full Definition');
}
