# SQL 웹 로그 분석 포트폴리오

본 프로젝트는 웹사이트 사용자 행동 로그를 기반으로  
**유입 → 전환 → 매출 → 이탈 흐름을 SQL로 분석**한 포트폴리오입니다.

지표 정의, 집계 단위(grain) 설계,  
그리고 **실무 환경에서 재현 가능한 SQL 구조**에 중점을 두었습니다.

---

## 데이터셋 개요

- 출처: Google Analytics Sample Dataset
- 분석 기간: **2016년 8월 ~ 10월**
- DB 환경: PostgreSQL

### 주요 테이블
- `ga_sess` : 세션 단위 방문 정보
- `ga_sess_hits` : 페이지 히트 로그
- `orders` : 주문 정보
- `order_items` : 주문별 상품 매출 정보

> ※ 원본 데이터는 GitHub에 포함하지 않았으며, 동일한 스키마 환경에서 SQL 쿼리는 재현 가능하도록 작성되었습니다.

---

## 분석 구성 및 지표

| No | 분석 항목 | 주요 지표 |
|----|---------|---------|
| 10 | 사용자 규모 | Rolling DAU / WAU |
| 20 | 월별 성과 | 세션 수, 매출 |
| 30 | 전환 분석 | 구매 전환율 |
| 40 | 채널 성과 | 매출, 방문자 대비 효율 |
| 50 | 이탈 분석 | Entry 기준 이탈률 |
| 60 | 종료 분석 | 세션 종료 페이지 |

---

## SQL 설계 원칙

- 모든 지표는 **세션 단위(grain)** 를 기준으로 설계
- 주문 매출은 `order_id` 기준 사전 집계로 중복 방지
- 세션 기준 집합 유지를 위해 **LEFT JOIN** 사용
- Entry / Exit 판단을 위해 **윈도우 함수** 활용
- `NULLIF`, `COALESCE`를 사용한 안전한 비율 계산

---

## 주요 관찰 결과

- 방문 세션 수 증가에도 불구하고 매출과 전환율은 회복되지 않음
- 채널별 전환율 및 매출 효율에 유의미한 차이 존재
- 방문자 규모와 매출 기여도는 비례하지 않음
- 탐색 단계 페이지에서 높은 이탈·종료율이 관찰됨

---

## 프로젝트 구조

```text
sql-portfolio/
├─ sql/
│  ├─ 10_dau_wau.sql
│  ├─ 20_revenue_sessions.sql
│  ├─ 30_conversion_rate.sql
│  ├─ 40_channel_performance.sql
│  ├─ 50_bounce_rate.sql
│  └─ 60_exit_rate.sql
│
├─ images/
│  ├─ 01_dau_wau.png
│  ├─ 02_revenue_sessions.png
│  ├─ 03_conversion_rate.png
│  ├─ 04_channel_performance.png
│  ├─ 05_bounce_rate.png
│  └─ 06_exit_rate.png
│
└─ README.md

