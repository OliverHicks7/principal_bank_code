use dp05_puffin


select account_id, AVG (balance) as average_balance,percent_rank() over ( order by avg(balance)) as percentile, 
case when percent_rank() over ( order by avg(balance)) <= 0.2 then 'E' 
 when percent_rank() over ( order by avg(balance)) <= 0.4 then 'D' 
 when percent_rank() over ( order by avg(balance)) <= 0.6 then 'C' 
 when percent_rank() over ( order by avg(balance)) <= 0.8 then 'B' 
  when percent_rank() over ( order by avg(balance)) <= 1 then 'A' 
  end as rank /*into project.account_size_rank*/
from project.trans
group by account_id 
order by average_balance asc

