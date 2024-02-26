/*
Credit card transactions Data Exploration 

Skills used: CTE's, Windows Functions, Aggregate Functions, Case when.

*/

select * from credit_card_transcations
--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

 select top 5
 city,
 sum(amount) as total_spends,
 sum(amount)*100.0/(select sum(amount) from credit_card_transactions) as percentage_contribution
 from credit_card_transcations
 group by city
 order by total_spends desc;


--- 2- write a query to print highest spend month and amount spent in that month for each card type


with monthly_spent as(
select 
card_type,
datepart(year,transaction_date) as transaction_year,
datepart(month,transaction_date) as transaction_month,
sum(amount) as total_spent
from credit_card_transactions
group by card_type,
datepart(year,transaction_date),
datepart(month,transaction_date)
),
max_spend_per_card_type as (
select card_type,
transaction_year,
transaction_month,
total_spent,
ROW_NUMBER() over(partition by card_type order by total_spent desc) as rank
from monthly_spent
)
select 
card_type,
transaction_year,
transaction_month,
total_spent
from max_spend_per_card_type
where rank=1;


--3- write a query to print the transaction details(all columns from the table) for each card type when
---it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cumulative_spending as (select 
transaction_id,
card_type,
transaction_date,
amount,
sum(amount) over (partition by card_type order by transaction_date) as cumulative_spent
from credit_card_transactions
),
filtered_transaction as(
select 
transaction_id,
card_type,
transaction_date,
amount,
cumulative_spent
from cumulative_spending
where cumulative_spent>=1000000
)
select *
from filtered_transaction;


--4- write a query to find city which had lowest percentage spend for gold card type

with gold_card_spending as (select city,
sum(case when card_type='Gold' then amount else 0 end) as gold_card_total_spending,
sum(amount) as total_spending
from credit_card_transactions
group by city
),
percentage_spent1 as (
select city,
gold_card_total_spending,
total_spending,
(gold_card_total_spending*100.0/total_spending) as percentage_spent
from gold_card_spending
)
select
city
from percentage_spent1
where percentage_spent=(select min(percentage_spent) from percentage_spent1)


---5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)


with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transactions
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;

--6- write a query to find percentage contribution of spends by females for each expense type

select 
exp_type,
sum( case when gender='F' then amount else 0 end ) as female_spend,
sum(amount) as total_spend,
(sum(case when gender='F' then amount else 0 end )*100.0/sum(amount)) as female_spend_contribution 
from credit_card_transactions
group by 
exp_type
order by female_spend_contribution desc;


--7.which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type,
datepart(year,transaction_date) yt,
datepart(month,transaction_date) mt,
sum(amount) as total_spend
from credit_card_transactions
group by card_type,exp_type,
datepart(year,transaction_date),
datepart(month,transaction_date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;


 --8.during weekends which city has highest total spend to total no of transcations ratio 
 select top 1 city ,
 sum(amount)*1.0/count(1) as ratio
from credit_card_transactions
where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc;

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transactions)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 








