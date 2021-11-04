select account_id, COUNT(*) as negatives,
case when count(*) =1 then '!'
when count(*) <=3 then '!!'
when count(*) >=4 then '!!!' end as warning /*into project.warning*/
from (
select account_id,type,amount,balance,lag(balance,1) over (partition by account_id order by date) as previous_balance, date from project.trans) as x
where balance <0 and previous_balance>0
group by account_id
order by negatives


select L.account_id,customerrating, coalesce(warning,'*') as warning /*into project.vscheme*/ from project.customerrating as l
left outer join project.warning as r
on L.account_id = r.account_id

