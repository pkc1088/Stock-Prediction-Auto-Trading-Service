import io
import os
import yfinance as yf
import time
import pandas as pd
import mplfinance as mpf
import tensorflow as tf
import numpy as np
from PIL import Image
from datetime import timedelta
from tensorflow.keras.preprocessing import image # type: ignore


# model = tf.keras.models.load_model('../model/pattern_classification_model_2.h5')
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(ROOT_DIR, 'model', 'pattern_classification_model_2.h5')
model = tf.keras.models.load_model(MODEL_PATH)


def cnn_model(target_date_str, ticker, df): 
    # 7월 1일, aapl, 4월1일~6월30일 (서비스)
    # 2024년 6월 16일, aapl, 2023-11-01 <= df < 2025-01-01 (학습)
    target_date = pd.to_datetime(target_date_str)
    N_CANDLES = 20

    try:
        df = df.copy()

        if isinstance(df.columns, pd.MultiIndex):
            df.columns = [col[0] for col in df.columns]

        required_cols = ["Open", "High", "Low", "Close"]
        if not all(col in df.columns for col in required_cols):
            print(f"{ticker}: OHLC 컬럼 누락")
            return None

        available_dates = df.index[df.index <= target_date] # 4월1일~6월30일 (서비스) / 2023-11-01 ~ 2024-06-16 (학습)
        if len(available_dates) == 0:
            print(f"{ticker}: {target_date.date()} 이전 거래일 없음")
            return None

        actual_date = available_dates[-1] # 6월 30일 (서비스) / 6월 16일 (학습 타켓)
        end_idx = df.index.get_loc(actual_date) # 150이라 가정

        if end_idx < N_CANDLES:
            print(f"{ticker}: 20봉 이상 데이터 부족")
            return None

        #df_slice = df.iloc[end_idx - N_CANDLES : end_idx].copy() # 학습용
        df_slice = df.iloc[end_idx - N_CANDLES + 1 : end_idx + 1].copy() # 서비스용
        print(f"[CNN_PY : period] {df.index[end_idx - N_CANDLES + 1]} <= df_slice <= {df.index[end_idx]}")
        
        # 150-20 인덱스 <= df_slice < 150, 즉 6월 29일 까지로, 6월 30일 포함이 안됨 (서비스)
        # 150-20 인덱스 <= df_slice < 6월 16일, 즉 6월 16일 포함 안되서 맞음 (학습)
        # 그래서 서비스 할 땐 :end_idx가 아니라 :end_idx+1이 맞음
        df_slice.index = pd.to_datetime(df_slice.index) # 6월 6일 ~ 6월 29일 (20일치)
        df_slice = df_slice[required_cols].copy().astype("float64").dropna()

        # (서비스) 즉 6월 29일치 까지 데이터로 6월 30일이 아닌 7월 1일을 예측하는 형태임. 
        # 이건 잘못됨. 사실상 6월 29일 데이터로 6월 30일을 예측하는 것과 같으니 수정 필요함 (수정 완료)   
        # 학습용 데이터 셋 구축할때는 target_date를 그 이전 데이터로 정상적으로 예측하는거 맞음
        if len(df_slice) < N_CANDLES:
            print(f"{ticker}: 정제 후 유효한 캔들 수 부족")
            return None

        mc = mpf.make_marketcolors(up='g', down='r', edge='black', wick='black', volume='gray')
        s = mpf.make_mpf_style(marketcolors=mc, rc={'axes.grid': False})

        buf = io.BytesIO()
        mpf.plot(
            df_slice,
            type='candle',
            style=s,
            volume=False,
            axisoff=True,
            tight_layout=True,
            savefig=buf
        )
        buf.seek(0)

        img = Image.open(buf).convert("RGB").resize((224, 224))
        predicted_label = predict_image(img)

        buf.close()
        return predicted_label

    except Exception as e:
        print(f"{ticker} 처리 중 오류: {e}")
        return None, None

def predict_image(img):
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array /= 255.0

    prediction = model.predict(img_array)
    predicted_class = float(prediction[0][0])
    
    return predicted_class
