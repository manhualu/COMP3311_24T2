-- Practice Question. 
-- Find the pids of the most expensive part(s) supplied by suppliers named "Yosemite Sham".

-- Find the parts that are supplied by "Yosemite Sham"
create view 
    YosemiteSupplies(pid, cost)
as 
    select  c.pid, c.cost 
    from    Catalog c 
    join    Suppliers s on (s.sid = c.sid) 
    where   s.sname = 'Yosemite Sham'
;

-- From those parts select max(cost)
select  y1.pid 
from    YosemiteSupplies y1
where   y1.cost = (
                    select  max(y2.cost)
                    from    YosemiteSupplies y2
                  )
;

-- Q1. PLpgSQL square function
create or replace function 
    sqr(n integer) returns integer 
as $$ 
begin 
    return n * n; 
end; 
$$ language plpgsql;

-- Could we use this function in the following ways?
select sqr(5.0); --> NO, type inputted is float or numeric
select(5.0::integer); --> YES, input has been typecasted from float to integer
select sqr('5'); --> MAYBE, depends on version


-- Q2. PLpgSQL function that spreads the letters in some text
-- mydb=> select spread('My Text');
--      spread
--  M y  T e x t
create or replace function 
    spread(str text) returns text  
as $$ 
declare 
    i       integer;
    result  text := '';
begin 
    -- for strings in PLpgSQL first char is position 1. 
    for i in 1..length(str) loop 
        result := result || substring(str, i, 1) || ' ';
    end loop;

    return result;
end; 
$$ language plpgsql;

-- substr(str, i, 1) extracts a substring from str, it will start at position i (inclusive) and extract 1 char after position i
-- e.g. substr("hello", 2, 1) returns 'e'
-- https://www.w3resource.com/PostgreSQL/substring-function.php 


-- Beer Database
-- Combining SQL statements with functions
Beers(name:string, manufacturer:string)
Bars(name:string, address:string, license#:integer)
Drinkers(name:string, address:string, phone:string)
Likes(drinker:string, beer:string)
Sells(bar:string, beer:string, price:real)
Frequents(drinker:string, bar:string)

-- Q7: Return a text string of all names of Bars in a given suburb
-- Address only has a suburb

-- The + output at end of each line is to indicate that the string spans multiple lines. 
-- Is an ouput artifact. Says 1 row because it is a string that spans multiple lines.

-- Write a select statement that returns the names of all bars in a suburb
    -- select * from Bars where address = suburb
-- Loop through the results of this query and add it to a string 
create or replace function 
    hotelsIn(_addr text) returns text 
as $$ 
declare 
    r       record; -- would be (name, address, license#)
    result  text := '';
begin 
    for r in (
                select  * 
                from    Bars b 
                where   b.addr = _addr
             )
    loop 
        result := result || r.name || e'\n';
        -- e is an escape string. It escapes the \ for the newline.
        -- Be careful, stick to using '' in PLpgSQL!
    end loop;  

    return result; 
end; 
$$ language plpgsql;

-- If I wanted a table that returns the names on separate rows, NOT a giant string e.g. output:
--     hotelsin     
-- -----------------
--  Australia Hotel
--  Lord Nelson   

-- (4 row)

create or replace function 
    hotelsIn(_addr text) returns setof text  
as $$ 
declare 
    r   record;
begin 
    for r in (
                select  * 
                from    Bars b 
                where   b.addr = _addr
            )
    loop 
        return next r.name; -- this return next just returns each row, but does NOT end the function
    end loop;  
end; 
$$ language plpgsql;


-- Or to return back each tuple of Bars with all attributes, e.g. output:
--                 hotelsin                
-- ----------------------------------------
--  ("Australia Hotel","The Rocks",123456)
--  ("Lord Nelson","The Rocks",123888)
-- (2 rows)

-- create or replace function 
--     hotelsIn(_addr text) returns setof Bars
-- as $$ 
-- declare 
--     r   Bars; -- this would just be (name, address, license#) 
-- begin 
--     for r in (
--                 select * 
--                 from Bars b 
--                 where b.addr = _addr
--             )
--     loop 
--         return next r;
--     end loop;
   
-- end; 
-- $$ language plpgsql;


-- Q8: Return name of all bars in suburb
-- or return 'There are no bars in {suburb}'
create or replace function 
    hotelsIn(_addr text) returns text
as $$ 
declare 
    r       record; -- this would just be (name, address, license#) 
    result  text := ''; 
    numBars integer; 
begin
    -- can also use the found special variable to handle no bars in address e.g.
    -- select  *
    -- from    Bars b 
    -- where   b.address = _addr;

    -- if not found then 
    --     return 'There are no bars in ' || _addr;
    -- end if;

    select  count(*) into numBars
    from    Bars b 
    where   b.addr = _addr;

    if (numBars = 0)
    then
        return 'There are no bars in ' || _addr;
    end if;

    for r in (
                select  * 
                from    Bars b 
                where   b.address = _addr
             )
    loop 
        result := result || ' ' || r.name;
    end loop; 
   
    return 'Hotels in ' || _addr || ': ' || result;
end; 
$$ language plpgsql;


-- Bank Database
Branches(location:text, address:text, assets:real)
Accounts(holder:text, branch:text, balance:real)
Customers(name:text, address:text)
Employees(id:integer, name:text, salary:real)

-- Q12. Write both an SQL and PLpgSQL function for following: 
-- a. return salary of an employee
    -- Assume name or id identifies only one employee
create or replace function 
    empSal(text) returns real
as $$
    select  e.salary 
    from    Employees e 
    where   e.name = $1;
$$ language sql; 

create or replace function 
    empSal(empName text) returns real 
as $$
declare 
    sal real;
begin
    select  e.salary into sal 
    from    Employees e 
    where   e.name = empName;

    return sal;
end;
$$ language plpgsql; 

-- b. return all details of a particular branch location [SKIP if no time]
create or replace function 
    branchDeets(text) returns Branches
as $$
    select  * 
    from    Branches b
    where   b.location = $1;
$$ language sql;

create or replace function 
    branchDeets(branchLocation text) returns Branches
as $$
declare 
    result Branches;
begin
    select  * into result 
    from    Branches b
    where   b.location = branchLocation;

    return result;
end
$$ language plpgsql;

-- c. return employee names earning more than specified salary [SKIP if no time]
create or replace function 
    empsWithSal(real) returns setof text
as $$
    select  e.name 
    from    Employees e
    where   e.salary > $1;
$$ language sql;

create or replace function 
    empsWithSal(_minSal real) returns setof EmpName
as $$
declare
    empName text;
begin
    for empName in (
                        select  e.name
                        from    Employees e
                        where   e.salary > _minSal
                   )
    loop
        return next empName;
    end loop;

    return;
end;
$$ language plpgsql;

-- d. return details of highly paid employees [SKIP if no time]
create or replace function 
    highlyPaid(real) returns setof Employees
as $$
    select  * 
    from    Employees e
    where   e.salary > $1;
$$ language sql;

create or replace function 
    highlyPaid(_minSal real) returns setof Employees
as $$
declare
    empDeets Employee; -- or type record
begin
    for empDeets in (
                        select  *
                        from    Employees e 
                        where   e.salary > _minSal
                    )
    loop
        return next _e;
    end loop;
    return;
end;
$$ language plpgsql;


-- Q13. produce a report giving: 
--      name and address of branch, 
--      list of customers who hold accounts at branch,
--      total amount in accounts held at branch
-- Example Output: 
--  Branch: Clovelly, Clovelly Rd.
--  Customers:  Chuck Ian James
--  Total deposits: $   8860.00

-- STEPS 
-- Go through each branch 
    -- Get the name and address of that branch
    -- Get all the customers in THAT branch, get their names
    -- Get the total sum(amount) of accounts in that branch
create or replace function 
    branchList() returns text 
as $$ 
declare 
    branch record; 
    result text := '';
    account record; 
    totalDeposits real;
begin 
    for branch in (
                    select * 
                    from Branches 
                  )
    loop
        -- Get the branch location and address
        result := result || 'Branch: ' || brance.location || branch.address || '.' || e'\n' || 'Customers: ';
        -- Result looks like currently: 
            -- Branch: Clovelly, Clovelly Rd.\n
            -- Customers:  
        
        -- Gets the customer names in that branch
        for account in (
                        select  * 
                        from    Accounts a 
                        where   a.branch = branch.location
                       )
        loop 
            result := result || account.holder || ' ';
        end loop; 
        -- Result looks like currently: 
            -- Branch: Clovelly, Clovelly Rd.\n
            -- Customers:  Chuck Ian James
        
        -- Gets the total deposit of the accounts in that branch
        select  sum(a.balance) into totalDeposits
        from    Accounts a    
        where   a.branch = branch.location;

        result := result || e'\nTotal deposits: ' || to_char(totalDeposits, '$999999.99') || e'\n';

    end loop;

    return result;
end; 
$$ language plpgsql;

-- to_char(value, desired_format) function. The second argument ensures that your value of type real is converted into that format i.e. with 2 decimal places
-- the extra 9s before the dpl ensure the spaces is left empty and 8860.00 value is indented left like: 
    -- Total deposits: $   8860.00
