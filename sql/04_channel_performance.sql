-- 목표: 2016-10월 채널별 방문·주문·매출 지표로 채널 효율 비교
--  - 방문자(고유) 기준 분모: unique_visitors
--  - 주문자(고유) 기준 분모: ordering_users
--  - 매출 정의: order_items.prod_revenue의 합(=주문별 아이템 매출 합계)

--  1) order_items는 주문(order_id) 당 여러 행이므로,
--     먼저 order_id 단위로 매출을 집계(order_revenue)한 뒤
--  2) 세션(ga_sess)을 기준 집합으로 유지하기 위해 LEFT JOIN으로 주문을 결합.
--     주문이 없는 방문도 채널 방문자 수에 포함됨

-- [1] 주문(order_id) 단위 매출 집계
WITH order_revenue AS (
 	SELECT
    	oi.order_id,
    	SUM(oi.prod_revenue) AS order_revenue
  	FROM ga.order_items oi
  	GROUP BY oi.order_id
),
-- [2] 10월 세션 + 주문 결합 (세션 기준 집합 유지)
--     - 세션은 채널/방문자 집계의 기준이므로 ga_sess를 base로 둠
--     - 주문이 없는 세션도 유지하기 위해 LEFT JOIN 사용
--     - 주문 매출은 order_revenue(주문당 1행)로 붙여 중복 방지
session_orders AS (
	SELECT
    	s.sess_id,
    	s.user_id,
    	s.channel_grouping AS channel,
    	o.order_id,
    	COALESCE(orv.order_revenue, 0) AS order_revenue
  	FROM ga.ga_sess s
  	LEFT JOIN ga.orders o
    	ON s.sess_id = o.sess_id
  	LEFT JOIN order_revenue orv
    	ON o.order_id = orv.order_id
  	WHERE s.visit_stime >= '2016-10-01' AND s.visit_stime < '2016-11-01'
)
-- [3] 채널별 KPI 집계
--     - total_revenue: 주문 매출 합계
--     - unique_visitors: 채널별 고유 방문자 수
--     - ordering_users: 주문을 발생시킨 고유 사용자 수
--     - revenue_per_visitor: 방문자 1인당 매출(운영 효율)
--     - revenue_per_ordering_user: 주문자 1인당 매출(구매자 가치)
--     * NULLIF로 분모 0(주문자 0명 채널 등) 방어
SELECT
	channel,
  	ROUND(SUM(order_revenue)::numeric, 3) AS total_revenue,
  	COUNT(DISTINCT user_id) AS unique_visitors,
  	COUNT(DISTINCT CASE WHEN order_id IS NOT NULL THEN user_id END) AS ordering_users,
  	ROUND((SUM(order_revenue) / NULLIF(COUNT(DISTINCT user_id), 0))::numeric, 3) AS revenue_per_visitor,
  	ROUND((SUM(order_revenue) / NULLIF(COUNT(DISTINCT CASE WHEN order_id IS NOT NULL THEN user_id END), 0))::numeric, 3) AS revenue_per_ordering_user
FROM session_orders
GROUP BY channel
ORDER BY unique_visitors DESC;