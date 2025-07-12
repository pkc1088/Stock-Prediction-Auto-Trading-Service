import requests
import json
import datetime
from pytz import timezone
import time
import yaml
import yfinance as yf

with open('config.yaml', encoding='UTF-8') as f:
    _cfg = yaml.load(f, Loader=yaml.FullLoader)
    
def get_access_token():
    """토큰 발급"""
    APP_KEY = _cfg['APP_KEY']
    APP_SECRET = _cfg['APP_SECRET']
    URL_BASE = _cfg['URL_BASE']

    headers = {"content-type":"application/json"}
    body = {"grant_type":"client_credentials",
    "appkey":APP_KEY,
    "appsecret":APP_SECRET}
    PATH = "oauth2/tokenP"
    URL = f"{URL_BASE}/{PATH}"
    res = requests.post(URL, headers=headers, data=json.dumps(body))
    ACCESS_TOKEN = res.json()["access_token"]
    return ACCESS_TOKEN

def hashkey(datas):
    """암호화"""
    APP_KEY = _cfg['APP_KEY']
    APP_SECRET = _cfg['APP_SECRET']
    URL_BASE = _cfg['URL_BASE']

    PATH = "uapi/hashkey"
    URL = f"{URL_BASE}/{PATH}"
    headers = {
    'content-Type' : 'application/json',
    'appKey' : APP_KEY,
    'appSecret' : APP_SECRET,
    }
    res = requests.post(URL, headers=headers, data=json.dumps(datas))
    hashkey = res.json()["HASH"]
    return hashkey

def get_current_price(ACCESS_TOKEN, code, market="NAS"):
    """현재가 조회"""
    APP_KEY = _cfg['APP_KEY']
    APP_SECRET = _cfg['APP_SECRET']
    URL_BASE = _cfg['URL_BASE']

    PATH = "uapi/overseas-price/v1/quotations/price"
    URL = f"{URL_BASE}/{PATH}"
    headers = {
        "Content-Type":"application/json",
        "authorization": f"Bearer {ACCESS_TOKEN}",
        "appKey":APP_KEY,
        "appSecret":APP_SECRET,
        "tr_id":"HHDFS00000300"
    }
    params = {
        "AUTH": "",
        "EXCD":market,
        "SYMB":code,
    }
    res = requests.get(URL, headers=headers, params=params)
    return float(res.json()['output']['last'])

def get_stock_balance(ACCESS_TOKEN):
    """주식 잔고조회"""
    APP_KEY = _cfg['APP_KEY']
    APP_SECRET = _cfg['APP_SECRET']
    CANO = _cfg['CANO']
    ACNT_PRDT_CD = _cfg['ACNT_PRDT_CD']
    URL_BASE = _cfg['URL_BASE']

    PATH = "uapi/overseas-stock/v1/trading/inquire-balance"
    URL = f"{URL_BASE}/{PATH}"
    headers = {
        "Content-Type":"application/json",
        "authorization":f"Bearer {ACCESS_TOKEN}",
        "appKey":APP_KEY,
        "appSecret":APP_SECRET,
        "tr_id":"VTTS3012R",
        "custtype":"P"
    }
    params = {
        "CANO": CANO,
        "ACNT_PRDT_CD": ACNT_PRDT_CD,
        "OVRS_EXCG_CD": "NAS",
        "TR_CRCY_CD": "USD",
        "CTX_AREA_FK200": "",
        "CTX_AREA_NK200": ""
    }
    res = requests.get(URL, headers=headers, params=params)
    stock_list = res.json()['output1']
    stock_dict = {}
    for stock in stock_list:
        if int(stock['ovrs_cblc_qty']) > 0:
            stock_dict[stock['ovrs_pdno']] = stock['ovrs_cblc_qty']
            time.sleep(0.1)
    time.sleep(0.1)
    return stock_dict


def make_holding(ACCESS_TOKEN):
    """주식 잔고 조회"""
    APP_KEY = _cfg['APP_KEY']
    APP_SECRET = _cfg['APP_SECRET']
    CANO = _cfg['CANO']
    ACNT_PRDT_CD = _cfg['ACNT_PRDT_CD']
    URL_BASE = _cfg['URL_BASE']

    PATH = "/uapi/overseas-stock/v1/trading/inquire-balance"
    URL = f"{URL_BASE}/{PATH}"
    headers = {"Content-Type":"application/json",
        "authorization":f"Bearer {ACCESS_TOKEN}",
        "appKey":APP_KEY,
        "appSecret":APP_SECRET,
        "tr_id":"VTTS3012R",
        "custtype":"P"
    }
    params = {
        "CANO": CANO,
        "ACNT_PRDT_CD": ACNT_PRDT_CD,
        "OVRS_EXCG_CD": "NASD",
        "TR_CRCY_CD": "USD",
        "CTX_AREA_FK200": "",
        "CTX_AREA_NK200": ""
    }
    res = requests.get(URL, headers=headers, params=params)
    stock_list = res.json()['output1']

    stock_dict = {}
    for stock in stock_list:
        if int(stock['ovrs_cblc_qty']) > 0:
            symbol = stock['ovrs_pdno']
            quantity = int(stock['ovrs_cblc_qty'])  # 보유량
            avgPrice = float(stock['pchs_avg_pric'])  # 평균 매입가

            stock_dict[symbol] = {
                "name": yf.Ticker(symbol).info['longName'],
                "symbol": symbol,
                "quantity": int(quantity),
                "avgPrice": float(avgPrice),
            }

            time.sleep(0.1)

    return stock_dict

def buy(ACCESS_TOKEN, code, qty, price, market="NAS"):
    """미국 주식 지정가 매수"""
    APP_KEY = _cfg['APP_KEY']
    APP_SECRET = _cfg['APP_SECRET']
    CANO = _cfg['CANO']
    ACNT_PRDT_CD = _cfg['ACNT_PRDT_CD']
    URL_BASE = _cfg['URL_BASE']

    PATH = "uapi/overseas-stock/v1/trading/order"
    URL = f"{URL_BASE}/{PATH}"
    data = {
        "CANO": CANO,
        "ACNT_PRDT_CD": ACNT_PRDT_CD,
        "OVRS_EXCG_CD": market,
        "PDNO": code,
        "ORD_DVSN": "00",
        "ORD_QTY": str(int(qty)),
        "OVRS_ORD_UNPR": str(price),
        "ORD_SVR_DVSN_CD": "0"
    }
    headers = {
        "Content-Type":"application/json",
        "authorization":f"Bearer {ACCESS_TOKEN}",
        "appKey":APP_KEY,
        "appSecret":APP_SECRET,
        "tr_id":"VTTT1002U",
        "custtype":"P",
        "hashkey" : hashkey(data)
    }
    res = requests.post(URL, headers=headers, data=json.dumps(data))
    if res.json()['rt_cd'] == '0':
        print(f"[매수 성공]{str(res.json())}")
        return True
    else:
        print(f"[매수 실패]{str(res.json())}")
        return False

# def buy(ACCESS_TOKEN, code, qty, market="NAS"):
#     """미국 주식 지정가 매수"""
#     APP_KEY = _cfg['APP_KEY']
#     APP_SECRET = _cfg['APP_SECRET']
#     CANO = _cfg['CANO']
#     ACNT_PRDT_CD = _cfg['ACNT_PRDT_CD']
#     URL_BASE = _cfg['URL_BASE']

#     PATH = "uapi/overseas-stock/v1/trading/order"
#     URL = f"{URL_BASE}/{PATH}"
#     data = {
#         "CANO": CANO,
#         "ACNT_PRDT_CD": ACNT_PRDT_CD,
#         "OVRS_EXCG_CD": market,
#         "PDNO": code,
#         "ORD_DVSN": "00",
#         "ORD_QTY": str(int(qty)),
#         "OVRS_ORD_UNPR": "0",
#         "ORD_SVR_DVSN_CD": "0"
#     }
#     headers = {
#         "Content-Type":"application/json",
#         "authorization":f"Bearer {ACCESS_TOKEN}",
#         "appKey":APP_KEY,
#         "appSecret":APP_SECRET,
#         "tr_id":"VTTT1002U",
#         "custtype":"P",
#         "hashkey" : hashkey(data)
#     }
#     res = requests.post(URL, headers=headers, data=json.dumps(data))
#     if res.json()['rt_cd'] == '0':
#         print(f"[매수 성공]{str(res.json())}")
#         return True
#     else:
#         print(f"[매수 실패]{str(res.json())}")
#         return False

def sell(ACCESS_TOKEN, code, qty, market="NAS"):
    """미국 주식 지정가 매도"""
    APP_KEY = _cfg['APP_KEY']
    APP_SECRET = _cfg['APP_SECRET']
    CANO = _cfg['CANO']
    ACNT_PRDT_CD = _cfg['ACNT_PRDT_CD']
    URL_BASE = _cfg['URL_BASE']

    PATH = "uapi/overseas-stock/v1/trading/order"
    URL = f"{URL_BASE}/{PATH}"
    data = {
        "CANO": CANO,
        "ACNT_PRDT_CD": ACNT_PRDT_CD,
        "OVRS_EXCG_CD": market,
        "PDNO": code,
        "ORD_QTY": str(int(qty)),
        "OVRS_ORD_UNPR": "0",
        "ORD_SVR_DVSN_CD": "0",
        "ORD_DVSN": "00"
    }
    headers = {
        "Content-Type":"application/json",
        "authorization":f"Bearer {ACCESS_TOKEN}",
        "appKey":APP_KEY,
        "appSecret":APP_SECRET,
        "tr_id":"VTTT1001U",
        "custtype":"P",
        "hashkey" : hashkey(data)
    }
    res = requests.post(URL, headers=headers, data=json.dumps(data))
    if res.json()['rt_cd'] == '0':
        print(f"[매도 성공]{str(res.json())}")
        return True
    else:
        print(f"[매도 실패]{str(res.json())}")
        return False

def make_price_point(symbol):
    ticker = yf.Ticker(symbol)
    df = ticker.history(period="1y")  # 1년치 일간 시세

    price_points = [
        {"date": date.strftime("%Y-%m-%d"), "price": round(close_price, 2)}
        for date, close_price in zip(df.index, df['Close'])
    ]
    return price_points


# 자동매매 시작
# def auto_trade(symbol, target_price):
def auto_trade(ACCESS_TOKEN, symbol, target_price):
    try:
        # ACCESS_TOKEN = get_access_token()

        soldout = False
        while True:
            t_now = datetime.datetime.now(timezone('America/New_York')) # 뉴욕 기준 현재 시간
            t_9 = t_now.replace(hour=9, minute=30, second=0, microsecond=0)
            t_start = t_now.replace(hour=9, minute=35, second=0, microsecond=0)
            t_sell = t_now.replace(hour=15, minute=45, second=0, microsecond=0)
            t_exit = t_now.replace(hour=15, minute=50, second=0,microsecond=0)
            today = t_now.weekday()
            if today == 5 or today == 6:  # 토요일이나 일요일이면 자동 종료
                print("주말이므로 프로그램을 종료합니다.")
                break
            if t_9 < t_now < t_start and soldout == False: # 잔여 수량 매도
                stock_dict = get_stock_balance(ACCESS_TOKEN)
                qty = int(stock_dict.get(symbol, 0))
                if qty > 0:
                    sell(ACCESS_TOKEN, code=symbol, qty=qty, market="NAS")
                time.sleep(1)
            if t_start < t_now < t_sell :  # AM 09:35 ~ PM 03:45 : 매수
                current_price = get_current_price(ACCESS_TOKEN, symbol, "NAS")
                if target_price > current_price:
                    buy_qty = 1  # 매수할 수량 초기화
                    if buy_qty > 0:
                        result = buy(ACCESS_TOKEN, code=symbol, price=current_price, qty=1, market="NAS")
                        time.sleep(1)
                        if result:
                            get_stock_balance(ACCESS_TOKEN)
                            time.sleep(1)
                        break
                time.sleep(1)
                if t_now.minute == 30 and t_now.second <= 5:
                    get_stock_balance(ACCESS_TOKEN)
                    time.sleep(5)
            if t_sell < t_now < t_exit:  # PM 03:45 ~ PM 03:50 : 일괄 매도
                stock_dict = get_stock_balance(ACCESS_TOKEN)
                qty = int(stock_dict.get(symbol, 0))
                if qty > 0:
                    sell(ACCESS_TOKEN, code=symbol, qty=qty, market="NAS")
                time.sleep(1)
            if t_exit < t_now:  # PM 03:50 ~ :프로그램 종료
                break
    except Exception as e:
        print(f"[오류 발생]{e}")
        time.sleep(1)