
use dp05_puffin


--creates average yearly in vs out tables--
select account_id, AVG(account_difference) as average /*into project.averagedifference*/ from (
						select l.account_id,l.year, (l.year_in - r.year_out) as account_difference from 
(
select account_id,YEAR, SUM(amount) as year_in from(
select account_id, YEAR(date) as year, type,amount,balance  from project.trans
where type='prijem')
 as x
  group by X.year,x.account_id ) as l
inner join 
(
select account_id,YEAR, SUM(amount) as year_out from(
select account_id,YEAR(date) as year, type,amount,balance  from project.trans
where type='vydaj')
 as y
  group by y.year, y.account_id ) as r
 on r.year = l.year and r.account_id=l.account_id
)as t
group by account_id
order by account_id


--assings rank--
select *, percent_rank() over ( order by average) as percentile, 
case when percent_rank() over ( order by average) <= 0.2 then 'E' 
 when percent_rank() over ( order by average) <= 0.4 then 'D' 
 when percent_rank() over ( order by average) <= 0.6 then 'C' 
 when percent_rank() over ( order by average) <= 0.8 then 'B' 
  when percent_rank() over ( order by average) <= 1 then 'A' 
end as grade /*into project.spending_habits_work*/ from project.averagedifference

