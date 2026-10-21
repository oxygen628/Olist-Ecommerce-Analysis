import pandas as pd
import os

DATA_DIR = "data"
files = {
    "customers": "olist_customers_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "payments": "olist_order_payments_dataset.csv",
    "reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "category": "product_category_name_translation.csv",
}

for name, f in files.items():
    df = pd.read_csv(os.path.join(DATA_DIR, f))
    print("=" * 60)
    print(f"{name}: {df.shape[0]} 行, {df.shape[1]} 列")
    print(df.dtypes)
    print("缺失值比例：")
    print((df.isna().mean() * 100).round(2).sort_values(ascending=False).head(10))
    print("前 3 行：")
    print(df.head(3))