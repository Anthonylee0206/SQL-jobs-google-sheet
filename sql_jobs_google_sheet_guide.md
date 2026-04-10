# SQL Server Jobs - Google Sheet 整理指南

## 工作表結構 (共 12 個 Sheet)

| Sheet | 名稱 | 用途 | 資料來源 |
|-------|------|------|---------|
| 1 | **Job 總覽** | Job 名稱、排程、啟用狀態 | msdb 系統表 |
| 2 | **步驟明細** | 每個 Job 的 Step 內容與命令 | msdb.sysjobsteps |
| 3 | **關聯資料表** | Step 引用的資料表 + SP 相依性 | command 解析 + sys.sql_expression_dependencies |
| 4 | **使用的 SP** | EXEC 呼叫的 SP 名稱與定義 | sys.procedures + sys.sql_modules |
| 5 | **SP 相依性** | SP 內部讀寫了哪些表、做什麼操作 | sys.sql_expression_dependencies |
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
| 3B (SP 相依性) | `USE cmd_data` |
| 4 (SP 定義) | `USE cmd_data` |
| 5 (SP 相依性) | `USE cmd_data` |
| 8 (I/O) | 任意 (查所有 DB) |
| 10 (表大小) | 分別在 `cmd_data` / `cmd_data_log` / `cmd_data_archive` 各執行一次 |
| 12 (設定表) | `USE cmd_data` |

### 3. 貼到 Google Sheet
1. SSMS 執行查詢 → **Ctrl+A** → **Ctrl+C**
2. Google Sheet 對應工作表 → **Ctrl+V**

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
