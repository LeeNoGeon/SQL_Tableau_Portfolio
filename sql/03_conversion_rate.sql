-- KPI: 채널별, 월별 구매 전환율 및 매출 성과 지표 산출

-- [구매 세션 정의] purchase_sessions: ga_sess_hits에서 action_type='6' 이벤트가 1회 이상 발생한 세션 수
-- [매출 기준] 매출은 주문이 발생한 세션(ga.orders.sess_id)의 유입 채널(ga_sess.channel_grouping)
-- [월 기준] 전환율은 세션 발생 월(visit_stime), 매출은 주문 발생 월(order_time) 기준으로 집계

--(1) 채널, 월별 세션 및 구매 세션 집계
with monthly_channel_sessions as ( 
	select 
		-- 유입 채널
		b.channel_grouping AS channel, 
		-- 세션 발생 월
		date_trunc('month', b.visit_stime)::date as sale_month,
		-- 해당 채널, 월 전체 고유 세션 수
		count(distinct a.sess_id) as total_sessions,
		-- action_type='6'(구매세션)인 세션 수
		count(distinct case when a.action_type='6' then a.sess_id end) as purchase_sessions   
	from ga.ga_sess_hits a
		join ga.ga_sess b on a.sess_id = b.sess_id
	group by b.channel_grouping, date_trunc('month', b.visit_stime)::date
),
--(2) 채널, 월별 매출 집계
monthly_channel_revenue as (
	select 
		-- 구매 세션의 유입 채널
		a.channel_grouping AS channel,
		-- 주문 발생 월
		date_trunc('month', b.order_time)::date as order_month,
		-- 해당 채널, 월 총 매출 합계
		sum(prod_revenue)::numeric as total_revenue
	from ga.ga_sess a 
		join ga.orders b on a.sess_id = b.sess_id 
		join ga.order_items c on b.order_id = c.order_id
	group by a.channel_grouping, date_trunc('month', b.order_time)::date
)
--(3) 세션/구매/매출 CTE를 결합하여 최종 지표 계산
select 
	a.channel, a.sale_month, a.purchase_sessions, a.total_sessions,
	-- 구매 전환율(%): 구매 세션 / 전체 세션
	round(100.0* purchase_sessions / NULLIF(total_sessions, 0), 2) as conversion_rate,
	-- 매출: 해당 채널, 월 총 매출 (없으면 0)
	round(COALESCE(b.total_revenue, 0), 2) as total_revenue,
	-- 구매 세션당 평균 매출: 총 매출 / 구매 세션 수
	round(COALESCE(b.total_revenue / NULLIF(purchase_sessions, 0), 0), 2) as revenue_per_purchase_sess
from monthly_channel_sessions a
	left join monthly_channel_revenue b on a.channel = b.channel and a.sale_month = b.order_month
-- 채널별·월별 순서로 정렬
order by channel, sale_month;