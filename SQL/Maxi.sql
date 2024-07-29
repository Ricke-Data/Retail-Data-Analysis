--Kreiranje tabele store
CREATE TABLE Store (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100),
    city VARCHAR(100),
    address VARCHAR(255)
);
--Kreiranje tabele employee
CREATE TABLE Employee (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    store_id INT,
    FOREIGN KEY (store_id) REFERENCES Store(store_id)
);
--Kreiranje tabele promotion
create table promotion (
promotion_id int primary key,
promotion_name varchar2(35),
discount_percentage number(4,2),
start_date timestamp,
end_date timestamp,
foreign key (product_id) references product(product_id)
);
--Kreiranje tabele product
CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    product_category VARCHAR(100),
    price NUMBER(10, 2),
    promotion_id int,
    foreign key (promotion_id) references promotion (promotion_id)
);
--Kreiranje tabele payment
create table payment (
payment_id int primary key,
payment_method varchar2(25)
);
/*
CREATE TABLE Customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20)
);
*/
--Kreiranje tabele receipt
CREATE TABLE Receipt (
    receipt_id INT PRIMARY KEY,
    store_id INT,
    --customer_id INT,
    employee_id INT,
    date_time TIMESTAMP,
    FOREIGN KEY (store_id) REFERENCES Store(store_id),
    --FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
);
create sequence receipt_seq start with 1 increment by 1;
--Kreiranje tabele receipt_item
CREATE TABLE receipt_item (
    receipt_item_id INT PRIMARY KEY,
    receipt_id INT,
    product_id INT,
    quantity INT,
    total_price NUMBER(10, 2),
    FOREIGN KEY (receipt_id) REFERENCES Receipt(receipt_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);
create sequence receipt_item_seq start with 1 increment by 1;

--Naknadno menjanje kolona
alter table product add (promotion_id int);
alter table product add foreign key (promotion_id) references promotion (promotion_id);
--Unos podataka u tabelu receipt i item
alter table receipt add (payment_id int,foreign key (payment_id) references payment (payment_id));
alter table receipt add (total_price number);
alter table receipt_item add (promotion_id int,foreign key (promotion_id) references promotion (promotion_id));
alter table receipt_item add (new_total_price number);
--Unos podataka u tabelu payment
insert into payment select * from maloprodaja.payment; -- values (1,'Cash');
insert into payment values (2,'Dina Card');
insert into payment values (3,'Visa Card');
insert into payment values (4,'Master Card');
insert into payment values (5,'Maestro Card');
insert into payment values (6,'Amex Card');
insert into payment values (7,'IPS Sken');
--Unos podataka u tabelu store
INSERT INTO store select * from maloprodaja.store; -- VALUES (1,'Maxi 471','Cacak','Svetozara Markovica 79');
INSERT INTO store VALUES (2,'Mega Maxi','Cacak','Zeleznicka 2');
INSERT INTO store VALUES (3,'Veliki Maxi','Cacak','Dragise Misovica 64');
INSERT INTO store VALUES (4,'Maxi 693','Kragujevac','Nocnih Brigada 12');
INSERT INTO store VALUES (5,'Mega Maxi','Kraljevo','Zitska 31');
--Unos podataka u tabelu employee
INSERT INTO employee select * from maloprodaja.employee; -- VALUES (1,'Gordanana','Savovivovic',1);
INSERT INTO employee VALUES (2,'Pe?a','Sremcevic',1);
INSERT INTO employee VALUES (3,'Vesnana','Krivokapic',2);
INSERT INTO employee VALUES (4,'Irenana','Nakostresic',2);
INSERT INTO employee VALUES (5,'Nikolinana','Sestic',3);
INSERT INTO employee VALUES (6,'Jelenana','Puzic',3);
INSERT INTO employee VALUES (7,'Milenana','Smerovic',4);
INSERT INTO employee VALUES (8,'Jovanana','Tepic',4);
INSERT INTO employee VALUES (9,'Snezanana','Kisic',5);
INSERT INTO employee VALUES (10,'Marijanana','Evic',5);
--Unos podataka u tabelu product
INSERT INTO product select * from maloprodaja.product; -- VALUES (1,'Plazma 300g','Keks',320,1);
INSERT INTO product VALUES (2,'Milka Lesnik 100g','Cokolada',150,2);
INSERT INTO product VALUES (3,'Najlepse Zelje Keks 100g','Cokolada',135,2);
INSERT INTO product VALUES (4,'Cacanski Rebrasti 250g','Cips',280,10);
INSERT INTO product VALUES (5,'Cipsy Slani 100g','Cips',140,4);
INSERT INTO product VALUES (6,'Jaffa 200g','Keks',180,10);
INSERT INTO product VALUES (7,'Grisky 90g','Grisine',75,10);
--Unos podataka u tabelu promotion
insert into promotion select * from maloprodaja.promotion; -- values (1,'Pcelica',50,systimestamp,systimestamp + interval '7' day);
insert into promotion values (2,'Coko Njami',15,systimestamp,systimestamp + interval '5' day);
insert into promotion values (3,'Coko Njami',15,systimestamp,systimestamp + interval '5' day);
insert into promotion values (10,'NO PROMOTION',NULL,systimestamp,systimestamp + interval '25' YEAR);
insert into promotion values (4,'Cipsy Way',30,to_timestamp('25/06/24 00:00','dd/mm/yy hh24:mi'),
                                                 to_timestamp('30/06/24 23:59','dd/mm/yy hh24:mi'));

--Kreiranje kolekcije za unos proizvoda i kolicine
create or replace type receipt_item_obj is object (
product_id int,
quantity number
);
create or replace type receipt_item_tab is table of receipt_item_obj;

--Kreiranje procedure za unos stavki sa racuna
create or replace procedure addreceipt (
p_store_id int,
p_employee_id int,
p_payment_id int,
p_items receipt_item_tab
) is
v_receipt_id int;
v_price number;
v_discount number;
v_product varchar2(35);
v_sum_price number := 0;
v_total_price number;
v_promotion_id int;
v_dt timestamp;
begin
  insert into receipt values (receipt_seq.nextval,p_store_id,p_employee_id,systimestamp,p_payment_id,null,systimestamp)
  returning receipt_id into v_receipt_id;
  
  select date_time into v_dt from receipt where receipt_id = v_receipt_id;
  
  for i in 1..p_items.count loop
    select price into v_price from product where product_id = p_items(i).product_id;

    begin
      select promotion_id,discount_percentage into v_promotion_id,v_discount from promotion 
      where promotion_id = (select promotion_id from product where product_id = p_items(i).product_id)
      and systimestamp between start_date and end_date;
      v_total_price := v_price * p_items(i).quantity * (1 - v_discount / 100);
    exception
      when no_data_found then
        v_promotion_id := 10;
        v_discount := null;
        v_total_price := null;
      when others then
        dbms_output.put_line('Desila se iznenadna greska prilikom racunanja popusta!');
    end;
    
    insert into receipt_item values (receipt_item_seq.nextval,v_receipt_id,p_items(i).product_id,
    p_items(i).quantity,v_price * p_items(i).quantity,v_promotion_id,v_total_price,v_dt);
    select product_name into v_product from product where product_id = p_items(i).product_id;
    dbms_output.put_line('Uspesno ste uneli proizvod '||v_product||', kolicina '||p_items(i).quantity
    ||', ukupna'||case when v_total_price is not null then ' cena sa popustom: '||v_total_price else 
    ' cena: '||v_price * p_items(i).quantity end||' dinara.');
    v_sum_price := v_sum_price + case when v_total_price is not null then v_total_price else
                   v_price * p_items(i).quantity end;
  end loop;
    update receipt set total_price = v_sum_price where receipt_id = v_receipt_id;
    dbms_output.put_line('Ukupan iznos racuna broj '||v_receipt_id||' je '||v_sum_price||' dinara.');
exception
  when no_data_found then
    dbms_output.put_line('Nije pronadjen nijedan podatak!');
  when others then
    dbms_output.put_line('Desila se iznenadna greska!');
end;
--Unos u tabelu receipt
insert into receipt select * from maloprodaja.receipt;
--Unos u tabelu receipt_item
insert into receipt_item select * from maloprodaja.receipt_item;
--azuriranje receipt tabele
update receipt r set total_price = (select sum(ri.total_price) from receipt_item ri where 
ri.receipt_id = r.receipt_id group by ri.receipt_id) where exists (select 1 from receipt_item ri
where ri.receipt_id = r.receipt_id);
--Azuriranje receipt tabele
update receipt_item set promotion_id = 10 where promotion_id is null;
update receipt set payment_id = 1 where receipt_id between 1 and 10;
update receipt set payment_id = 2 where receipt_id between 11 and 20;
update receipt set payment_id = 3 where receipt_id between 21 and 30;
update receipt set payment_id = 4 where receipt_id between 31 and 40;
update receipt set payment_id = 5 where receipt_id between 41 and 50;
update receipt set payment_id = 6 where receipt_id between 51 and 60;
update receipt set payment_id = 7 where receipt_id between 59 and 69;
--Provera
SELECT count(*) FROM RECEIPT_ITEM JOIN RECEIPT ON RECEIPT_ITEM.RECEIPT_ID = RECEIPT.RECEIPT_ID 
WHERE RECEIPT_ITEM.LAST_UPDATED = RECEIPT.DATE_TIME; --AND RECEIPT.RECEIPT_ID = 75
select sum(ri.quantity),p.promotion_name,s.store_name from receipt_item ri join receipt r on 
ri.receipt_id = r.receipt_id join store s on s.store_id = r.store_id join promotion p on
ri.promotion_id = p.promotion_id
group by p.promotion_name,s.store_name;

select sum(ri.quantity) from receipt_item ri join receipt r on ri.receipt_id = r.receipt_id join
product p on ri.product_id = p.product_id
where p.product_id in (2,3) and r.store_id = 1
group by p.promotion_name,s.store_name;

--Ispravka greske u receipt_item za date_time
DECLARE
V_RECEIPT INT := 1;
BEGIN
WHILE V_RECEIPT < 90 LOOP
UPDATE RECEIPT_ITEM SET LAST_UPDATED = (SELECT DATE_TIME FROM RECEIPT WHERE RECEIPT_ID = V_RECEIPT)
WHERE RECEIPT_ID = V_RECEIPT;
V_RECEIPT := V_RECEIPT + 1;
END LOOP;
END;
--Azuriranje receipt_item
update receipt_item set promotion_id = 2 where product_id in (2,3);
update receipt_item set new_total_price = total_price - (total_price*15/100) 
where product_id in (2,3) and new_total_price is null;

update receipt_item set promotion_id = 1 where product_id = 1 and new_total_price is null;
update receipt_item set new_total_price = total_price - (total_price*50/100) 
where product_id = 1 and new_total_price is null;

alter table product add (promotion_id int, foreign key (promotion_id) references promotion (promotion_id));
update receipt_item set promotion_id = 2 where promotion_id = 3;

update receipt_item set promotion_id = 1 where product_id = 1;
update receipt_item set promotion_id = 1 where product_id = 1;
update receipt_item set promotion_id = 1 where product_id = 1;
--Kreiranje triggera za proveru prodavnice i kasira
create or replace trigger check_receipt
before insert or update on receipt
for each row
declare
  v_store_id employee.store_id%type;
begin
  select store_id into v_store_id
  from employee where employee_id = :new.employee_id;
  if :new.store_id != v_store_id then
    raise_application_error(-20001,'Ne mozete uneti drugu prodavnicu za unetog zaposlenog! 
    Mora biti uneta prodavnica u kojoj zaposleni radi!');
  end if;
exception
  when no_data_found then
    raise_application_error(-20002,'Zaposleni sa datim ID ne postoji!');
  when others then
    raise_application_error(-20003,'Doslo je do neocekivane greske: '||sqlerrm);
end;

--Azuriranje racuna
update receipt set employee_id = 1 where store_id = 1 and receipt_id between 1 and 35;
update receipt set employee_id = 2 where store_id = 1 and receipt_id between 36 and 67;
update receipt set employee_id = 3 where store_id = 2 and receipt_id between 1 and 35;
update receipt set employee_id = 4 where store_id = 2 and receipt_id between 36 and 67;
update receipt set employee_id = 5 where store_id = 3 and receipt_id between 1 and 35;
update receipt set employee_id = 6 where store_id = 3 and receipt_id between 36 and 67;
update receipt set employee_id = 7 where store_id = 4 and receipt_id between 1 and 35;
update receipt set employee_id = 8 where store_id = 4 and receipt_id between 36 and 67;
update receipt set employee_id = 9 where store_id = 5 and receipt_id between 1 and 35;
update receipt set employee_id = 10 where store_id = 5 and receipt_id between 36 and 67;

--dodavanje hire_date kolone
alter table employee add hire_date date;
--dodavanje last_updated kolona
alter table employee add last_updated timestamp;
alter table payment add last_updated timestamp;
alter table product add last_updated timestamp;
alter table promotion add last_updated timestamp;
alter table receipt add last_updated timestamp;
alter table receipt_item add last_updated timestamp;
alter table store add last_updated timestamp;
update employee set last_updated = systimestamp;
update payment set last_updated = systimestamp;
update product set last_updated = systimestamp;
update promotion set last_updated = systimestamp;
update receipt set last_updated = systimestamp;
update receipt_item set last_updated = systimestamp;
update store set last_updated = systimestamp;
--triger za store
create or replace trigger lu_store
before update on store
for each row
begin
  :new.last_updated := systimestamp;
end;
--triger za employee
create or replace trigger lu_employee
before update on employee
for each row
begin
  :new.last_updated := systimestamp;
end;
--triger za product
create or replace trigger lu_product
before update on product
for each row
begin
  :new.last_updated := systimestamp;
end;
--triger za promotion
create or replace trigger lu_promotion
before update on promotion
for each row
begin
  :new.last_updated := systimestamp;
end;
--triger za payment
create or replace trigger lu_payment
before update on payment
for each row
begin
  :new.last_updated := systimestamp;
end;
--triger za receipt
create or replace trigger lu_receipt
before update on receipt
for each row
begin
  :new.last_updated := systimestamp;
end;
--triger za receipt_item
create or replace trigger lu_receipt_item
before update on receipt_item
for each row
begin
  :new.last_updated := systimestamp;
end;

--Provera podataka
select dd.date_id,r.receipt_id,ds.dim_store_id,dc.dim_cashier_id, dp.dim_product_id,
dpr.dim_promotion_id, dpa.dim_payment_id,ri.quantity, p.price,ri.total_price,
nvl(ri.total_price * pr.discount_percentage/100,0),nvl(ri.new_total_price,ri.total_price)
from receipt_item ri join receipt r on ri.receipt_id = r.receipt_id
join store s on r.store_id = s.store_id
join employee e on r.employee_id = e.employee_id
join product p on ri.product_id = p.product_id
join promotion pr on ri.promotion_id = pr.promotion_id
join payment pa on r.payment_id = pa.payment_id
join MAXIDWH.dim_date dd on trunc(ri.last_updated) = trunc(dd."DATE")
join MAXIDWH.dim_store ds on s.store_id = ds.store_id 
join MAXIDWH.dim_cashier dc on e.employee_id = dc.cashier_id
join MAXIDWH.dim_product dp on p.product_id = dp.product_id
join MAXIDWH.dim_promotion dpr on pr.promotion_id = dpr.promotion_id
join MAXIDWH.dim_payment dpa on pa.payment_id = dpa.payment_id;
--Brisanje podataka iz tabela
truncate table receipt_item;
truncate table receipt;

--Provera
select dd.date_id,ds.dim_store_id,dc.dim_cashier_id, dpa.dim_payment_id,
r.receipt_id,sum(ri.total_price),
sum(ri.TOTAL_PRICE) - r.total_price,r.total_price
from receipt r join receipt_item ri on r.receipt_id = ri.receipt_id
join store s on r.store_id = s.store_id
join employee e on r.employee_id = e.employee_id
join payment pa on r.payment_id = pa.payment_id
join MAXIDWH.dim_date dd on trunc(r.last_updated) = trunc(dd."DATE")
join MAXIDWH.dim_store ds on s.store_id = ds.store_id 
join MAXIDWH.dim_cashier dc on e.employee_id = dc.cashier_id
join MAXIDWH.dim_payment dpa on pa.payment_id = dpa.payment_id
group by r.receipt_id,dd.date_id,ds.dim_store_id,dc.dim_cashier_id, dpa.dim_payment_id,r.total_price;

--Unos podataka sa racuna
declare
  items receipt_item_tab;
begin
  items := receipt_item_tab(receipt_item_obj(4,9),
  receipt_item_obj(2,6),
  receipt_item_obj(3,9),
  receipt_item_obj(9,6),
  receipt_item_obj(7,4),
  receipt_item_obj(8,5),
  receipt_item_obj(1,4),
  receipt_item_obj(5,12),
  receipt_item_obj(6,19)
  );
  addreceipt(3,6,6,items);
end;

--Unos 2
declare
  items receipt_item_tab;
begin
  items := receipt_item_tab(receipt_item_obj(1,1),
  receipt_item_obj(2,1),
  receipt_item_obj(3,2),
  receipt_item_obj(4,3),
  receipt_item_obj(5,1),
  receipt_item_obj(9,2)
  );

  addreceipt(1,1,1,items);
end;

--Kreiranje pogleda ukupno placanja po prodavnicama
create or replace view stores_total_payments
as
select s.store_name, sum(case when p.payment_method like '%Card%' then 1 else 0 end)as card,
sum(case when p.payment_method like '%Cash%' then 1 else 0 end)as cash,
sum(case when p.payment_method like '%Sken%' then 1 else 0 end)as scan
from payment p join receipt r on p.payment_id = r.payment_id
join store s on s.store_id = r.store_id
group by s.store_name
order by card desc,cash desc,scan desc;