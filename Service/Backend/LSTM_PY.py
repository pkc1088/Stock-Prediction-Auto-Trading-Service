import numpy as np
import pandas as pd
import yfinance as yf
from sklearn.preprocessing import MinMaxScaler
import joblib
import ta
import os
import tensorflow as tf
from datetime import timedelta

def lstm_model(target_date, ticker, df):
    try:
        target_date = pd.to_datetime(target_date)

        model_path = os.path.join('LSTM_MODEL_H5_WIN', f'{ticker}.h5')
        scaler_path = os.path.join('LSTM_MODEL_H5_WIN', f'{ticker}_scaler.joblib')

        if not os.path.exists(model_path) or not os.path.exists(scaler_path):
            print(f"{ticker}의 모델 또는 스케일러 파일이 없습니다.")
            return None

        model = tf.keras.models.load_model(model_path, compile=False)
        scaler = joblib.load(scaler_path)

        # 데이터 정제
        df = df.copy()
        df.dropna(subset=['Open', 'High', 'Low', 'Close', 'Volume'], inplace=True)

        # 기술적 지표 추가
        df['MA20'] = ta.trend.sma_indicator(df['Close'], window=20)
        bb = ta.volatility.BollingerBands(df['Close'], window=20, window_dev=2)
        df['Upper'] = bb.bollinger_hband()
        df['Lower'] = bb.bollinger_lband()
        df['RSI'] = ta.momentum.RSIIndicator(df['Close'], window=14).rsi()
        df.dropna(inplace=True)

        # target_date 이전 거래일 찾기
        available_dates = df.index[df.index <= target_date]
        if len(available_dates) == 0:
            print(f"{ticker}: {target_date.date()} 이전 거래일 없음")
            return None

        actual_date = available_dates[-1]
        end_idx = df.index.get_loc(actual_date) 

        if end_idx < 49:
            print(f"{ticker}: {actual_date.date()} 기준 50일 이상 데이터 부족")
            return None

        features = ['Open', 'High', 'Low', 'Close', 'Volume', 'MA20', 'Upper', 'Lower', 'RSI']
        df_slice = df.iloc[end_idx - 49:end_idx + 1]
        X_scaled = scaler.transform(df_slice[features])

        X_input = np.expand_dims(X_scaled, axis=0)
        pred = model.predict(X_input)

        dummy = np.zeros((1, len(features)))
        close_idx = features.index('Close')
        dummy[:, close_idx] = pred.flatten()
        pred_close = scaler.inverse_transform(dummy)[0, close_idx]

        return pred_close

    except Exception as e:
        print(f"{ticker} 처리 중 오류: {e}")
        return None

