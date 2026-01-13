-- KPI: 2016-10 페이지별 이탈률(Bounce Rate) 계산
-- 목적: 페이지별로 '해당 페이지에서 세션이 1페이지뷰(PAGE hit 1회)로 종료되는 비율'을 파악
-- 정의(본 쿼리 기준):
--  - Bounce session: 세션 내 PAGE hit 수가 1인 세션
--  - Entry session: 세션의 첫 PAGE hit의 page_path가 해당 페이지인 세션
--  - Bounce Rate(%): bounce_sessions_cnt / entry_sessions_cnt * 100

-- (1) 세션별 PAGE hit 정보 + 세션 내 PAGE hit 수 + 첫 PAGE 경로 추출
with 
session_page_hits as ( 
	select 
		a.page_path,	-- 페이지 경로
		b.sess_id, 	    -- 세션 ID
		a.hit_seq,      -- 세션 내 히트 순서
		a.hit_type,     -- 히트 유형
		a.action_type,  -- 액션 세부 유형
		-- 세션 내 PAGE hit 수 (bounce 판정용)
		count(*) over(partition by b.sess_id rows between unbounded preceding and unbounded following) as sess_cnt,
		-- 세션의 첫 PAGE hit의 page_path (진입 페이지 판정용)
		first_value(page_path) over(partition by b.sess_id order by hit_seq	) as first_page_path
	from ga.ga_sess_hits a
		join ga.ga_sess b on a.sess_id = b.sess_id 
	-- 분석 기준일(:current_date) 직전 30일간의 히트만 포함
	where visit_stime >= '2016-10-01' and visit_stime < '2016-11-01'
	and a.hit_type = 'PAGE'
),
-- (2) 페이지별 세션 및 이탈 집계
page_stats as (
	select 
		-- 페이지 경로
		page_path, 
		-- 해당 페이지의 PAGE hit 수(=페이지뷰 수)
		count(*) as page_view_cnt,  
		-- 세션 내 PAGE hit 수가 1인 경우를 합산(= bounce session 수로 해석)
		sum(case when sess_cnt = 1 then 1 else 0 end) as bounce_sessions_cnt,
		-- 해당 페이지가 세션의 첫 PAGE인 경우의 고유 세션 수(진입 세션)
		count(distinct case when first_page_path = page_path then sess_id else null end) as entry_sessions_cnt
	from session_page_hits
	group by page_path
)
-- [3] 최종 계산: 페이지별 이탈률(%)
select 
	page_path,	-- 페이지 경로
	page_view_cnt,	-- 전체 페이지뷰 수
	bounce_sessions_cnt,	-- 이탈 세션 수
	entry_sessions_cnt,		-- 진입 세션 수
	-- 이탈율 계산. sess_cnt_01이 0 일 경우 0으로 나눌수 없으므로 Null값 처리. sess_cnt_01이 0이면 bounce session이 없으므로 이탈율은 0.
	coalesce(round(100.0 * bounce_sessions_cnt / NULLIF(entry_sessions_cnt, 0), 2), 0) as bounce_rate_pct
from page_stats
order by page_view_cnt desc;