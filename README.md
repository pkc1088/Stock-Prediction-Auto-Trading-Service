# 📈 멀티모달 데이터마이닝 기반 주가 예측 시스템

본 프로젝트는 이미지, 시계열, 텍스트 데이터를 통합하여 **종목별 주가를 예측**하는 멀티모달 예측 시스템이다.<br>
단일 모달 한계를 극복하고, 다양한 데이터의 조합을 통해 정확도 높은 주가 예측 및 자동 매매을 목표로 한다.

<br><br>

---

## 🧠 프로젝트 개요

- **프로젝트명**: 멀티모달 데이터마이닝 기반 주가 예측
- **시연 영상**: CNN(이미지) + LSTM(시계열) + LLM(텍스트) → MLP(Late Fusion)
- **학습 데이터 규모**
    - 약 10년간 일봉 기준 데이터(120만건)
    - 이미지(약 10만장) 
    - 자체 수집한 MLP 데이터셋(10만건)
    - 뉴스 본문
<br><br>

### 🛠️ 기술 스택

- **Language**: Python
- **Model**: TensorFlow, Keras, h5 
- **Network**: FastAPI, Uvicorn, ngrok
- **APIs**: yfinance, Gemini Flash, NewsAPI, Marketaux, 한국투자 API
- **Front-end**: Swift (iOS)
<br><br>

### 🧑‍🤝‍🧑 프로젝트 멤버 이름 및 멤버 별 담당 파트
 
| 이름    | 담당 파트 및 주요 역할 |
|---------|--------------------------|
| 편경찬  | LSTM 모델 설계 및 구현, MLP 데이터셋 생성, MLP 모델 설계 및 구현, 뉴스 크롤링, LLM 모델 통한 텍스트 감정분석, Fast API 이용한 메인 백엔드 구축<br>  |
| 정다원  | 캔들 스틱 차트 이미지 데이터 확보 및 분석, CNN 이미지 모델 설계 및 구현, 한국투자증권 API 기반 자동매매 프로그램 구현<br>  |
| 하종석  | 프론트 UI/UX 설계 및 구현, TCA기반 네비게이션 설계 및 구현|

<br><br>

### 🔍 문제 정의

- 금융시장 변동성 ↑
- 단일 모달(가격만) 예측 → 한계
- 실제 주가: 기술적 패턴 + 뉴스 심리 + 외부 변수 동시 작용
- 기존 LSTM 단일모델 → 정확도 한계
<br><br>

### 🎯 목표

- 단일 모달리티 한계 극복
- 차트 이미지 + 시계열 + 뉴스 텍스트 통합 시스템 구축
- 미국 S&P 500 종목 주가 대상
- 실시간 의사결정 지원
- 자동 매매 연계
<br><br>

## 핵심 컴포넌트


- 핵심 컴포넌트
    ```shell
  .
  ├── README.md
  ├── cnn             차트 이미지 데이터셋 구축, cnn 모델 학습
  ├── data            csv, 데이터셋 저장
  ├── lstm            시계열 데이터셋 구축, lstm 모델 학습
  ├── mlp             mlp 데이터셋 구축
  ├── model           모델 저장
  └── service
      ├── backend      
      └── frontend
    ```

---

## 🧩 모델 구성

### 1️⃣ CNN (Chart Image)

- 캔들차트 생성: `mplfinance` 사용, 20봉 기준 이미지 생성
- CNN 모델로 상승/하락 라벨 분류
- GradCAM 적용 (시각적 해석)

- 입력: 캔들스틱 차트 PNG (224x224, RGB)
- 데이터: yfinance로 수집, 20일 단위 캔들 생성
- Conv2D 3층 + MaxPooling + Dropout(0.3) + Dense
- 출력: Sigmoid로 상승(1)/하락(0) 확률
- GradCAM 적용 → 음봉, 갭 하락 등 실제 패턴 집중 학습 확인
- Validation 정확도 83%, Test 81%, AUC 0.83

  > Q. Conv2D 왜 3개만?  
  > → 저수준~고수준 특징만 추출, 과적합 방지, 효율성 확보
  
  > Q. 이미지 크기 왜 224x224?  
  > → 딥러닝 표준, 정보손실 최소화, 연산 효율성 균형 - Softmax 대신 Sigmoid 사용 → 이진 분류(상승/하락)

- 결과 <br><br>
  <img width="603" height="321" alt="image" src="https://github.com/user-attachments/assets/668fff58-7edc-43cf-9038-9730941b37ca" />

  - rkskek 

---

### 2️⃣ LSTM ((Time Series))

- 입력: `[시가, 고가, 저가, 종가, 거래량, MA20, 볼린저 밴드(상/하), RSI]`
- 윈도우 슬라이딩 방식으로 50일 단위 입력
- 모델 구조: LSTM → Dense → Dropout
- 평가 지표: **sMAPE 평균 3.92%**
- 학습 데이터: 종목별 개별 LSTM 모델 (약 500개)

- 입력: 50일 윈도우, 시가·고가·저가·종가·거래량 + MA20, 볼린저밴드, RSI
- 10년치 S&P 500 데이터 (~120만개)
- Forget Gate + Input Gate + Cell State → 장기 의존성 처리
- 과적합 방지: Dropout + Early Stopping
- 평가: sMAPE 평균 3.9%, 350종목 이상 0~5% 그룹 포함

  > Q. 왜 LSTM?  
  > → 과거 패턴 → 미래 영향 강함, 장기 의존성 처리 특화
<br><br>

- 결과 <br><br>
  <img width="603" height="321" alt="image" src="https://github.com/user-attachments/assets/668fff58-7edc-43cf-9038-9730941b37ca" />

  - rkskek 


---

### 3️⃣ MLP (Late Fusion)

- 입력: `[LSTM 예측값, CNN 확률값, 전일 종가]`
- 학습 데이터: 최근 1년간 10만개 이상 자체 생성
- 정규화: `MinMaxScaler` (종가 입력값에만 적용)
- 평가 지표:
  - sMAPE: **2.54%**
  - R²: **0.996**

- CNN 예측(상승/하락) + LSTM 예측(종가) + 전일 종가 → 결합
- 서로 다른 형태 데이터 → MLP로 통합
- 활성화: ReLU, LSTM 출력은 MinMax Scaling
- sMAPE 2.54% → LSTM 단독 대비 1.4%p 개선
- R² 0.996

  > Q. 왜 Late Fusion?  
  > → 이미지/시계열/수치 데이터 통합 최적 구조

- 결과 <br><br>
  <img width="603" height="321" alt="image" src="https://github.com/user-attachments/assets/668fff58-7edc-43cf-9038-9730941b37ca" />

  - rkskek
 
 
---

### 4️⃣ TEXT (뉴스 감정분석)

- 조건: 무료, 본문 제공, 종목별 수집 가능
- API 활용:
  - `NewsAPI`: CNN/CBS/BBC 필터링 후 본문 크롤링
  - `Yahoo Finance`: 종목별 실시간 뉴스 동적 크롤링
- 감정 분석:
  - **Gemini 1.5 Flash**: LLM 기반 감정 점수 추출
  - **Marketaux API**: -1 ~ 1 범위 감성 점수 확보

- NewsAPI (CNN, CBS, BBC) + Yahoo Finance 크롤링
- 도메인 전용 크롤러 직접 제작
- Gemini Flash LLM → 뉴스 본문 감정 점수화
- Marketaux API 감정 점수 결합 → 다양성 확보
  
  > Q. 왜 Gemini Flash?  
  > → 빠른 응답, 문맥 이해 높음, 금융·기술 분야 범용성 ↑

---

## ⚙️ Backend

- FastAPI + Uvicorn + ngrok
- 종목 요청 → 50일치 데이터 → LSTM + CNN 실행 → MLP 입력
- MLP 예측가 산출
- 뉴스 크롤링 → Gemini 분석 → 감정 점수 반환
- 한국투자 API → 자동매매 연계

> Q. 자동매매?  
> → 멀티스레딩으로 주문 실행

---

## 📱 Frontend (iOS)

- Swift 기반 앱
- 홈: 보유 종목, 수량, 매수가 자동 조회
- 검색: 종목 상세 정보 + 그래프 + 예측가 + 감정 점수
- 감정 그래프: -100%~+100%
- 영어 기본, 다국어 번역 가능
- 사용자: 예상가 주문 or 직접 입력 → 자동매매 실행

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


## 🔁 전체 데이터 흐름 (DFD)

<img width="2008" height="1005" alt="image" src="https://github.com/user-attachments/assets/4e880d0c-c2b9-4f6a-9cf8-1ccac4f06c1a" />


## ✅ 주요 결과 요약

| 모델 유형         | 평가 지표     | 성능         |
|------------------|---------------|--------------|
| 단일 LSTM        | sMAPE 평균    | **3.92%**    |
| 멀티모달 MLP     | sMAPE 평균    | **2.04%**    |


| 모델 | 성능 |
|------|------|
| CNN  | Val 83% / Test 81% / AUC 0.83 |
| LSTM | sMAPE 평균 3.9% |
| MLP  | sMAPE 2.04%, R² 0.996 |




