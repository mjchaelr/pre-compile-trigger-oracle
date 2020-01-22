-- Drop (if any)
 drop sequence modification_log_sqnu;
 drop trigger pre_compile_check;
 drop table modification_log;

 
CREATE SEQUENCE modification_log_sqnu
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 0
  NOCYCLE
  NOCACHE
  NOORDER
  NOKEEP
  GLOBAL;

-- Table modification_log to store changes done by a developer
create table modification_log (
    id number,
    object_name varchar2(100),
    object_type varchar2(100)  CHECK (object_type in ('PACKAGE', 'PACKAGE BODY', 'TRIGGER','FUNCTION', 'PROCEDURE')),
    developer_name varchar2(100),
    tracker varchar2(100),
    date_created date
);

-- unique key on object_name, object_type, developer_name, tracker
ALTER TABLE modification_log ADD (
  CONSTRAINT modification_log_uk
  UNIQUE (object_name, object_type, developer_name, tracker)
  ENABLE VALIDATE);

-- trigger to initialise id, and date created
CREATE OR REPLACE TRIGGER modification_log_trig
BEFORE INSERT
ON modification_log
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
    SELECT modification_log_sqnu.NEXTVAL, sysdate, upper(:new.object_name), upper(:new.object_type)
    into :new.id, :new.date_created, :new.object_name, :new.object_type
    from dual;
END;
/

-- trigger to prevent inserting a line with an invalid object name
CREATE OR REPLACE TRIGGER modification_log_ins_upd_trig
BEFORE INSERT OR UPDATE
ON modification_log
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
    vcount number;
BEGIN
    select count(*) into vcount
    from all_objects
    where object_name = :new.object_name;
    
    if vcount = 0 then
        raise_application_error(-20601, 'Object '|| :new.object_name|| ' does not exist.');
    end if;
END;
/

-- precompile trigger check
CREATE OR REPLACE TRIGGER pre_compile_check
AFTER CREATE
ON SCHEMA
DECLARE
    list_of_user varchar2(1000);
BEGIN

  if ora_dict_obj_type in ( 'PACKAGE', 'PACKAGE BODY', 'TRIGGER','FUNCTION', 'PROCEDURE') then
    for rec in (select * from modification_log where object_name = ora_dict_obj_name)
    loop
        list_of_user := list_of_user|| rec.developer_name; 
    end loop;
    
    if list_of_user is not null then
        raise_application_error(-20601, 'Cannot compile  '|| ora_dict_obj_name|| ' object. Consult developer: '
        ||chr(10)||list_of_user|| ' or check table modification_log for more information.'||chr(10)
        ||' sql: SELECT * FROM modification_log WHERE object_name = '''||ora_dict_obj_name||'''');
    end if;
  end if;
END pre_compile_check;
/