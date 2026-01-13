-- KPI: 2016-10 페이지별 종료율(Exit Rate) 계산
-- 목적: 각 페이지가 세션의 '마지막 페이지'로 등장하는 비율을 집계하여
--       페이지별 퍼널 종착지(이탈 지점) 성격을 파악
-- 정의:
--    hit_type='PAGE' 기준으로 세션 내 마지막으로 조회된 페이지를 Exit로 간주
--    Exit Rate(세션 기준) = (해당 페이지가 마지막 PAGE였던 고유 세션 수) / (해당 페이지를 본 고유 세션 수)

with page_hit as ( 
	select 
		h.sess_id, h.page_path, h.hit_seq, h.hit_type, h.action_type, h.is_exit,
		-- 세션당 hit_seq 내림차순 순번 1이면 종료 페이지로 간주
		case when row_number() over (partition by s.sess_id order by h.hit_seq desc) = 1 then 1 else 0 end as is_exit_page
	from ga.ga_sess_hits h
		join ga.ga_sess s on h.sess_id = s.sess_id 
	-- 분석 기준일(:current_date) 직전 30일간의 페이지 히트만 포함
	where visit_stime >= '2016-10-01' and visit_stime < '2016-11-01'
	and h.hit_type = 'PAGE'  -- 페이지 조회 히트만
)
select 
	page_path, 
	-- 전체 페이지뷰 수
	count(*) as page_cnt,
	-- 페이지별 고유 세션 건수를 구함. 
	count(distinct sess_id) as sess_cnt,
	-- 해당 페이지가 종료 페이지일 경우에만 고유 세션 건수를 구함. 
	count(distinct case when is_exit_page = 1 then sess_id else null end) as exit_cnt,
	-- 종료율(%)
	round(100.0 * count(distinct case when is_exit_page = 1 then sess_id else null end) / count(distinct sess_id), 2) as exit_pct
from page_hit
group by page_path 
order by page_cnt desc;