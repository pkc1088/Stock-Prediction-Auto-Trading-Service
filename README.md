# 📈 멀티모달 데이터마이닝 기반 주가 예측 시스템

본 프로젝트는 이미지, 시계열, 텍스트 데이터를 통합하여 **종목별 주가를 예측**하는 멀티모달 예측 시스템입니다. 단일 모달 한계를 극복하고, 다양한 데이터의 조합을 통해 정확도 높은 주가 예측을 목표로 합니다.

---

## 🧠 프로젝트 개요

- **프로젝트명**: 멀티모달 데이터마이닝 기반 주가 예측
- **모델 구조**: CNN + LSTM → MLP (Late Fusion)
- **예측 대상**: 미국 S&P 500 종목 주가
- **학습 데이터 규모**: 약 10년간 일봉 기준 데이터 120만건 +
  이미지 약 10만장 + 뉴스 본문

---

## 🔧 주요 기술 스택

| 모달리티 | 활용 방식 |
|----------|------------|
| 시계열 (Time Series) | LSTM으로 50일치 주가 흐름을 입력, 다음날 종가 예측 |
| 이미지 (Candlestick Chart) | CNN으로 20일치 차트 이미지 분석, 상승/하락 판단 |
| 텍스트 (뉴스 기사) | LLM 기반 감정 분석 (Gemini 1.5, Marketaux API 활용) |

- **백엔드**: FastAPI + Uvicorn + Ngrok
- **모델 통합**: MLP로 Late Fusion 수행
- **자동 매매 연동**: 한국투자증권 Open API 사용 (멀티스레딩)

---

## 📊 모델 구조 및 성능

### LSTM (Time Series)

- 입력: `[시가, 고가, 저가, 종가, 거래량, MA20, 볼린저 밴드(상/하), RSI]`
- 윈도우 슬라이딩 방식으로 50일 단위 입력
- 모델 구조: LSTM → Dense → Dropout
- 평가 지표: **sMAPE 평균 3.92%**
- 학습 데이터: 종목별 개별 LSTM 모델 (약 500개)

### CNN (Chart Image)

- 캔들차트 생성: `mplfinance` 사용, 20봉 기준 이미지 생성
- CNN 모델로 상승/하락 라벨 분류
- GradCAM 적용 가능 (시각적 해석)

### MLP (Late Fusion)

- 입력: `[LSTM 예측값, CNN 확률값, 전일 종가]`
- 학습 데이터: 최근 1년간 10만개 이상 자체 생성
- 정규화: `MinMaxScaler` (종가 입력값에만 적용)
- 평가 지표:
  - sMAPE: **2.54%**
  - R²: **0.996**

---

## 📰 텍스트 처리 (뉴스 감정 분석)

- 조건: 무료, 본문 제공, 종목별 수집 가능
- API 활용:
  - `NewsAPI`: CNN/CBS/BBC 필터링 후 본문 크롤링
  - `Yahoo Finance`: 종목별 실시간 뉴스 보강
- 감정 분석:
  - **Gemini 1.5 Flash**: LLM 기반 감정 점수 추출
  - **Marketaux API**: -1 ~ 1 범위 감성 점수 확보

---

## 🔁 전체 데이터 흐름 (DFD)



## ✅ 주요 결과 요약

| 모델 유형         | 평가 지표     | 성능         |
|------------------|---------------|--------------|
| 단일 LSTM        | sMAPE 평균    | **3.92%**    |
| 멀티모달 MLP     | sMAPE 평균    | **2.54%**    |

