# Modelo estrella

Generado por `run_sql.py` a partir de las tablas de `warehouse.duckdb`.

```mermaid
erDiagram
    dim_address ||--o{ fact_order : "billing_address_key"
    dim_address ||--o{ fact_order : "shipping_address_key"
    dim_channel ||--o{ fact_nps : "channel_key"
    dim_channel ||--o{ fact_order : "channel_key"
    dim_channel ||--o{ fact_order_item : "channel_key"
    dim_channel ||--o{ fact_payment : "channel_key"
    dim_channel ||--o{ fact_shipment : "channel_key"
    dim_customer ||--o{ fact_nps : "customer_key"
    dim_customer ||--o{ fact_order : "customer_key"
    dim_customer ||--o{ fact_order_item : "customer_key"
    dim_customer ||--o{ fact_payment : "customer_key"
    dim_customer ||--o{ fact_shipment : "customer_key"
    dim_customer ||--o{ fact_web_session : "customer_key"
    dim_date ||--o{ fact_nps : "date_key"
    dim_date ||--o{ fact_order : "date_key"
    dim_date ||--o{ fact_order_item : "date_key"
    dim_date ||--o{ fact_payment : "date_key"
    dim_date ||--o{ fact_payment : "paid_date_key"
    dim_date ||--o{ fact_shipment : "date_key"
    dim_date ||--o{ fact_shipment : "delivered_date_key"
    dim_date ||--o{ fact_shipment : "shipped_date_key"
    dim_date ||--o{ fact_web_session : "date_key"
    dim_device ||--o{ fact_web_session : "device_key"
    dim_payment_method ||--o{ fact_payment : "payment_method_key"
    dim_product ||--o{ fact_order_item : "product_key"
    dim_province ||--o{ fact_order : "province_key"
    dim_province ||--o{ fact_order_item : "province_key"
    dim_province ||--o{ fact_payment : "province_key"
    dim_province ||--o{ fact_shipment : "province_key"
    dim_store ||--o{ fact_order : "store_key"
    dim_store ||--o{ fact_order_item : "store_key"
    dim_store ||--o{ fact_payment : "store_key"
    dim_store ||--o{ fact_shipment : "store_key"
    dim_traffic_source ||--o{ fact_web_session : "traffic_source_key"
    dim_address {
        INTEGER address_key PK
        INTEGER address_id
        VARCHAR line1
        VARCHAR line2
        VARCHAR city
        INTEGER province_id
        VARCHAR province_name
        VARCHAR province_code
        VARCHAR postal_code
        VARCHAR country_code
        TIMESTAMP created_at
    }
    dim_channel {
        INTEGER channel_key PK
        INTEGER channel_id
        VARCHAR code
        VARCHAR name
    }
    dim_customer {
        INTEGER customer_key PK
        INTEGER customer_id
        VARCHAR email
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR phone
        VARCHAR status
        TIMESTAMP created_at
    }
    dim_date {
        INTEGER date_key PK
        DATE full_date
        INTEGER year
        INTEGER quarter
        INTEGER month
        INTEGER day
        INTEGER day_of_week
    }
    dim_device {
        INTEGER device_key PK
        VARCHAR device
    }
    dim_payment_method {
        INTEGER payment_method_key PK
        VARCHAR method
    }
    dim_product {
        INTEGER product_key PK
        INTEGER product_id
        VARCHAR sku
        VARCHAR name
        VARCHAR category
        VARCHAR family
        DECIMAL list_price
    }
    dim_province {
        INTEGER province_key PK
        INTEGER province_id
        VARCHAR name
        VARCHAR code
    }
    dim_store {
        INTEGER store_key PK
        INTEGER store_id
        VARCHAR name
        VARCHAR city
        VARCHAR province
        VARCHAR postal_code
        VARCHAR country_code
    }
    dim_traffic_source {
        INTEGER traffic_source_key PK
        VARCHAR source
    }
    fact_nps {
        BIGINT nps_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        SMALLINT score
        VARCHAR segment
        SMALLINT nps_value
        VARCHAR comment
        TIMESTAMP responded_at
    }
    fact_order {
        BIGINT order_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER province_key FK
        INTEGER billing_address_key FK
        INTEGER shipping_address_key FK
        TIMESTAMP order_date
        VARCHAR status
        VARCHAR currency_code
        DECIMAL subtotal
        DECIMAL tax_amount
        DECIMAL shipping_fee
        DECIMAL total_amount
    }
    fact_order_item {
        BIGINT order_item_id PK
        BIGINT order_id
        INTEGER date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER province_key FK
        INTEGER product_key FK
        VARCHAR status
        INTEGER quantity
        DECIMAL unit_price
        DECIMAL discount_amount
        DECIMAL line_total
    }
    fact_payment {
        BIGINT payment_id PK
        BIGINT order_id
        INTEGER date_key FK
        INTEGER paid_date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER province_key FK
        INTEGER payment_method_key FK
        VARCHAR status
        DECIMAL amount
        TIMESTAMP paid_at
        VARCHAR transaction_ref
    }
    fact_shipment {
        BIGINT shipment_id PK
        BIGINT order_id
        INTEGER date_key FK
        INTEGER shipped_date_key FK
        INTEGER delivered_date_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER province_key FK
        VARCHAR carrier
        VARCHAR tracking_number
        VARCHAR status
        TIMESTAMP shipped_at
        TIMESTAMP delivered_at
        DECIMAL delivery_days
    }
    fact_web_session {
        BIGINT session_id PK
        INTEGER date_key FK
        INTEGER customer_key FK
        VARCHAR visitor_key
        TIMESTAMP started_at
        TIMESTAMP ended_at
        INTEGER traffic_source_key FK
        INTEGER device_key FK
    }
    mart_activity {
        VARCHAR desde
        VARCHAR hasta
        BIGINT usuarios_activos
        BIGINT usuarios_identificados
        BIGINT sesiones_anonimas
        DOUBLE usuarios_miles
    }
    mart_charts {
        VARCHAR desde
        VARCHAR hasta
        VARCHAR canal
        VARCHAR provincia
        VARCHAR grafico
        VARCHAR contenido
    }
    mart_filters {
        VARCHAR tipo
        VARCHAR valor
        VARCHAR etiqueta
    }
    mart_nps {
        VARCHAR desde
        VARCHAR hasta
        VARCHAR canal
        BIGINT respuestas
        BIGINT promotores
        BIGINT detractores
        DOUBLE nps
    }
    mart_periods {
        VARCHAR desde
        VARCHAR hasta
        DATE fecha_desde
        DATE fecha_hasta
    }
    mart_products {
        VARCHAR mes
        VARCHAR canal
        VARCHAR provincia
        VARCHAR product_id
        VARCHAR producto
        HUGEINT unidades
        DECIMAL ventas_producto
        BIGINT posicion
    }
    mart_sales {
        VARCHAR desde
        VARCHAR hasta
        VARCHAR canal
        VARCHAR provincia
        BIGINT pedidos_validos
        DECIMAL ventas_totales
        DECIMAL subtotal
        DOUBLE ventas_millones
        DOUBLE ticket_promedio
        DOUBLE ticket_miles
        DOUBLE ancho_barra
    }
```
