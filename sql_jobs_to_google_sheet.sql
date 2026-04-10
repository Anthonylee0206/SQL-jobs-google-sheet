-- =====================================================================
-- SQL Server Agent Jobs 完整匯出至 Google Sheet (多工作表版)
-- 每段查詢對應一個 Google Sheet 工作表，依序執行後貼上
-- =====================================================================


-- =====================================================================
-- Sheet 1：Job 總覽
-- =====================================================================
SELECT
    j.name                              AS [Job Name],
    j.enabled                           AS [Enabled],
    CASE s.freq_type
        WHEN 1  THEN 'Once'
        WHEN 4  THEN
            CASE WHEN s.freq_interval = 1 THEN 'Daily'
                 ELSE 'Every ' + CAST(s.freq_interval AS VARCHAR) + ' days'
            END
        WHEN 8  THEN
            CASE WHEN s.freq_recurrence_factor = 1 THEN 'Weekly'
                 ELSE 'Every ' + CAST(s.freq_recurrence_factor AS VARCHAR) + ' weeks'
            END
        WHEN 16 THEN
            CASE WHEN s.freq_recurrence_factor = 1 THEN 'Monthly'
                 ELSE 'Every ' + CAST(s.freq_recurrence_factor AS VARCHAR) + ' months'
            END
        WHEN 32 THEN 'Monthly Relative'
        WHEN 64 THEN 'On Agent Start'
        WHEN 128 THEN 'On Idle'
        ELSE ''
    END                                 AS [Freq],
    CASE s.freq_type
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN
            LTRIM(
                CASE WHEN s.freq_interval & 2  = 2  THEN 'Mon ' ELSE '' END +
                CASE WHEN s.freq_interval & 4  = 4  THEN 'Tue ' ELSE '' END +
                CASE WHEN s.freq_interval & 8  = 8  THEN 'Wed ' ELSE '' END +
                CASE WHEN s.freq_interval & 16 = 16 THEN 'Thu ' ELSE '' END +
                CASE WHEN s.freq_interval & 32 = 32 THEN 'Fri ' ELSE '' END +
                CASE WHEN s.freq_interval & 64 = 64 THEN 'Sat ' ELSE '' END +
                CASE WHEN s.freq_interval & 1  = 1  THEN 'Sun ' ELSE '' END
            )
        WHEN 16 THEN 'Day ' + CAST(s.freq_interval AS VARCHAR)
        WHEN 32 THEN
            CASE s.freq_relative_interval
                WHEN 1  THEN 'First '  WHEN 2  THEN 'Second '
                WHEN 4  THEN 'Third '  WHEN 8  THEN 'Fourth '
                WHEN 16 THEN 'Last '
            END +
            CASE s.freq_interval
                WHEN 1  THEN 'Sun' WHEN 2  THEN 'Mon' WHEN 3  THEN 'Tue'
                WHEN 4  THEN 'Wed' WHEN 5  THEN 'Thu' WHEN 6  THEN 'Fri'
                WHEN 7  THEN 'Sat' WHEN 8  THEN 'Day' WHEN 9  THEN 'Weekday'
                WHEN 10 THEN 'Weekend'
            END
        ELSE ''
    END                                 AS [Day],
    CASE
        WHEN s.freq_subday_type = 1 THEN
            LTRIM(RIGHT(CONVERT(VARCHAR(22),
                CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_subday_type IN (2,4,8) THEN
            LTRIM(RIGHT(CONVERT(VARCHAR(22),
                CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
            + ' - '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22),
                CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        ELSE ''
    END                                 AS [Time],
    -- Schedule Summary
    CASE
        WHEN s.freq_type = 4 AND s.freq_subday_type IN (2,4,8) THEN
            'Occurs every day, every ' + CAST(s.freq_subday_interval AS VARCHAR) + ' '
            + CASE s.freq_subday_type WHEN 2 THEN 'second(s)' WHEN 4 THEN 'minute(s)' WHEN 8 THEN 'hour(s)' END
            + ' between '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
            + ' and '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 4 AND s.freq_subday_type = 1 THEN
            'Occurs every day at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 8 AND s.freq_subday_type IN (2,4,8) THEN
            'Occurs every week on '
            + LTRIM(
                CASE WHEN s.freq_interval & 2  = 2  THEN 'Monday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 4  = 4  THEN 'Tuesday, '  ELSE '' END +
                CASE WHEN s.freq_interval & 8  = 8  THEN 'Wednesday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 32 = 32 THEN 'Friday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 1  = 1  THEN 'Sunday, '   ELSE '' END)
            + 'every ' + CAST(s.freq_subday_interval AS VARCHAR) + ' '
            + CASE s.freq_subday_type WHEN 2 THEN 'second(s)' WHEN 4 THEN 'minute(s)' WHEN 8 THEN 'hour(s)' END
            + ' between '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
            + ' and '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 8 AND s.freq_subday_type = 1 THEN
            'Occurs every week on '
            + LTRIM(
                CASE WHEN s.freq_interval & 2  = 2  THEN 'Monday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 4  = 4  THEN 'Tuesday, '  ELSE '' END +
                CASE WHEN s.freq_interval & 8  = 8  THEN 'Wednesday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 32 = 32 THEN 'Friday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 1  = 1  THEN 'Sunday, '   ELSE '' END)
            + 'at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 16 AND s.freq_subday_type = 1 THEN
            'Occurs every month on day ' + CAST(s.freq_interval AS VARCHAR)
            + ' at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 16 AND s.freq_subday_type IN (2,4,8) THEN
            'Occurs every month on day ' + CAST(s.freq_interval AS VARCHAR)
            + ', every ' + CAST(s.freq_subday_interval AS VARCHAR) + ' '
            + CASE s.freq_subday_type WHEN 2 THEN 'second(s)' WHEN 4 THEN 'minute(s)' WHEN 8 THEN 'hour(s)' END
            + ' between '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
            + ' and '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 32 AND s.freq_subday_type = 1 THEN
            'Occurs every month on the '
            + CASE s.freq_relative_interval
                WHEN 1 THEN 'first ' WHEN 2 THEN 'second ' WHEN 4 THEN 'third '
                WHEN 8 THEN 'fourth ' WHEN 16 THEN 'last ' END
            + CASE s.freq_interval
                WHEN 1 THEN 'Sunday' WHEN 2 THEN 'Monday' WHEN 3 THEN 'Tuesday'
                WHEN 4 THEN 'Wednesday' WHEN 5 THEN 'Thursday' WHEN 6 THEN 'Friday'
                WHEN 7 THEN 'Saturday' WHEN 8 THEN 'day' WHEN 9 THEN 'weekday' WHEN 10 THEN 'weekend day' END
            + ' at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 1 THEN
            'Occurs once at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
        WHEN s.freq_type = 64  THEN 'Occurs when SQL Server Agent starts'
        WHEN s.freq_type = 128 THEN 'Occurs when server is idle'
        ELSE ''
    END                                 AS [Schedule Summary],
    j.description                       AS [Description]
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
ORDER BY j.name;


-- =====================================================================
-- Sheet 2：Job Steps 步驟明細
-- =====================================================================
SELECT
    j.name                              AS [Job Name],
    js.step_id                          AS [Step #],
    js.step_name                        AS [Step Name],
    CASE js.subsystem
        WHEN 'TSQL'       THEN 'T-SQL'
        WHEN 'CmdExec'    THEN 'OS Command'
        WHEN 'PowerShell' THEN 'PowerShell'
        WHEN 'SSIS'       THEN 'SSIS'
        ELSE js.subsystem
    END                                 AS [Type],
    js.database_name                    AS [Database],
    js.command                          AS [Command],
    CASE js.on_success_action
        WHEN 1 THEN 'Quit with success'
        WHEN 2 THEN 'Go to next step'
        WHEN 3 THEN 'Go to step ' + CAST(js.on_success_step_id AS VARCHAR)
        WHEN 4 THEN 'Quit with failure'
    END                                 AS [On Success],
    CASE js.on_fail_action
        WHEN 1 THEN 'Quit with success'
        WHEN 2 THEN 'Go to next step'
        WHEN 3 THEN 'Go to step ' + CAST(js.on_fail_step_id AS VARCHAR)
        WHEN 4 THEN 'Quit with failure'
    END                                 AS [On Failure],
    js.retry_attempts                   AS [Retry Count],
    js.retry_interval                   AS [Retry Interval (min)]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
ORDER BY j.name, js.step_id;


-- =====================================================================
-- Sheet 3：Job 關聯資料表 (從 Step Command 與 SP 相依性兩種來源合併)
-- =====================================================================

-- 3A：直接從 Job Step command 文字解析出資料表名稱
SELECT
    j.name                              AS [Job Name],
    js.step_id                          AS [Step #],
    js.step_name                        AS [Step Name],
    js.database_name                    AS [Step Database],
    t.operation                         AS [Operation],
    t.table_name                        AS [Table Name],
    t.direction                         AS [Direction],
    js.command                          AS [Full Command]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
CROSS APPLY (
    -- 解析 DELETE ... FROM [table]
    SELECT 'DELETE' AS operation,
           LTRIM(RTRIM(REPLACE(REPLACE(
               SUBSTRING(
                   SUBSTRING(js.command, CHARINDEX('FROM ', js.command) + 5, 200),
                   1,
                   CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('FROM ', js.command) + 5, 200) + ' ') - 1
               ), '[', ''), ']', ''))) AS table_name,
           'SOURCE' AS direction
    WHERE js.command LIKE '%DELETE%FROM %'
    UNION ALL
    -- 解析 INSERT INTO / OUTPUT ... INTO [table]
    SELECT 'INSERT/OUTPUT INTO',
           LTRIM(RTRIM(REPLACE(REPLACE(
               SUBSTRING(
                   SUBSTRING(js.command, CHARINDEX('INTO ', js.command) + 5, 200),
                   1,
                   CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('INTO ', js.command) + 5, 200) + ' ') - 1
               ), '[', ''), ']', ''))),
           'TARGET'
    WHERE js.command LIKE '%INTO %'
    UNION ALL
    -- 解析 JOIN [table]
    SELECT 'JOIN',
           LTRIM(RTRIM(REPLACE(REPLACE(
               SUBSTRING(
                   SUBSTRING(js.command, CHARINDEX('JOIN ', js.command) + 5, 200),
                   1,
                   CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('JOIN ', js.command) + 5, 200) + ' ') - 1
               ), '[', ''), ']', ''))),
           'REFERENCE'
    WHERE js.command LIKE '%JOIN %'
    UNION ALL
    -- 解析 EXEC sp_name
    SELECT 'EXEC SP',
           LTRIM(RTRIM(
               SUBSTRING(
                   SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200),
                   1,
                   CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200) + ' ') - 1
               ))),
           'CALL'
    WHERE js.command LIKE '%EXEC %'
    UNION ALL
    -- 解析 ALTER PARTITION
    SELECT 'ALTER PARTITION',
           LTRIM(RTRIM(
               SUBSTRING(
                   SUBSTRING(js.command, CHARINDEX('ALTER PARTITION ', js.command) + 17, 200),
                   1,
                   CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('ALTER PARTITION ', js.command) + 17, 200) + ' ') - 1
               ))),
           'DDL'
    WHERE js.command LIKE '%ALTER PARTITION%'
) t
WHERE js.subsystem = 'TSQL'
  AND t.table_name IS NOT NULL
  AND t.table_name <> ''
ORDER BY j.name, js.step_id, t.direction;

-- 3B：透過 SP 相依性反查，只撈 Job 有呼叫到的 SP 的相依性
--     需在 Job 使用的資料庫下執行 (例如 USE cmd_data)
SELECT
    DB_NAME()                           AS [Source Database],
    p.name                              AS [SP Name],
    d.referenced_database_name          AS [Referenced Database],
    ISNULL(d.referenced_schema_name, 'dbo') AS [Referenced Schema],
    d.referenced_entity_name            AS [Referenced Table/Object],
    CASE
        WHEN ro.type_desc IS NOT NULL THEN ro.type_desc
        ELSE 'UNKNOWN (cross-db)'
    END                                 AS [Object Type]
FROM sys.procedures p
INNER JOIN sys.sql_expression_dependencies d
    ON p.object_id = d.referencing_id
LEFT JOIN sys.objects ro
    ON d.referenced_id = ro.object_id
WHERE p.name IN (
    -- 只撈 Job Step 裡有 EXEC 到的 SP
    SELECT DISTINCT
        LTRIM(RTRIM(
            SUBSTRING(
                SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200),
                1,
                CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200) + ' ') - 1
            )
        ))
    FROM msdb.dbo.sysjobsteps js
    WHERE js.command LIKE '%EXEC %'
      AND js.subsystem = 'TSQL'
)
ORDER BY p.name, d.referenced_entity_name;


-- =====================================================================
-- Sheet 4：Job 使用的 Stored Procedures (SP 總表 + 定義)
-- 需在 Job 使用的資料庫下執行 (例如 USE cmd_data)
-- =====================================================================
SELECT
    DB_NAME()                           AS [Current Database],
    j.name                              AS [Job Name],
    js.step_id                          AS [Step #],
    js.step_name                        AS [Step Name],
    js.database_name                    AS [Step Database],
    -- 擷取 EXEC 後面的 SP 名稱
    LTRIM(RTRIM(
        SUBSTRING(
            SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200),
            1,
            CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200) + ' ') - 1
        )
    ))                                  AS [SP Name],
    p.create_date                       AS [SP Created],
    p.modify_date                       AS [SP Last Modified],
    LEN(m.definition)                   AS [SP Definition Length],
    -- SP 做什麼：摘要 (取前 500 字)
    LEFT(m.definition, 500)             AS [SP Definition Preview],
    -- SP 完整內容 (如果需要完整定義可展開此欄)
    m.definition                        AS [SP Full Definition]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
LEFT JOIN sys.procedures p
    ON p.name = LTRIM(RTRIM(
        SUBSTRING(
            SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200),
            1,
            CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200) + ' ') - 1
        )
    ))
LEFT JOIN sys.sql_modules m ON p.object_id = m.object_id
WHERE js.command LIKE '%EXEC %'
  AND js.subsystem = 'TSQL'
ORDER BY j.name, js.step_id;


-- =====================================================================
-- Sheet 5：SP 相依性分析 (SP 讀寫了哪些資料表)
-- 需在對應資料庫下執行 (例如 USE cmd_data)
-- =====================================================================
SELECT
    DB_NAME()                           AS [Current Database],
    OBJECT_NAME(d.referencing_id)       AS [SP Name],
    d.referenced_database_name          AS [Referenced Database],
    ISNULL(d.referenced_schema_name, 'dbo') AS [Referenced Schema],
    d.referenced_entity_name            AS [Referenced Table/Object],
    CASE
        WHEN ro.type_desc IS NOT NULL THEN ro.type_desc
        ELSE 'UNKNOWN (cross-db)'
    END                                 AS [Object Type],
    -- 從 SP 原始碼判斷操作類型
    CASE
        WHEN m.definition LIKE '%DELETE%'  + d.referenced_entity_name + '%'
         AND m.definition LIKE '%OUTPUT%deleted%' THEN 'DELETE + OUTPUT INTO'
        WHEN m.definition LIKE '%DELETE%'  + d.referenced_entity_name + '%' THEN 'DELETE'
        WHEN m.definition LIKE '%INSERT%'  + d.referenced_entity_name + '%' THEN 'INSERT'
        WHEN m.definition LIKE '%UPDATE%'  + d.referenced_entity_name + '%' THEN 'UPDATE'
        WHEN m.definition LIKE '%SELECT%'  + d.referenced_entity_name + '%' THEN 'SELECT'
        WHEN m.definition LIKE '%TRUNCATE%'+ d.referenced_entity_name + '%' THEN 'TRUNCATE'
        ELSE 'REFERENCE'
    END                                 AS [Operation Type],
    LEFT(m.definition, 500)             AS [SP Definition Preview]
FROM sys.sql_expression_dependencies d
INNER JOIN sys.objects o ON d.referencing_id = o.object_id
LEFT JOIN sys.sql_modules m ON d.referencing_id = m.object_id
LEFT JOIN sys.objects ro ON d.referenced_id = ro.object_id
WHERE o.type = 'P'
  AND o.name IN (
    -- 只撈 Job Step 裡有 EXEC 到的 SP
    SELECT DISTINCT
        LTRIM(RTRIM(
            SUBSTRING(
                SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200),
                1,
                CHARINDEX(' ', SUBSTRING(js.command, CHARINDEX('EXEC ', js.command) + 5, 200) + ' ') - 1
            )
        ))
    FROM msdb.dbo.sysjobsteps js
    WHERE js.command LIKE '%EXEC %'
      AND js.subsystem = 'TSQL'
)
ORDER BY OBJECT_NAME(d.referencing_id), d.referenced_entity_name;


-- =====================================================================
-- Sheet 6：Job 資源使用量 (最近 30 天執行統計)
-- =====================================================================
SELECT
    j.name                              AS [Job Name],
    COUNT(*)                            AS [Executions (30d)],
    SUM(CASE WHEN h.run_status = 1 THEN 1 ELSE 0 END) AS [Success Count],
    SUM(CASE WHEN h.run_status = 0 THEN 1 ELSE 0 END) AS [Failure Count],
    CAST(
        CASE WHEN COUNT(*) > 0
             THEN SUM(CASE WHEN h.run_status = 1 THEN 1.0 ELSE 0 END) / COUNT(*) * 100
             ELSE 0
        END AS DECIMAL(5,1))            AS [Success Rate %],
    -- 平均執行時長 (秒)
    AVG(h.run_duration / 10000 * 3600
        + (h.run_duration % 10000) / 100 * 60
        + h.run_duration % 100)         AS [Avg Duration (sec)],
    -- 最長執行時長
    MAX(h.run_duration / 10000 * 3600
        + (h.run_duration % 10000) / 100 * 60
        + h.run_duration % 100)         AS [Max Duration (sec)],
    -- 最短執行時長
    MIN(h.run_duration / 10000 * 3600
        + (h.run_duration % 10000) / 100 * 60
        + h.run_duration % 100)         AS [Min Duration (sec)],
    -- 最後執行時間
    MAX(msdb.dbo.agent_datetime(h.run_date, h.run_time))
                                        AS [Last Run Time],
    -- 最後執行結果
    CASE (SELECT TOP 1 h2.run_status
          FROM msdb.dbo.sysjobhistory h2
          WHERE h2.job_id = j.job_id AND h2.step_id = 0
          ORDER BY h2.run_date DESC, h2.run_time DESC)
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        ELSE 'Unknown'
    END                                 AS [Last Run Status]
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobhistory h
    ON j.job_id = h.job_id AND h.step_id = 0
    AND h.run_date >= CONVERT(VARCHAR(8), DATEADD(DAY, -30, GETDATE()), 112)
GROUP BY j.job_id, j.name
ORDER BY [Executions (30d)] DESC;


-- =====================================================================
-- Sheet 7：Job Step 層級資源使用量 (哪個步驟最耗時)
-- =====================================================================
SELECT
    j.name                              AS [Job Name],
    h.step_id                           AS [Step #],
    h.step_name                         AS [Step Name],
    COUNT(*)                            AS [Executions (30d)],
    AVG(h.run_duration / 10000 * 3600
        + (h.run_duration % 10000) / 100 * 60
        + h.run_duration % 100)         AS [Avg Duration (sec)],
    MAX(h.run_duration / 10000 * 3600
        + (h.run_duration % 10000) / 100 * 60
        + h.run_duration % 100)         AS [Max Duration (sec)],
    SUM(CASE WHEN h.run_status = 0 THEN 1 ELSE 0 END) AS [Failure Count],
    -- 最後一次失敗訊息
    (SELECT TOP 1 h2.message
     FROM msdb.dbo.sysjobhistory h2
     WHERE h2.job_id = j.job_id
       AND h2.step_id = h.step_id
       AND h2.run_status = 0
     ORDER BY h2.run_date DESC, h2.run_time DESC)
                                        AS [Last Error Message]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory h
    ON j.job_id = h.job_id AND h.step_id > 0
    AND h.run_date >= CONVERT(VARCHAR(8), DATEADD(DAY, -30, GETDATE()), 112)
GROUP BY j.job_id, j.name, h.step_id, h.step_name
ORDER BY [Avg Duration (sec)] DESC;


-- =====================================================================
-- Sheet 8：資料庫層級 I/O 統計 (Job 涉及的資料庫資源消耗)
-- =====================================================================
SELECT
    DB_NAME(fs.database_id)             AS [Database],
    fs.file_id                          AS [File ID],
    mf.name                             AS [Logical Name],
    mf.type_desc                        AS [File Type],
    mf.physical_name                    AS [Physical Path],
    -- 讀取統計
    fs.num_of_reads                     AS [Total Reads],
    CAST(fs.num_of_bytes_read / 1048576.0 AS DECIMAL(18,2))
                                        AS [Read MB],
    CASE WHEN fs.num_of_reads > 0
         THEN CAST(fs.io_stall_read_ms * 1.0 / fs.num_of_reads AS DECIMAL(10,2))
         ELSE 0
    END                                 AS [Avg Read Latency (ms)],
    -- 寫入統計
    fs.num_of_writes                    AS [Total Writes],
    CAST(fs.num_of_bytes_written / 1048576.0 AS DECIMAL(18,2))
                                        AS [Write MB],
    CASE WHEN fs.num_of_writes > 0
         THEN CAST(fs.io_stall_write_ms * 1.0 / fs.num_of_writes AS DECIMAL(10,2))
         ELSE 0
    END                                 AS [Avg Write Latency (ms)],
    -- 總計
    CAST((fs.num_of_bytes_read + fs.num_of_bytes_written) / 1048576.0 AS DECIMAL(18,2))
                                        AS [Total IO MB],
    CAST(fs.size_on_disk_bytes / 1048576.0 AS DECIMAL(18,2))
                                        AS [File Size MB]
FROM sys.dm_io_virtual_file_stats(NULL, NULL) fs
INNER JOIN sys.master_files mf
    ON fs.database_id = mf.database_id AND fs.file_id = mf.file_id
WHERE DB_NAME(fs.database_id) IN ('cmd_data', 'cmd_data_log', 'cmd_data_archive', 'msdb')
ORDER BY [Total IO MB] DESC;


-- =====================================================================
-- Sheet 9：Job 通知與告警設定
-- =====================================================================
SELECT
    j.name                              AS [Job Name],
    CASE j.notify_level_email
        WHEN 0 THEN 'Never'
        WHEN 1 THEN 'On Success'
        WHEN 2 THEN 'On Failure'
        WHEN 3 THEN 'On Completion'
    END                                 AS [Email Notify],
    ISNULL(o.name, '-')                 AS [Email Operator],
    CASE j.notify_level_eventlog
        WHEN 0 THEN 'Never'
        WHEN 1 THEN 'On Success'
        WHEN 2 THEN 'On Failure'
        WHEN 3 THEN 'On Completion'
    END                                 AS [EventLog Notify],
    CASE j.delete_level
        WHEN 0 THEN 'Never'
        WHEN 1 THEN 'On Success'
        WHEN 2 THEN 'On Failure'
        WHEN 3 THEN 'On Completion'
    END                                 AS [Auto Delete],
    SUSER_SNAME(j.owner_sid)            AS [Owner],
    j.date_created                      AS [Created],
    j.date_modified                     AS [Modified]
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysoperators o ON j.notify_email_operator_id = o.id
ORDER BY j.name;


-- =====================================================================
-- Sheet 10：關聯資料表大小與資料量
-- 需在各資料庫下分別執行 (cmd_data / cmd_data_log / cmd_data_archive)
-- =====================================================================
SELECT
    DB_NAME()                           AS [Database],
    s.name                              AS [Schema],
    t.name                              AS [Table Name],
    p.rows                              AS [Row Count],
    CAST(SUM(a.total_pages) * 8 / 1024.0 AS DECIMAL(18,2))
                                        AS [Total Size MB],
    CAST(SUM(a.used_pages) * 8 / 1024.0 AS DECIMAL(18,2))
                                        AS [Used Size MB],
    CAST((SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024.0 AS DECIMAL(18,2))
                                        AS [Unused Size MB],
    -- Index 數量
    (SELECT COUNT(*) FROM sys.indexes i WHERE i.object_id = t.object_id AND i.type > 0)
                                        AS [Index Count],
    -- 是否有 Partition
    CASE
        WHEN EXISTS (
            SELECT 1 FROM sys.partitions pp
            WHERE pp.object_id = t.object_id AND pp.partition_number > 1
        ) THEN 'Yes'
        ELSE 'No'
    END                                 AS [Is Partitioned],
    -- Partition 數量
    (SELECT COUNT(DISTINCT pp.partition_number) FROM sys.partitions pp
     WHERE pp.object_id = t.object_id AND pp.index_id IN (0,1))
                                        AS [Partition Count],
    t.create_date                       AS [Table Created],
    t.modify_date                       AS [Table Modified]
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE i.index_id <= 1  -- Heap 或 Clustered Index
GROUP BY s.name, t.name, t.object_id, p.rows, t.create_date, t.modify_date
ORDER BY [Total Size MB] DESC;


-- =====================================================================
-- Sheet 11：Job 資料流向圖 (來源 → 目標 對照表)
-- 手動整理用：搭配 Sheet 1-5 的資料，整理出每個 Job 的資料流向
-- =====================================================================
SELECT
    j.name                              AS [Job Name],
    js.step_id                          AS [Step #],
    js.step_name                        AS [Step Name],
    -- 搬移方向摘要
    CASE
        WHEN js.command LIKE '%EXEC sp_move_data%' THEN
            'sp_move_data → see sys_movelog_setting'
        WHEN js.command LIKE '%OUTPUT deleted%INTO%' THEN
            'DELETE+OUTPUT pattern'
        WHEN js.command LIKE '%INSERT INTO%SELECT%' THEN
            'INSERT...SELECT pattern'
        WHEN js.command LIKE '%ALTER PARTITION%' THEN
            'Partition maintenance'
        ELSE 'Other'
    END                                 AS [Pattern],
    js.database_name                    AS [Execution DB],
    -- 保留天數
    CASE
        WHEN js.command LIKE '%DATEADD(MONTH,-6%'  THEN '6 months'
        WHEN js.command LIKE '%DATEADD(MONTH,-3%'  THEN '3 months'
        WHEN js.command LIKE '%GETDATE()-365%'     THEN '365 days'
        WHEN js.command LIKE '%DATEADD(DAY,7%'     THEN 'Next 7 days (partition)'
        WHEN js.command LIKE '%EXEC sp_move_data%' THEN 'See sys_movelog_setting'
        ELSE '-'
    END                                 AS [Retention Policy],
    -- 批次大小
    CASE
        WHEN js.command LIKE '%TOP (10000)%'  THEN '10,000 rows/batch'
        WHEN js.command LIKE '%TOP (50000)%'  THEN '50,000 rows/batch'
        WHEN js.command LIKE '%TOP%(%'        THEN 'Batched (see command)'
        WHEN js.command LIKE '%EXEC sp_move_data%' THEN '50,000 rows/batch (in SP)'
        ELSE 'No batching'
    END                                 AS [Batch Size],
    -- 有無 WAITFOR 延遲
    CASE
        WHEN js.command LIKE '%WAITFOR DELAY%' THEN 'Yes'
        ELSE 'No'
    END                                 AS [Has Delay],
    -- HA 檢查
    CASE
        WHEN js.command LIKE '%fn_hadr_is_primary_replica%' THEN 'Yes'
        ELSE 'No'
    END                                 AS [HA Check]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
WHERE js.subsystem = 'TSQL'
ORDER BY j.name, js.step_id;


-- =====================================================================
-- Sheet 12：sys_movelog_setting 設定表內容
-- (sp_move_data 的搬移規則設定)
-- 需在 cmd_data 資料庫下執行
-- =====================================================================
SELECT
    Table_Name                          AS [Table Name],
    TableType                           AS [Table Type],
    FilterColName                       AS [Filter Column],
    WhereString                         AS [Where Condition],
    FromDbName                          AS [Source DB],
    TargetDbName                        AS [Target DB]
FROM cmd_data.dbo.sys_movelog_setting
ORDER BY TableType, Table_Name;
