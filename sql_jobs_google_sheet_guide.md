# SQL Server Jobs - Google Sheet 整理指南

## 工作表結構 (共 12 個主 Sheet + 1 個明細 Sheet)

| Sheet | 名稱 | 用途 | 資料來源 |
|-------|------|------|---------|
| 1 | **Job 總覽** | Job 名稱、排程、啟用狀態 | msdb 系統表 |
| 2 | **步驟明細** | 每個 Job 的 Step 內容與命令 | msdb.sysjobsteps |
| 3 | **關聯資料表** | 3A: Step 引用的表 / 3B: SP 關聯表**摘要** (每 SP 一行，含超連結至 Sheet 5) | command 解析 + sys.sql_expression_dependencies |
| 4 | **使用的 SP** | Job → SP 對應表 + Definition Preview，附超連結至 Sheet 4B | sys.procedures + sys.sql_modules |
| **4B** | **SP 完整定義** | 每個 SP 一行，存放 Full Definition (僅供 Sheet 4 超連結查閱) | sys.sql_modules |
| 5 | **SP 相依性明細** | SP 讀寫了哪些表、操作類型 (Sheet 3B 的完整明細) | sys.sql_expression_dependencies |
| 6 | **資源使用量 (Job)** | 30 天執行次數、成功率、平均/最大時長 | msdb.sysjobhistory |
| 7 | **資源使用量 (Step)** | Step 層級耗時、失敗次數、錯誤訊息 | msdb.sysjobhistory |
| 8 | **資料庫 I/O** | 相關 DB 的讀寫量、延遲、檔案大小 | sys.dm_io_virtual_file_stats |
| 9 | **通知設定** | Email/EventLog 通知、擁有者、建立日期 | msdb.sysjobs |
| 10 | **資料表大小** | 表的 row count、大小、index、partition | sys.tables + sys.allocation_units |
| 11 | **資料流向圖** | 每個 Step 的搬移模式、保留天數、批次大小 | command 解析 |
| 12 | **搬移設定表** | sp_move_data 的 sys_movelog_setting 內容 | cmd_data.dbo.sys_movelog_setting |

---

## 使用方式

### 1. 在 msdb 上執行 (Sheet 1, 2, 6, 7, 9, 11)
這些查詢只讀取 `msdb` 系統表，任何連線都可以執行。

### 2. 在各資料庫下執行
| Sheet | 需切換到 |
|-------|---------|
| 3B (SP 相依性摘要) | 在每個有 Job 呼叫 SP 的 DB 各執行一次 |
| 4 (SP 摘要) | 在每個有 Job 呼叫 SP 的 DB 各執行一次 |
| 4B (SP 完整定義) | 在每個有 Job 呼叫 SP 的 DB 各執行一次 |
| 5 (SP 相依性明細) | 在每個有 Job 呼叫 SP 的 DB 各執行一次 |
| 8 (I/O) | 任意 (查所有 DB) |
| 10 (表大小) | 分別在 `cmd_data` / `cmd_data_log` / `cmd_data_archive` 各執行一次 |
| 12 (設定表) | `USE cmd_data` |

### 3. 貼到 Google Sheet
1. SSMS 執行查詢 → **Ctrl+A** → **Ctrl+C**
2. Google Sheet 對應工作表 → **Ctrl+V**

### 4. 設定 Sheet 3B → Sheet 5 超連結
1. 先建好 Sheet 5（貼完資料），從瀏覽器網址列複製 `gid=` 後面的數字
2. 回到 SSMS，打開 Sheet 3B 的查詢，把開頭的 `@Sheet5Gid` 變數值改成那個數字
   ```sql
   DECLARE @Sheet5Gid VARCHAR(20) = '1234567890';  -- 改這裡
   ```
3. 重新執行查詢 → Ctrl+A → Ctrl+C → 貼到 Sheet 3B
4. Detail Link 欄位會直接是可用的超連結，點擊跳到 Sheet 5

### 5. 設定 Sheet 4 → Sheet 4B 超連結
方式跟上面一樣：
1. 先建好 Sheet 4B（執行 Sheet 4B 查詢並貼到 Google Sheet）
2. 複製 Sheet 4B 的 gid
3. 修改 Sheet 4 查詢開頭的 `@Sheet4BGid` 變數
   ```sql
   DECLARE @Sheet4BGid VARCHAR(20) = '9876543210';  -- 改這裡
   ```
4. 執行 Sheet 4 → 貼到 Google Sheet
5. Full Definition Link 欄位點擊就會跳到 Sheet 4B 的完整 SP 內容

---

## 多環境管理

每個環境建一份 Google Sheet，以環境命名：
- `CASH DEV` - 開發環境
- `CASH PROD` - 正式環境

每份 Sheet 內的 12 個工作表結構一致，方便橫向比對。

---

## 建議格式化

- Sheet 1: `Enabled = 0` → 灰色底
- Sheet 6: `Success Rate < 100%` → 紅色底
- Sheet 6: `Avg Duration > 3600` → 橘色底（超過 1 小時）
- Sheet 7: `Failure Count > 0` → 紅色底
- Sheet 10: 依 `Total Size MB` 降冪排序，大表用底色標記
- Sheet 11: 依 `Pattern` 分色（DELETE+OUTPUT=藍, Partition=綠）
