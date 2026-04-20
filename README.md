# TestOutGitHubCoPilot

This repository now includes a baseline SQL Server data model and semantic model for consolidating similar Excel files into a reporting-ready structure.

## Artifacts

- `/home/runner/work/TestOutGitHubCoPilot/TestOutGitHubCoPilot/db/sqlserver_model.sql`
  - Creates schemas (`stg`, `dim`, `fact`, `rpt`)
  - Creates source/staging/dimension/fact tables
  - Creates a reporting view: `rpt.vw_ExcelObservation`
- `/home/runner/work/TestOutGitHubCoPilot/TestOutGitHubCoPilot/semantic/reporting_semantic_model.json`
  - Defines semantic tables, relationships, and core reporting measures

## How to use

1. Run `db/sqlserver_model.sql` in SQL Server.
2. Load each Excel file into `stg.ExcelRecord` and register file metadata in `dbo.SourceFile`.
3. Transform staged records into dimensions (`dim.*`) and fact (`fact.ExcelObservation`).
4. Connect reporting tools (Power BI/SSRS/Excel) to `rpt.vw_ExcelObservation` or use the semantic JSON as a model template.
