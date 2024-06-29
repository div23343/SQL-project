create database zomato_analysis;
use zomato_analysis;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');
select * from goldusers_signup;


drop table if exists users;
CREATE TABLE users(userid integer,signup_date date);
INSERT INTO users
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');
select * from users;

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales
VALUES 
    (1, '2017-04-19', 2),
    (3, '2019-12-18', 1),
    (2, '2020-07-20', 3),
    (1, '2019-10-23', 2),
    (1, '2018-03-19', 3),
    (3, '2016-12-20', 2),
    (1, '2016-11-09', 1),
    (1, '2016-05-20', 3),
    (2, '2017-09-24', 1),
    (1, '2017-03-11', 2),
    (1, '2016-03-11', 1),
    (3, '2016-11-10', 1),
    (3, '2017-12-07', 2),
    (3, '2016-12-15', 2),
    (2, '2017-11-08', 2),
    (2, '2018-09-10', 3);
select * from sales;

drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);
select * from product;

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

#what is the total amount spent by each customer on zomato as per userid?
select s.userid, sum(p.price) as PRICE
from sales s
join product p on s.product_id=p.product_id
group by s.userid
order by s.userid;

#How many days has each customer visited zomato?
select userid, count(created_date) as distinct_days from sales
group by userid
order by userid;

#First product purchased by each of the customer?
select * from(select*, rank() over(partition by userid order by created_date) as rn from sales)x
				where rn=1;
                
#Most purchased item on the menu and how many times was it purchased by all the customers?
select product_id, count(product_id) as PRODUCT from sales
group by product_id
order by count(product_id) desc
LIMIT 1;

#Which item was most popular among customers?
WITH ranked_sales AS(select count(product_id) as cnt,rank()over(partition by userid order by count(product_id) desc)rn
 , userid, product_id from sales
						group by userid, product_id)
	SELECT userid, product_id, cnt
FROM ranked_sales
WHERE rn = 1;
show tables;

#Which item was first purchased by the customer after they became a member?
select*from(			select s.userid, s.created_date, s.product_id, g.gold_signup_date,
						row_number()over(partition by userid order by created_date) as rn
						from sales s join goldusers_signup g 
						on s.userid=g.userid
                        where s.created_date>g.gold_signup_date)x
                        where rn=1;
                        
#Which item was purchased just before the customer became a member?
select*from(			select s.userid, s.created_date, s.product_id, g.gold_signup_date,
						row_number()over(partition by userid order by created_date desc) as rn
						from sales s join goldusers_signup g 
						on s.userid=g.userid
                        where s.created_date<g.gold_signup_date)x
                        where rn=1;
                        
                        show tables;
                        
#What is the total orders and amount spent for each member before they became a member?
select s.userid,count(s.created_date)as total_orders, sum(p.price) as total_amount
from sales s join 
product p on s.product_id=p.product_id
join goldusers_signup g on s.userid=g.userid
where s.created_date<g.gold_signup_date
group by s.userid 
order by s.userid; 

#If buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points
#for eg for p1 5rs=1 zomato point, for p2 10rs=5 zomato point,for p3 5rs=1 zomato point, calculate points collected
#by each customers and for which product most points have been given till now.

with pointsper_user as		(			select s.userid, s.product_id,sum(p.price) as total_sales,
										sum(
										case when s.product_id= 1 then round((p.price/5)*1,1)
										when s.product_id= 2 then round((p.price/10)*5,1)
										when s.product_id= 3 then round((p.price/5)*1,1) else 0 end)
										as points
										from sales s join product p on s.product_id=p.product_id
										group by s.userid,s.product_id
										order by s.userid,s.product_id)
					select userid, product_id, total_sales,points,
                    sum(points)over(partition by product_id order by product_id) as SUM_POINTS
                    from pointsper_user 
                    order by product_id;

#In the first one year after a customer joins the gold program(including their join date) irrespective of what
#the customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3 
#and what was their points earning in their first year?
SELECT 
    s.userid, 
    SUM(p.price) AS total_spent,
    (SUM(p.price) / 10) * 5 AS total_points
FROM 
    sales s 
JOIN 
    goldusers_signup g ON s.userid = g.userid
JOIN 
    product p ON s.product_id = p.product_id
WHERE 
    s.created_date >= g.gold_signup_date 
    AND s.created_date < DATE_ADD(g.gold_signup_date, INTERVAL 1 YEAR)
    AND s.userid IN (1, 3)
GROUP BY 
    s.userid
ORDER BY 
     (SUM(p.price) / 10) * 5  DESC;
     
#rank all the transaction of the customers
select *,rank()over(partition by userid order by created_date) as rnk
from sales;

#rank all the transactions for each member whenever they are a zomato gold member for every non 
#gold member transaction mark as na
select s.*,g.gold_signup_date ,
case when s.created_date>=g.gold_signup_date then rank()over(partition by s.userid order by s.created_date) else 'NA' 
end as transaction_rank
from sales s join goldusers_signup g
on s.userid=g.userid
order by s.userid,s.created_date; 

#THE END










                
                        








