CREATE TABLE fact_order_item (
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key INTEGER NOT NULL REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    store_key INTEGER NOT NULL REFERENCES dim_store(store_key),
    province_key INTEGER NOT NULL REFERENCES dim_province(province_key),
    product_key INTEGER NOT NULL REFERENCES dim_product(product_key),
    order_status_key INTEGER NOT NULL REFERENCES dim_order_status(order_status_key),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL
);

INSERT INTO fact_order_item
SELECT
    i.order_item_id,
    i.order_id,
    o.date_key,
    o.customer_key,
    o.channel_key,
    o.store_key,
    o.province_key,
    p.product_key,
    o.order_status_key,
    i.quantity,
    i.unit_price,
    i.discount_amount,
    i.line_total
FROM raw.sales_order_item AS i
JOIN fact_order AS o ON o.order_id = i.order_id
JOIN dim_product AS p ON p.product_id = i.product_id;
