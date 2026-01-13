-- DAU 집계 (rolling 24h, window end = current_date 00:00)
-- 목적: 2016-10-01 ~ 2016-10-31 기간에 대해,
--       각 날짜(current_date)를 "집계 윈도우의 종료 시점"으로 두고
--       직전 24시간 동안 방문한 고유 사용자 수(DAU)를 계산.
--       예) current_date=2016-10-02 → 2016-10-01 00:00 ~ 2016-10-02 00:00 방문자 기준
--
-- 사용 테이블: ga.ga_sess (세션/방문 로그)
-- 기준 컬럼:
--   - visit_stime: 방문 시작 시각(timestamp)
--   - user_id: 사용자 식별자(DAU의 distinct 기준)

with date_range as (
	-- [1] 분석 대상 날짜 목록 생성: 2016-10-01부터 2016-10-31까지, 1일 단위
	select 
		generate_series(
			'2016-10-01'::date, 
			'2016-10-31'::date, 
			'1 day'::interval)::date as current_date
		)
select 
	b.current_date,  -- 기준 날짜
	count(distinct user_id) as dau  -- 해당 일자 전 24시간 동안 방문한 고유 사용자 수
from ga.ga_sess a
	cross join date_range b
where visit_stime >= (b.current_date - interval '1 days') and visit_stime < b.current_date
group by b.current_date
ORDER BY b.current_date;

-- ===================================================================================================================

-- WAU 집계 (Rolling 7d WAU, 주 1회 샘플링)
-- 목적: 2016-10-01 ~ 2016-10-31 기간에 대해,
--       각 기준일(current_date)을 "집계 윈도우 종료 시점(해당 날짜 00:00)"으로 두고
--       직전 7일 동안 최소 1회 방문한 고유 사용자 수(WAU)를 계산.
--       단, current_date를 7일 간격으로 생성하므로 결과는 '주 1회(7일마다)'로 출력.
--       예) current_date=2016-10-08 → 2016-10-01 00:00 ~ 2016-10-08 00:00 방문자 기준
--
-- 사용 테이블: ga.ga_sess
-- 기준 컬럼:
--   - visit_stime: 방문 시작 시각(timestamp)
--   - user_id: 사용자 식별자(WAU의 distinct 기준)

with date_range as (
	-- [1] 기준일 목록 생성: 2016-10-01부터 2016-10-31까지 7일 간격(주 1회 샘플링)
	select 
		generate_series(
			'2016-10-01'::date, 
			'2016-10-31'::date, 
			'7 day'::interval)::date as current_date
)
select 
	b.current_date,                 -- 집계 윈도우 종료 시점(해당 날짜 00:00)
	count(distinct user_id) as wau  -- 직전 7d 방문 고유 사용자 수(rolling)
from ga.ga_sess a
	cross join date_range b 
where visit_stime >= (b.current_date - interval '7 days') and visit_stime < b.current_date
group by b.current_date
ORDER BY b.current_date;