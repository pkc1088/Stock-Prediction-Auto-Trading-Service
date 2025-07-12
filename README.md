# 📈 멀티모달 데이터마이닝 기반 주가 예측 시스템

본 프로젝트는 이미지, 시계열, 텍스트 데이터를 통합하여 종목별 주가를 예측하는 **멀티모달 예측 시스템**이다.<br>
단일 모달 한계를 극복하고, 다양한 데이터의 조합을 통해 정확도 높은 주가 예측 및 자동 매매를 목표로 한다.
<br><br>
![졸업과제 포스터](https://github.com/user-attachments/assets/e01ed946-003e-4b98-b973-56721fe652fb)

---

## 🧠 프로젝트 개요

- **프로젝트명**: **멀티모달 데이터마이닝 기반 주가 예측**
- **시연 영상**: [멀티모달 데이터마이닝 기반 주가 예측](https://www.youtube.com/shorts/7GqrPiGFHaA) <br><br>

### 🔍 문제 정의

- 최근 금융 시장의 변동성 증가 → 더 정교하고 실질적인 투자 의사결정을 지원하는 도구 요구
- 실제 주가는 경제 뉴스, 투자자 감정, 글로벌 이벤트, 차트 패턴 등 다양한 요인의 영향
- 단일 모달리티 기반 예측 모델은 이질적인 정보를 통합적 반영 불가
- 실제 주가: 기술적 패턴 + 뉴스 심리 + 외부 변수 동시 작용
<br><br>

### 🎯 목표

- 단일 모달리티 한계 극복
- 차트 이미지 + 시계열 + 뉴스 텍스트 통합 시스템 구축
- 미국 S&P 500 종목 주가 대상
- 실시간 의사결정 지원
- 자동 매매 연계
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
| 편경찬  | LSTM 모델 설계 및 구현<br>MLP 데이터셋 생성, MLP 모델 설계 및 구현<br>뉴스 크롤링, LLM 모델 통한 텍스트 감정분석<br>Fast API 이용한 메인 백엔드 구축<br>  |
| 정다원  | 캔들 스틱 차트 이미지 데이터 확보 및 분석<br>CNN 이미지 모델 설계 및 구현<br>한국투자증권 API 기반 자동매매 프로그램 구현<br>  |
| 하종석  | 프론트 UI/UX 설계 및 구현<br>TCA기반 네비게이션 설계 및 구현|

<br><br>

### ℹ️ 핵심 컴포넌트

- 디렉토리 구조
    ```shell
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
<br><br>

### 🔁 전체 데이터 흐름 (DFD)

<img width="2008" height="1005" alt="image" src="https://github.com/user-attachments/assets/4e880d0c-c2b9-4f6a-9cf8-1ccac4f06c1a" />


---

## 🧩 모델 구성

### 1️⃣ CNN (Chart Image)

- **개요**: CNN 모델로 상승/하락 라벨 분류 (패턴 분석)
- **데이터셋**: yfinance로 수집, 20일 단위 캔들 생성
- **입력**: `[캔들스틱 차트 PNG (224x224, RGB)]`
- **출력**: `Sigmoid 상승(1)/하락(0) 확률`
- **모델 구성**: Conv2D 3층 + MaxPooling + Dropout(0.3) + Dense<br><br>

- **결과**<br><br>

    <img width="600" height="300" alt="image" src="https://github.com/user-attachments/assets/90e16626-2454-4495-b9e5-1da354eaaba3" /> <br><br>
    - Validation 정확도 83.38%, Test 정확도 81.4%, loss : 0.3408 <br><br>

    <img width="300" height="300" alt="image" src="https://github.com/user-attachments/assets/5009a0f8-cbc2-4827-8800-a2b93236e451" /> <img width="421" height="300" alt="image" src="https://github.com/user-attachments/assets/5144849a-5a70-4c5c-ae00-3e2605b93a8a" />
<br><br>
    - 혼동행렬
        - 상승 클래스에서의 정분류 비율이 높음
        - 하락 클래스에 대해서도 일정 수준 이상의 예측 성능을 유지<br><br>
    - ROC-AUC 점수:
        - Area Under Curve : 0.83
        - 모델이 전체 임계값 구간에서 우수한 분류 능력을 보여줌<br><br>
    
    <img width="600" height="300" alt="image" src="https://github.com/user-attachments/assets/c4d19518-a588-45af-b71f-07dcb64b02a4" /> <br><br>
    - GradCAM 시각화 → 음봉, 갭 하락 등 실제 패턴 집중 학습 확인
    - 하락(Drop)으로 분류된 캔들차트에 대해 Grad-CAM을 적용한 결과

<br><br>
  > Q. Conv2D 왜 3개만?  
  > → 저수준~고수준 특징만 추출, 과적합 방지, 효율성 확보
  
  > Q. 이미지 크기 왜 224x224?  
  > → 딥러닝 표준, 정보손실 최소화, 연산 효율성 균형 - Softmax 대신 Sigmoid 사용 → 이진 분류(상승/하락)
<br><br>

---

### 2️⃣ LSTM ((Time Series))

- **개요**: 50일 윈도우 슬라이딩 방식, 종목별 모델 예측
- **데이터셋**: 10년치 S&P 500 데이터 (~120만개)
- **Train/Validation/Test**: 7:2:1
- **Epoch, Batch Size**: 50, 32
- **입력**: `[시가, 고가, 저가, 종가, 거래량, MA20, 볼린저 밴드(상/하), RSI]`
- **출력**: `예측 종가`
- **모델 구조**: LSTM 2층 + Dense 1층 + Dropout(0.3) + Early Stopping
- **평가 지표**: sMAPE<br><br>

- 결과 <br><br>
  <img width="603" height="321" alt="image" src="https://github.com/user-attachments/assets/668fff58-7edc-43cf-9038-9730941b37ca" /><br><br>
  - 테스트 셋 sMAPE 평균: **3.92%**
  - 350종목(72.5%) 이상 0~5% 그룹 포함 

<br><br>
  > Q. 왜 LSTM?  
  > → 과거 패턴 → 미래 영향 강함, 장기 의존성 처리 특화
<br><br>  
---

### 3️⃣ MLP (Late Fusion)

- **개요**: Late Fusion 방식의 MLP(Multi Layer Perceptron)
- **데이터셋**: 1년간의 CNN, LSTM 모델 예측값(10만개 이상 자체 생성)
- **Train/Validation/Test**: 8:1:2
- **Epoch, Batch Size**: 100, 16
- **입력**: `[LSTM 예측값, CNN 확률값, 전일 종가]`
- **출력**: `예측 종가` 
- **모델 구조**: Dense 3층 + 활성화 함수(ReLU) + Early Stopping
- **평가 지표**: sMAPE, R²<br><br>

- **결과** <br><br>
  <img width="781" height="326" alt="image" src="https://github.com/user-attachments/assets/980f9703-c22f-4203-bdc9-8836c47f2041" /><br><br>
  - 테스트 셋 sMAPE: **2.54%** → LSTM 단독 대비 **35% 개선**
  - R²: 0.996

<br><br>
  > Q. 왜 Late Fusion?  
  > → 이질적인 모달리티인 이미지/시계열 데이터 통합의 최적 구조 
<br><br>

---

### 4️⃣ TEXT (뉴스 감정분석)

- **조건**: 무료, 본문 제공, 종목별 수집 가능 →  **모두 만족하는 서비스 전무**<br><br>
- 뉴스 본문 확보:
  - `NewsAPI`: CNN/CBS/BBC 필터링 해 뉴스 링크 확보 → 도메인별 전용 크롤러 구축 →  본문 크롤링
  - 비교적 덜 유명한 종목: 제공 받을 수 있는 링크 자체가 한정적
  - `Yahoo Finance News`: 종목별 실시간 뉴스 제공 섹션 동적 접근 → Yahoo 전용 크롤러 구축 →  본문 크롤링<br><br>
- 감정 분석:
  - **Gemini 1.5 Flash**: LLM 기반 감정 점수 추출
  - **Marketaux API**: -1 ~ 1 범위 감성 점수 확보

<br><br>  
  > Q. 왜 Gemini Flash?  
  > → 빠른 응답, 문맥 이해 높음, 금융·기술 분야 범용성 ↑
<br><br>
---

### 5️⃣ Backend

- FastAPI + Uvicorn + ngrok
- 종목 요청 → 과거 데이터 수집 → LSTM + CNN 실행 → MLP 입력 → 최종 예측가 산출 
- 뉴스 크롤링 → Gemini 분석 → 감정 점수 반환
- 한국투자 API → 멀티스레딩 방식의 자동매매 연계

---

### 6️⃣ Frontend (iOS)

- Swift 기반 앱
- 홈: 보유 종목, 수량, 매수가 자동 조회
- 검색: 종목 상세 정보 + 그래프 + 예측가 + 감정 점수
- 감정 그래프: -100%~+100%
- 영어 기본, 다국어 번역 가능
- 사용자: 예상가 주문 or 직접 입력 → 자동매매 실행

---

## 📊 주요 결과 요약

| 모델 유형         | 평가 지표     | 성능         |
|------------------|---------------|--------------|
| LSTM        | sMAPE 종목 평균    | **3.92%**    |
| CNN  | 정확도 / AUC | 81.4% / 0.83  |
| 멀티모달 MLP     | sMAPE     | **2.54%**    |

- 결과<br><br>
<img width="343" height="326" alt="image" src="https://github.com/user-attachments/assets/108ec663-f5c1-4706-8bd7-fe37c5e4c75c" /><br><br>
 - 각 단일 모델도 신뢰할만한 지표를 가지도록 설계
 - 더불어 멀티모달 모델로 결합될 때 예측의 정확도와 신뢰도가 유의미하게 상승
 - 향후 상용화된 투자 지원 시스템으로 발전시킬 수 있는 기반 확보 

---

## ✅ 주요 기능

<img width="716" height="1022" alt="image" src="https://github.com/user-attachments/assets/8eb29c67-a52d-49a0-853e-14df04727166" /><br><br>





