-- KPI: 월별(데이터 전체 기간) 세션 기반 구매 전환율 및 매출 성과 지표

-- [기간/단위]
--  - 월 단위 집계
--  - 세션 월 기준: ga_sess.visit_stime의 month
--  - 매출 월 기준: orders.order_time의 month  (※ 주문 발생 월 기준)

-- [구매 세션 정의]
--  - purchase_sessions: ga_sess_hits에서 action_type='6' 이벤트가 1회 이상 발생한 세션 수

-- [매출 정의]
--  - total_revenue: order_items.prod_revenue의 합 (주문 상품 매출 합)

--(1) 월별 세션, 구매 세션 집계 
with monthly_sessions as ( 
	select 
		-- 세션이 발생한 월 단위로 그룹화 (첫 날 기준 날짜)
		date_trunc('month', b.visit_stime)::date as sale_month,
		-- 해당 월 전체 고유 세션 수
		count(distinct a.sess_id) as total_sessions,
		-- action_type='6'(구매세션)인 세션 수   
		count(distinct case when a.action_type = '6' then a.sess_id end) as purchase_sessions
	from ga.ga_sess_hits a
		join ga.ga_sess b on a.sess_id = b.sess_id
	group by date_trunc('month', b.visit_stime)::date
),
--(2) 월별 매출 집계
monthly_revenue as ( 
	select 
		-- 주문이 발생한 월 단위로 그룹화
		date_trunc('month', a.order_time)::date as order_month,
		-- 해당 월 총 매출 합산
		sum(prod_revenue) as total_revenue
	from ga.orders a
		join ga.order_items b on a.order_id = b.order_id 
	group by date_trunc('month', a.order_time)::date
)
--(3) 두 CTE 합쳐서 최종 지표 산출
select 
	a.sale_month, a.purchase_sessions, a.total_sessions,  
	-- 구매 전환율(%): 구매 세션 / 전체 세션, NULL 방지를 위해 NULLIF 적용
	round(100.0 * purchase_sessions / NULLIF(total_sessions, 0), 2) as conversion_rate,
	round(b.total_revenue::numeric, 2) AS total_revenue, 
	-- 구매 세션당 평균 매출: 총 매출 / 구매 세션 수
	round((b.total_revenue::numeric / NULLIF(a.purchase_sessions, 0)::numeric), 2) as revenue_per_purchase_sess
from monthly_sessions a
	left join monthly_revenue b on a.sale_month = b.order_month
ORDER BY sale_month;