import pandas as pd
import numpy as np
import os

# 以脚本所在目录为基准，避免工作目录问题
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
CLEAN_DIR = os.path.join(BASE_DIR, "clean")
os.makedirs(CLEAN_DIR, exist_ok=True)

def read(name):
    return pd.read_csv(os.path.join(DATA_DIR, name))

def to_datetime(df, cols):
    for c in cols:
        df[c] = pd.to_datetime(df[c], errors="coerce")
    return df

# ---------- 1. customers ----------
customers = read("olist_customers_dataset.csv")
customers["customer_city"] = customers["customer_city"].str.strip().str.lower()
customers["customer_state"] = customers["customer_state"].str.strip().str.upper()
customers.to_csv(os.path.join(CLEAN_DIR, "customers.csv"), index=False)
print(f"customers: {len(customers)} 行")

# ---------- 2. orders ----------
orders = read("olist_orders_dataset.csv")
time_cols = ["order_purchase_timestamp", "order_approved_at",
             "order_delivered_carrier_date", "order_delivered_customer_date",
             "order_estimated_delivery_date"]
orders = to_datetime(orders, time_cols)
orders["order_month"] = orders["order_purchase_timestamp"].dt.to_period("M").astype(str)
orders["order_year"] = orders["order_purchase_timestamp"].dt.year
# 时间倒挂标记（任一成立即为 True）
orders["is_time_reversed"] = (
    (orders["order_approved_at"] < orders["order_purchase_timestamp"]) |
    (orders["order_delivered_customer_date"] < orders["order_delivered_carrier_date"])
).fillna(False)
# 派生时长（缺失值为 NaN，正常）
orders["delivery_days"] = (orders["order_delivered_customer_date"] -
                           orders["order_purchase_timestamp"]).dt.total_seconds() / 86400
orders["approval_hours"] = (orders["order_approved_at"] -
                            orders["order_purchase_timestamp"]).dt.total_seconds() / 3600
orders.to_csv(os.path.join(CLEAN_DIR, "orders.csv"), index=False)
print(f"orders: {len(orders)} 行, 时间倒挂 {orders['is_time_reversed'].sum()} 条")
print("订单状态分布：")
print(orders["order_status"].value_counts())

# ---------- 3. order_items ----------
items = read("olist_order_items_dataset.csv")
items["shipping_limit_date"] = pd.to_datetime(items["shipping_limit_date"], errors="coerce")
items["price"] = pd.to_numeric(items["price"], errors="coerce")
items["freight_value"] = pd.to_numeric(items["freight_value"], errors="coerce")
items["is_price_invalid"] = ((items["price"] <= 0) | items["price"].isna()).astype(int)
items.to_csv(os.path.join(CLEAN_DIR, "order_items.csv"), index=False)
print(f"order_items: {len(items)} 行, 价格异常 {items['is_price_invalid'].sum()} 条")

# ---------- 4. payments ----------
pay = read("olist_order_payments_dataset.csv")
pay["payment_value"] = pd.to_numeric(pay["payment_value"], errors="coerce")
pay.to_csv(os.path.join(CLEAN_DIR, "payments.csv"), index=False)
print(f"payments: {len(pay)} 行")

# ---------- 5. reviews ----------
rev = read("olist_order_reviews_dataset.csv")
rev = to_datetime(rev, ["review_creation_date", "review_answer_timestamp"])
rev.to_csv(os.path.join(CLEAN_DIR, "reviews.csv"), index=False)
print(f"reviews: {len(rev)} 行")

# ---------- 6. products（合并品类翻译） ----------
prod = read("olist_products_dataset.csv")
cat = read("product_category_name_translation.csv")
prod = prod.merge(cat, on="product_category_name", how="left")
prod["product_category_name"] = prod["product_category_name"].fillna("unknown")
prod["product_category_name_english"] = prod["product_category_name_english"].fillna("unknown")
prod.to_csv(os.path.join(CLEAN_DIR, "products.csv"), index=False)
print(f"products: {len(prod)} 行, 品类 unknown { (prod['product_category_name']=='unknown').sum() } 条")

# ---------- 7. sellers ----------
sell = read("olist_sellers_dataset.csv")
sell["seller_city"] = sell["seller_city"].str.strip().str.lower()
sell["seller_state"] = sell["seller_state"].str.strip().str.upper()
sell.to_csv(os.path.join(CLEAN_DIR, "sellers.csv"), index=False)
print(f"sellers: {len(sell)} 行")

print("\n清洗完成，文件在：", CLEAN_DIR)