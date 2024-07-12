-- Q2
Employee(id:integer, name:text, works_in:integer, salary:integer, ...)
Department(id:integer, name:text, manager:integer, ...)

-- write an assertion to ensure that no employee in a department earns more than the manager of their department.
create assertion employee_manager_salary check ( 
    not exists (
        -- Cases where the employees salary is more than the manager
        select  * 
        from    Employee emp 
        join    Department d on (d.id = emp.works_in)
        join    Employee mgr on (d.manager = mgr.id)
        where   emp.salary > mgr.salary
    )
);


-- Q6
create table R(
    a int, 
    b int, 
    c text,
    primary key(a,b)
);

-- State how you could use triggers to implement the following constraint checking:
-- a. primary key constraint on relation R

-- The constraints for primary key(a,b) is:
    -- a or b cannot be null
    -- primary key needs to be unique i.e. (a,b) must not exist already in the db

-- We would want to check the pk before:
    -- before inserting a row
    -- before updating a row

create or replace function pk_check_R() returns trigger
as $$
begin
    -- enforce neither a or b can be null
    if (NEW.a is null or NEW.b is null) then
        raise exception 'primary key cannot be null!';
    end if;

    -- if updating and the new row's pk is identical to the updated one, 
    -- ignore pk check as pk has not been changed
    if (TG_OP = 'UPDATE' and OLD.a = NEW.a and OLD.b = NEW.b) then
        return NEW;
    end if; 

    -- primary key needs to be unique i.e. a,b combination doesn't already exist     
    select  * 
    from    R r 
    where   r.a = NEW.a 
            and r.b = NEW.b;

    if (FOUND) then
        raise exception 'primary key must be unique!';
    end if;

    return NEW; 
end; 
$$ language plpgsql

create trigger pk_trigger_R
before insert or update 
on R 
for each row 
execute procedure pk_check_R();

-- b. foreign key constraint between T.k and S.x
create table S(
    x int primary key,
    y int
);
create table T(
    j int primary key,
    k int references S(x)
);

-- What are the constraints on a foreign key?
    -- Referential integrity i.e. Every reference to something (foreign key) must actually refer to something that exists.

-- When would we want to fk check?
    -- before inserting/updating a T row, we need to check T.k refers to a key in S
    -- before deleting/updating a S row, we need to make sure no T.k refers to that S

-- Will be easiest to split it into 2 triggers because we are looking at separate tables

-- Trigger 1:
    -- before inserting/updating a T row, we need to check T.k refers to a key in S
create or replace function fk_check_T() returns trigger 
as $$
begin 

    -- new k must refer to an x key in S
    select  * 
    from    S 
    where   S.x = new.k;
    
    if (not found) then 
        raise exception 'Non-existent S.x key being referenced by T!';
    end if;

    return new;
end; 
$$ language plpgsql


create trigger fk_trigger_T
before insert or update 
on T 
for each row 
execute procedure fk_check_T();

-- Trigger 2: 
    -- before deleting/updating a S row, we need to make sure no T.k refers to that S
create or replace function refs_check_S() returns trigger 
as $$
begin 

    if (TG_OP = 'UPDATE' and old.x = new.x) then 
        return new;
    end if;

    -- when deleting/updating S, check if T has any references to S.x 
    select  * 
    from    T 
    where   T.k = old.x; 
    
    if (found) then 
        raise exception 'References to S.x from T!'
    end if;

    return new;
end; 
$$ language plpgsql


create trigger refs_trigger_S
before delete or update 
on S 
for each row 
execute procedure refs_check_S();


-- Q7. 
create table S(
    x int primary key,
    y int
);
-- Explain the difference between these triggers when executed with the following statements.
-- Assuming that S contains PK (1,2,3,4,5,6,7,8,9)
create trigger updateS1 after update on S
for each row execute procedure updateS();

create trigger updateS2 after update on S
for each statement execute procedure updateS();

-- a. 
update S set y = y + 1 where x = 5;
-- We are updating a single record 
-- For each row/ For each statement -> do the same thing (as we are only updating one row i.e. where x = 5)

-- b. 
update S set y = y + 1 where x > 5;
-- updateS1 trigger:
-- Records with x that are 6, 7, 8, 9 are updating
-- update 6 -> call updateS1
-- update 7 -> call updateS1
-- update 8 -> call updateS1
-- update 9 -> call updateS1
-- For each row calls the trigger function after every changed row

-- updateS2 trigger: 
-- For each statement
-- SQL statement updates 6,7,8,9
-- UpdateS2 is then called
-- For each statement calls the trigger ONCE after the rows have been changed

-- Q14.
-- Imagine that PostgreSQL did not have an avg() aggregate to compute the mean of a column of numeric values.
-- How could you implement it using a PostgreSQL user-defined aggregation definition (called mean)?
-- Assume that it ignores null values. If the column is empty (has no values) return null.

-- Step 1. What do I need to calculate the average?
    -- sum of all numbers
    -- count of numbers 

-- Step 2. Make the sType (values to carry throughout calculation)
create type AvgState as (sum numeric, count integer);
-- numeric can be integer, decimal, or money type

-- Step 3. What initial condition do I want for my state?
initcond = '(0, 0)'

-- Step 4. What kind of function do I need to keep an average as I go through the numbers? i.e. what will my sfunc be?
create or replace function mean_iterator(s AvgState, v numeric) returns AvgState
as $$
begin
    -- s and v are available without declaring because they are parameters
    -- v is null -> skip
    if (v is not null) then
        s.sum := s.sum + v;
        s.count := s.count + 1;
    end if;

    return s;
end;
$$ language plpgsql;

-- Step 5. What kind of function do I need to return the average from the final state? i.e. what will my finalfunc be?
-- In this case => return sum/count OR need to consider the case where there are no rows
    -- From question: Assume that it ignores null values. If the column is empty (has no values) return null.
create or replace function mean_final(s AvgState) returns numeric
as $$
begin
    -- If there were no rows, return null. 
    if (s.count = 0) then
        return null;
    end if;

    return s.sum / s.count::numeric; -- type cast is important due to / doing integer division by default
end;
$$ language plpgsql;

-- Step 6. FINALLY create our aggregate mean function!
create aggregate mean(numeric) (
    stype = AvgState,
    initcond = '(0, 0)', -- string type, weirdly it just is
    sfunc = mean_iterator,
    finalfunc = mean_final
);

-- You would use your new aggregate in the following way: 
select  mean(e.salary)
from    Employees e;
