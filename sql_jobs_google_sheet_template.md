# Google Sheet 範本 — 每個工作表的標題列與資料擺放方式

## 工作表 1：Job 總覽
```
| Job Name | Enabled | Freq | Day | Time | Schedule Summary | Description |
|----------|---------|------|-----|------|------------------|-------------|
| JOBS_move_log | 1 | Daily | Daily | 6:30:00 AM | Occurs every day at 6:30:00 AM | 搬移 log 資料 |
| JOBS_move_ticket | 1 | Daily | Daily | 7:00:00 AM | Occurs every day at 7:00:00 AM | 搬移 ticket |
| ... | | | | | | |
```

---

## 工作表 2：步驟明細
```
| Job Name | Step # | Step Name | Type | Database | Command | On Success | On Failure | Retry Count | Retry Interval (min) |
|----------|--------|-----------|------|----------|---------|------------|------------|-------------|---------------------|
| JOBS_move_log | 1 | Check Replica | T-SQL | cmd_data | IF master.dbo.fn_hadr... | Go to next step | Quit with failure | 0 | 0 |
| JOBS_move_log | 2 | move_log | T-SQL | cmd_data | EXEC sp_move_data... | Go to next step | Quit with failure | 0 | 0 |
| ... | | | | | | | | | |
```

---

## 工作表 3：關聯資料表

### ← 先貼 3A 結果 (在 msdb 執行一次就好)
```
| Job Name | Step # | Step Name | Step Database | Operation | Table Name | Direction | Full Command |
|----------|--------|-----------|---------------|-----------|------------|-----------|--------------|
| JOBS_move_log | 2 | move_log | cmd_data | EXEC SP | sp_move_data | CALL | EXEC sp_move_data... |
| JOBS_move_log | 3 | cashout_log | cmd_data | DELETE | cmd_data.dbo.provider_ticket_cmd_cashout_log | SOURCE | DELETE c FROM... |
| JOBS_move_log | 3 | cashout_log | cmd_data | INSERT/OUTPUT INTO | cmd_data_log.dbo.provider_ticket_cmd_cashout_log | TARGET | insert into... |
| ... | | | | | | | |
```

### ← 空一行，然後貼 3B 結果 (每個 DB 各跑一次，全部接在下面)
```
| Source Database | SP Name | Referenced Database | Referenced Schema | Referenced Table/Object | Object Type |
|-----------------|---------|---------------------|-------------------|------------------------|-------------|
| cmd_data | sp_move_data | cmd_data | dbo | sys_movelog_setting | USER_TABLE |
| cmd_data | sp_move_data | NULL | dbo | provider_ticket_cmd | USER_TABLE |
| cmd_data_log | (如果 log 庫有 SP 才會有資料) | | | | |
| cmd_data_archive | (如果 archive 庫有 SP 才會有資料) | | | | |
```

> **注意：3A 和 3B 欄位不同，分開貼就好，中間空一行區隔**

---

## 工作表 4：使用的 SP
```
| Current Database | Job Name | Step # | Step Name | Step Database | SP Name | SP Created | SP Last Modified | SP Definition Length | SP Definition Preview | SP Full Definition |
|------------------|----------|--------|-----------|---------------|---------|------------|------------------|---------------------|-----------------------|-------------------|
| cmd_data | JOBS_move_log | 2 | move_log | cmd_data | sp_move_data | 2025-01-15 | 2026-03-26 | 487 | CREATE PROC [dbo].[sp_move_data]... | (完整定義) |
```
> 在 cmd_data / cmd_data_log / cmd_data_archive 各跑一次，結果全部接在一起，靠 Current Database 欄位區分

---

## 工作表 5：SP 相依性
```
| Current Database | SP Name | Referenced Database | Referenced Schema | Referenced Table/Object | Object Type | Operation Type | SP Definition Preview |
|------------------|---------|---------------------|-------------------|------------------------|-------------|----------------|-----------------------|
| cmd_data | sp_move_data | cmd_data | dbo | sys_movelog_setting | USER_TABLE | SELECT | CREATE PROC... |
| cmd_data | sp_move_data | NULL | dbo | sp_executesql | UNKNOWN (cross-db) | REFERENCE | CREATE PROC... |
```
> 同上，每個 DB 各跑一次，全部貼在一起

---

## 工作表 6：資源使用量 (Job 層級)
```
| Job Name | Executions (30d) | Success Count | Failure Count | Success Rate % | Avg Duration (sec) | Max Duration (sec) | Min Duration (sec) | Last Run Time | Last Run Status |
|----------|-----------------|---------------|---------------|----------------|--------------------|--------------------|--------------------|--------------|-----------------| 
| JOBS_move_log | 30 | 30 | 0 | 100.0 | 45 | 120 | 12 | 2026-04-10 06:30 | Succeeded |
| JOBS_move_ticket | 30 | 29 | 1 | 96.7 | 300 | 1800 | 60 | 2026-04-10 07:00 | Succeeded |
```

---

## 工作表 7：資源使用量 (Step 層級)
```
| Job Name | Step # | Step Name | Executions (30d) | Avg Duration (sec) | Max Duration (sec) | Failure Count | Last Error Message |
|----------|--------|-----------|-----------------|--------------------|--------------------|---------------|--------------------|
| JOBS_move_log | 3 | pp_log | 30 | 35 | 90 | 0 | NULL |
| JOBS_move_ticket | 2 | cashout | 30 | 250 | 1500 | 1 | Error: deadlock... |
```

---

## 工作表 8：資料庫 I/O
```
| Database | File ID | Logical Name | File Type | Physical Path | Total Reads | Read MB | Avg Read Latency (ms) | Total Writes | Write MB | Avg Write Latency (ms) | Total IO MB | File Size MB |
|----------|---------|-------------|-----------|---------------|-------------|---------|----------------------|-------------|----------|----------------------|-------------|-------------|
| cmd_data | 1 | cmd_data | ROWS | D:\Data\cmd_data.mdf | 500000 | 8192.00 | 1.25 | 300000 | 4096.00 | 2.50 | 12288.00 | 20480.00 |
```

---

## 工作表 9：通知設定
```
| Job Name | Email Notify | Email Operator | EventLog Notify | Auto Delete | Owner | Created | Modified |
|----------|-------------|----------------|-----------------|-------------|-------|---------|----------|
| JOBS_move_log | On Failure | DBA_Team | On Failure | Never | sa | 2025-01-15 | 2026-03-26 |
```

---

## 工作表 10：資料表大小
```
| Database | Schema | Table Name | Row Count | Total Size MB | Used Size MB | Unused Size MB | Index Count | Is Partitioned | Partition Count | Table Created | Table Modified |
|----------|--------|------------|-----------|--------------|-------------|---------------|-------------|----------------|-----------------|--------------|---------------|
| cmd_data | dbo | provider_ticket_cmd | 25000000 | 15360.00 | 14800.00 | 560.00 | 3 | Yes | 52 | 2024-01-01 | 2026-04-10 |
| cmd_data_log | dbo | provider_ticket_cmd | 80000000 | 45000.00 | 44000.00 | 1000.00 | 2 | No | 1 | 2024-01-01 | 2026-04-10 |
```
> 在 cmd_data / cmd_data_log / cmd_data_archive 各跑一次，靠 Database 欄位區分

---

## 工作表 11：資料流向圖
```
| Job Name | Step # | Step Name | Pattern | Execution DB | Retention Policy | Batch Size | Has Delay | HA Check |
|----------|--------|-----------|---------|--------------|------------------|------------|-----------|----------|
| JOBS_move_log | 1 | STEPNAME | sp_move_data → see sys_movelog_setting | cmd_data | See sys_movelog_setting | 50,000 rows/batch (in SP) | No | No |
| JOBS_move_log | 2 | cashout_log | INSERT...SELECT pattern | cmd_data | 6 months | No batching | No | No |
| JOBS_move_log | 3 | pp_log | DELETE+OUTPUT pattern | cmd_data | 3 months | 10,000 rows/batch | Yes | No |
```

---

## 工作表 12：搬移設定表
```
| Table Name | Table Type | Filter Column | Where Condition | Source DB | Target DB |
|------------|-----------|---------------|-----------------|-----------|-----------|
| provider_ticket_cmd | ticket | working_date | CAST(DATEADD(MONTH,-12,GETDATE()) AS DATE) | cmd_data | cmd_data_archive |
| some_log_table | log | create_date | CAST(DATEADD(MONTH,-6,GETDATE()) AS DATE) | cmd_data | cmd_data_log |
```
