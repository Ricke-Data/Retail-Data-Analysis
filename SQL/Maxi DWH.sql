--Kreiranje tabele dim_date
create table dim_date (
date_id int primary key,
"date" timestamp,
"year" int,
"month" int,
"day" int,
week int,
quarter char(2),
semester char(2),
month_name varchar2(20),
day_in_week varchar2(11),
number_day_in_month int,
work_day_indicator char(1)
);
--Kreiranje tabele dim_store
create table dim_store (
dim_store_id int primary key,
store_id int,
name varchar2(30),
location varchar2(30),
city varchar2(20),
country varchar2(15)
);
--Kreiranje tabele dim_cashier
create table dim_cashier (
dim_cashier_id int primary key,
cashier_id int,
name varchar2(35),
hire_date date
);
--Kreiranje tabele dim_product
create table dim_product (
dim_product_id int primary key,
product_id int,
name varchar2(25),
category varchar2(15),
price number
);
--Kreiranje tabele dim_promotion
create table dim_promotion (
dim_promotion_id int primary key,
promotion_id int,
promotion_name varchar2(35),
discount_percentage varchar2(5),
start_date timestamp,
end_date timestamp
);
--Kreiranje tabele dim_payment
create table dim_payment (
dim_payment_id int primary key,
payment_id int,
full_payment_method varchar2(20),
payment_method varchar2(10),
method_name varchar2(15)
);
--Kreiranje tabele fact_receipt_item
create table fact_receipt_item (
fact_receipt_item_id int primary key,
date_id int,
dim_store_id int,
dim_cashier_id int,
dim_product_id int,
dim_promotion_id int,
dim_payment_id int,
quantity_sold number,
unit_price number,
total_price number,
discount_amount number,
final_price number,
foreign key (date_id) references dim_date(date_id),
foreign key (dim_cashier_id) references dim_cashier(dim_cashier_id),
foreign key (dim_store_id) references dim_store(dim_store_id),
foreign key (dim_product_id) references dim_product(dim_product_id),
foreign key (dim_payment_id) references dim_payment(dim_payment_id),
foreign key (dim_promotion_id) references dim_promotion(dim_promotion_id)
);
alter table fact_sales add receipt_number varchar2(50);
--Kreiranje tabele fact_receipt
create table fact_receipt (
fact_receipt_id int primary key,
date_id int,
dim_store_id int,
dim_cashier_id int,
dim_promotion_id int,
dim_payment_id int,
receipt_number varchar2(50),
total_amount number,
total_discount number,
final_amount number,
foreign key (date_id) references dim_date(date_id),
foreign key (dim_cashier_id) references dim_cashier(dim_cashier_id),
foreign key (dim_store_id) references dim_store(dim_store_id),
foreign key (dim_payment_id) references dim_payment(dim_payment_id)
);
--Kreiranje sekvenci
create sequence dim_store_seq start with 1 increment by 1;
create sequence dim_cashier_seq start with 1 increment by 1;
create sequence dim_product_seq start with 1 increment by 1;
create sequence dim_promotion_seq start with 1 increment by 1;
create sequence dim_payment_seq start with 1 increment by 1;
create sequence fact_receipt_item_seq start with 1 increment by 1;
create sequence fact_receipt_seq start with 1 increment by 1;
--Brisanje
delete from dim_date commit;
--Provera BI app
select count(*) from fact_receipt fri join dim_cashier dc on fri.dim_cashier_id = dc.dim_cashier_id
where dc.name like '%Gorda%';

select sum(fri.quantity_sold) from fact_receipt_item fri join MAXI.receipt ri on fri.receipt_number = ri.receipt_id
where fri.dim_product_id = 116;
--Brisanje svih podataka
truncate table fact_receipt;
truncate table fact_receipt_item;
truncate table dim_date;
truncate table dim_store;
truncate table dim_cashier;
truncate table dim_product;
truncate table dim_promotion;
truncate table dim_payment;