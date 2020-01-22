# pre-compile-trigger-oracle
A simple way to prevent loss of modification done in a package/trigger/procedure/function when working on a shared test oracle database.

** Note - This was written in a rush.. did not have time to think of better variable names ect ^^** 

## Installation Guide
Execute file intall_pre_compile_check

## Table Modification Log

| Field Name | Description | 
| ----------- | ----------- |
| ID  | Record Unique Identifier |
| object_name  |  |
| object_type  |  |
| developer_name  | name of the person doing the change |
| tracker  | link to the task |
| date_created | date added in the table|

## Usage
Each time you work on an object_name, log it in the table modification log.


```sql
insert into  modification_log(object_name, object_type, developer_name, tracker ) 
values('TEST', 'PACKAGE BODY', 'JDoe', 'WORK#ID5555');
```

## Output example
```console
Connected to:
Oracle Database 12c Standard Edition Release 12.1.0.2.0 - 64bit Production

SQL> create or replace package TEST
  2  as
  3  end
  4  /
create or replace package TEST
*
ERROR at line 1:
ORA-00604: error occurred at recursive SQL level 1
ORA-20601: Cannot compile  TEST object. Consult developer:
jdoe or check table modification_log for more information.
sql: SELECT * FROM modification_log WHERE object_name = 'TEST'
ORA-06512: at line 12
```
