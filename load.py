import pandas as pd
from sqlalchemy import create_engine
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CLEAN_DIR = os.path.join(BASE_DIR, "clean")

# 改成你的 MySQL 密码
engine = create_engine(
    "mysql+pymysql://root:han6533ge@localhost:3306/olist_analysis?charset=utf8mb4"
)

files = {
    "dim_customers": "customers.csv",
    "dim_products": "products.csv",
    "dim_sellers": "sellers.csv",
    "orders": "orders.csv",
    "fact_order_items": "order_items.csv",
    "payments": "payments.csv",
    "reviews": "reviews.csv",
}

for table, f in files.items():
    df = pd.read_csv(os.path.join(CLEAN_DIR, f))
    df.to_sql(table, engine, if_exists="append", index=False, chunksize=5000)
    print(f"{table}: 导入 {len(df)} 行")