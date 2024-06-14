-- Q13.
create table Supplier(
    name            varchar(30),
    city            varchar(30),
    primary key     (name)  
);

create table Part(
    number          integer,
    colour          varchar(30),
    primary key     (number)
);

create table Supply(
    supplier        varchar(30),
    part            integer,
    quantity        integer,
    primary key     (supplier, part),
    foreign key     (supplier) references Supplier(name),
    foreign key     (part) references Part(number)
);

-- All of the elements from the ER design appear in the relational model and this SQL
