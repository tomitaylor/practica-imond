# Diccionario de datos del modelo EcoBottle AR

Corresponde a las dimensiones, hechos y marts del commit `21ebfe1`. Describe el modelo implementado; las tablas de origen se explican en el README del profesor.

## Convenciones

- PK: clave primaria declarada. FK: clave foránea declarada y destino. UNIQUE: unicidad declarada. En los marts se indica una clave lógica de selección, sin afirmar que exista una PK física.
- La columna «Admite NULL» refleja la restricción de la tabla, no solo los valores observados en el conjunto actual. Los marts se crean con `CREATE TABLE AS SELECT` y no declaran PK, FK ni NOT NULL.
- Las claves subrogadas de catálogo se generan con `ROW_NUMBER`. El calendario usa YYYYMMDD y los hechos conservan sus identificadores transaccionales. La reconstrucción es completa; no se mantiene historia de cambios de atributos (SCD tipo 2).
- Los miembros -1 de cliente, tienda y dirección permiten representar datos ausentes. Sus identificadores naturales son NULL; un pedido online utiliza tienda No aplica.
- Montos en ARS y marcas de tiempo del origen en hora de Argentina. Los TIMESTAMP no guardan zona horaria. El formato YYYY-MM identifica meses completos.
- Los tipos de las tablas con DDL explícito se muestran como están escritos en SQL. En DuckDB, VARCHAR(n) y CHAR(n) no imponen por sí mismos una longitud máxima. En marts se muestra el tipo inferido por DuckDB.
- Un dominio indicado como «del origen» o una fórmula documentada no equivale a un CHECK. Se distinguen las restricciones efectivamente declaradas de las reglas de negocio.

## Inventario

| Tabla | Filas en el conjunto | Grano |
|---|---:|---|
| `dim_address` | 3.830 | Una dirección del origen, más el miembro desconocido de clave -1. |
| `dim_channel` | 2 | Un canal de venta. |
| `dim_customer` | 3.472 | Un cliente del origen, más el miembro desconocido de clave -1. |
| `dim_date` | 731 | Un día del calendario. |
| `dim_product` | 2 | Un producto, con categoría y familia aplanadas. |
| `dim_province` | 4 | Una provincia. |
| `dim_store` | 5 | Una tienda, más el miembro No aplica de clave -1. |
| `fact_nps` | 3.083 | Una respuesta NPS. |
| `fact_order` | 11.969 | Un pedido, identificado por order_id. |
| `fact_order_item` | 14.573 | Una línea de producto dentro de un pedido. |
| `fact_payment` | 11.969 | Un registro de pago. |
| `fact_shipment` | 7.009 | Un envío asociado a un pedido. |
| `fact_web_session` | 100.363 | Una sesión web. |
| `mart_activity` | 231 | Un intervalo de meses completos. |
| `mart_charts` | 4.389 | Un gráfico para un intervalo y combinación aplicable de filtros. |
| `mart_filters` | 29 | Una opción de un tipo de filtro. |
| `mart_nps` | 693 | Un intervalo y un canal, incluido el total de canales. |
| `mart_periods` | 231 | Un intervalo contiguo de meses completos. |
| `mart_products` | 630 | Un producto en un mes y combinación de canal y provincia, incluyendo totales. |
| `mart_sales` | 3.465 | Un intervalo y una combinación de canal y provincia, incluyendo totales. |

## dim_address

**Grano:** Una dirección del origen, más el miembro desconocido de clave -1.

**Origen:** raw.address y raw.province.

province_id conserva el identificador de origen; no tiene FK declarada hacia dim_province. La provincia se aplana dentro de la dirección.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `address_key` | `INTEGER` | No | PK | Clave subrogada de la dirección; -1 para desconocida. |
| `address_id` | `INTEGER` | Sí | UNIQUE | Identificador natural de la dirección en el origen. |
| `line1` | `VARCHAR(120)` | Sí | — | Primera línea de la dirección. |
| `line2` | `VARCHAR(120)` | Sí | — | Complemento opcional de la dirección. |
| `city` | `VARCHAR(80)` | Sí | — | Localidad de la dirección o de la tienda. |
| `province_id` | `INTEGER` | Sí | — | Identificador de provincia en el origen. |
| `province_name` | `VARCHAR(50)` | Sí | — | Nombre de provincia aplanado. |
| `province_code` | `VARCHAR(10)` | Sí | — | Código de provincia aplanado. |
| `postal_code` | `VARCHAR(20)` | Sí | — | Código postal conservado como texto. |
| `country_code` | `CHAR(2)` | Sí | — | Código de país; AR en los registros de origen del conjunto. |
| `created_at` | `TIMESTAMP` | Sí | — | Fecha y hora de alta en el sistema de origen. |

## dim_channel

**Grano:** Un canal de venta.

**Origen:** raw.channel.

Los códigos del conjunto son ONLINE y OFFLINE.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `channel_key` | `INTEGER` | No | PK | Clave subrogada del canal comercial. |
| `channel_id` | `INTEGER` | No | UNIQUE | Identificador natural del canal. |
| `code` | `VARCHAR(20)` | No | UNIQUE | Código de canal: ONLINE u OFFLINE. |
| `name` | `VARCHAR(50)` | No | — | Nombre descriptivo del canal. |

## dim_customer

**Grano:** Un cliente del origen, más el miembro desconocido de clave -1.

**Origen:** raw.customer.

La fila -1 representa clientes ausentes o sin correspondencia. No se eliminan clientes inactivos.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `customer_key` | `INTEGER` | No | PK | Clave subrogada del cliente; -1 para desconocido o anónimo. |
| `customer_id` | `INTEGER` | Sí | UNIQUE | Identificador natural del cliente; nulo en el miembro desconocido. |
| `email` | `VARCHAR(120)` | Sí | — | Correo electrónico conservado del origen; sin UNIQUE declarada en esta dimensión. |
| `first_name` | `VARCHAR(80)` | Sí | — | Nombre del cliente; Desconocido en el miembro -1. |
| `last_name` | `VARCHAR(80)` | Sí | — | Apellido del cliente. |
| `phone` | `VARCHAR(30)` | Sí | — | Teléfono opcional del cliente. |
| `status` | `CHAR(1)` | Sí | — | A (activo) o I (inactivo); CHECK declarado; NULL en el miembro desconocido. |
| `created_at` | `TIMESTAMP` | Sí | — | Fecha y hora de alta en el sistema de origen. |

## dim_date

**Grano:** Un día del calendario.

**Origen:** Calendario generado en SQL.

Incluye 2024 y 2025 completos (731 días). Los hechos del conjunto llegan hasta septiembre de 2025.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `date_key` | `INTEGER` | No | PK | Clave primaria del calendario en formato YYYYMMDD. |
| `full_date` | `DATE` | No | UNIQUE | Día calendario; único y obligatorio. |
| `year` | `INTEGER` | No | — | Año del calendario. |
| `quarter` | `INTEGER` | No | — | Trimestre: 1 a 4. |
| `month` | `INTEGER` | No | — | Mes: 1 a 12. |
| `day` | `INTEGER` | No | — | Día del mes: 1 a 31, según calendario. |
| `day_of_week` | `INTEGER` | No | — | Día ISO: lunes 1 a domingo 7. |

## dim_product

**Grano:** Un producto, con categoría y familia aplanadas.

**Origen:** raw.product y dos niveles de raw.product_category.

Se conserva el ejemplo del profesor. product_id y sku no tienen UNIQUE declarada en esta dimensión. No se copian status ni created_at del producto.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `product_key` | `INTEGER` | No | PK | Clave subrogada del producto. |
| `product_id` | `INTEGER` | No | — | Identificador natural del producto. |
| `sku` | `VARCHAR` | No | — | Código comercial del producto, conservado del origen. |
| `name` | `VARCHAR` | No | — | Nombre comercial: Classic A Bottle o Sport B Bottle. |
| `category` | `VARCHAR` | Sí | — | Categoría del producto: Classic o Sport. |
| `family` | `VARCHAR` | Sí | — | Categoría padre: Bottles. |
| `list_price` | `DECIMAL(12, 2)` | Sí | — | Precio de lista en ARS, sin IVA. |

## dim_province

**Grano:** Una provincia.

**Origen:** raw.province.

Buenos Aires, Córdoba, Santa Fe y Mendoza.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `province_key` | `INTEGER` | No | PK | Clave subrogada de provincia. |
| `province_id` | `INTEGER` | No | UNIQUE | Identificador de provincia en el origen. |
| `name` | `VARCHAR(50)` | No | — | Nombre de provincia. |
| `code` | `VARCHAR(10)` | Sí | UNIQUE | Código opcional de provincia. |

## dim_store

**Grano:** Una tienda, más el miembro No aplica de clave -1.

**Origen:** raw.store, raw.address y raw.province.

La localización está aplanada. La fila -1 se utiliza cuando no corresponde una tienda, por ejemplo una venta online.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `store_key` | `INTEGER` | No | PK | Clave subrogada de tienda; -1 cuando no aplica o no se resuelve. |
| `store_id` | `INTEGER` | Sí | UNIQUE | Identificador natural de tienda; nulo en No aplica. |
| `name` | `VARCHAR(80)` | No | — | Nombre de tienda; No aplica en el miembro -1. |
| `city` | `VARCHAR(80)` | Sí | — | Localidad de la dirección o de la tienda. |
| `province` | `VARCHAR(50)` | Sí | — | Nombre de provincia de la tienda, aplanado desde su dirección. |
| `postal_code` | `VARCHAR(20)` | Sí | — | Código postal conservado como texto. |
| `country_code` | `CHAR(2)` | Sí | — | Código de país; AR en los registros de origen del conjunto. |

## fact_nps

**Grano:** Una respuesta NPS.

**Origen:** raw.nps_response y dimensiones.

Se fecha por responded_at y conserva el canal de la encuesta. No se atribuye un pedido, producto o provincia, porque la respuesta no contiene order_id.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `nps_id` | `BIGINT` | No | PK | Identificador de la respuesta NPS. |
| `date_key` | `INTEGER` | No | FK → dim_date.date_key | Fecha principal del hecho; YYYYMMDD; referencia al calendario. |
| `customer_key` | `INTEGER` | No | FK → dim_customer.customer_key | Clave subrogada del cliente; -1 para desconocido o anónimo. |
| `channel_key` | `INTEGER` | No | FK → dim_channel.channel_key | Clave subrogada del canal comercial. |
| `score` | `SMALLINT` | No | — | Puntaje entero de 0 a 10; CHECK declarado. |
| `segment` | `VARCHAR(10)` | No | — | Promotor (9–10), Pasivo (7–8) o Detractor (0–6), derivado por SQL. |
| `nps_value` | `SMALLINT` | No | — | 1 para promotor, 0 para pasivo y -1 para detractor; CHECK declarado. |
| `comment` | `TEXT` | Sí | — | Comentario opcional de la encuesta. |
| `responded_at` | `TIMESTAMP` | No | — | Fecha y hora de respuesta; determina date_key. |

## fact_order

**Grano:** Un pedido, identificado por order_id.

**Origen:** raw.sales_order y dimensiones; raw.address para resolver la provincia.

Conserva todos los estados. Solo PAID y FULFILLED se consideran ventas en los marts. La provincia corresponde a la dirección de envío.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `order_id` | `BIGINT` | No | PK | Identificador del pedido en el origen. |
| `date_key` | `INTEGER` | No | FK → dim_date.date_key | Fecha principal del hecho; YYYYMMDD; referencia al calendario. |
| `customer_key` | `INTEGER` | No | FK → dim_customer.customer_key | Clave subrogada del cliente; -1 para desconocido o anónimo. |
| `channel_key` | `INTEGER` | No | FK → dim_channel.channel_key | Clave subrogada del canal comercial. |
| `store_key` | `INTEGER` | No | FK → dim_store.store_key | Clave subrogada de tienda; -1 cuando no aplica o no se resuelve. |
| `province_key` | `INTEGER` | Sí | FK → dim_province.province_key | Clave subrogada de provincia; puede ser nula si no se resuelve la localización. |
| `billing_address_key` | `INTEGER` | No | FK → dim_address.address_key | Dirección de facturación; referencia a dim_address; -1 si ausente. |
| `shipping_address_key` | `INTEGER` | No | FK → dim_address.address_key | Dirección de envío; referencia a dim_address; -1 si ausente. |
| `order_date` | `TIMESTAMP` | No | — | Fecha y hora de creación del pedido. |
| `status` | `VARCHAR(20)` | No | — | Estado de pedido: CREATED, PAID, CANCELLED, FULFILLED o REFUNDED; conservado del origen, sin CHECK declarado. |
| `currency_code` | `CHAR(3)` | No | — | Moneda del pedido; ARS en el conjunto. |
| `subtotal` | `DECIMAL(12,2)` | No | — | Importe de productos después de descuentos, sin IVA ni envío; ARS. |
| `tax_amount` | `DECIMAL(12,2)` | No | — | IVA del pedido en ARS; 21 % del subtotal en el conjunto. |
| `shipping_fee` | `DECIMAL(12,2)` | No | — | Costo de envío en ARS. |
| `total_amount` | `DECIMAL(12,2)` | No | — | Subtotal más IVA más envío, en ARS. |

## fact_order_item

**Grano:** Una línea de producto dentro de un pedido.

**Origen:** raw.sales_order_item, fact_order y dim_product.

Hereda fecha, cliente, canal, tienda, provincia y estado del pedido. No repite sus importes de cabecera para evitar multiplicar ventas al sumar líneas.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `order_item_id` | `BIGINT` | No | PK | Identificador de la línea de pedido. |
| `order_id` | `BIGINT` | No | — | Identificador del pedido en el origen. Referencia lógica a fact_order.order_id, sin FK física declarada. |
| `date_key` | `INTEGER` | No | FK → dim_date.date_key | Fecha principal del hecho; YYYYMMDD; referencia al calendario. |
| `customer_key` | `INTEGER` | No | FK → dim_customer.customer_key | Clave subrogada del cliente; -1 para desconocido o anónimo. |
| `channel_key` | `INTEGER` | No | FK → dim_channel.channel_key | Clave subrogada del canal comercial. |
| `store_key` | `INTEGER` | No | FK → dim_store.store_key | Clave subrogada de tienda; -1 cuando no aplica o no se resuelve. |
| `province_key` | `INTEGER` | Sí | FK → dim_province.province_key | Clave subrogada de provincia; puede ser nula si no se resuelve la localización. |
| `product_key` | `INTEGER` | No | FK → dim_product.product_key | Clave subrogada del producto. |
| `status` | `VARCHAR(20)` | No | — | Estado heredado del pedido: CREATED, PAID, CANCELLED, FULFILLED o REFUNDED; sin CHECK declarado. |
| `quantity` | `INTEGER` | No | — | Cantidad de unidades de la línea; CHECK mayor que cero. |
| `unit_price` | `DECIMAL(12,2)` | No | — | Precio unitario de la línea, sin IVA; ARS. |
| `discount_amount` | `DECIMAL(12,2)` | No | — | Descuento total de la línea en ARS. |
| `line_total` | `DECIMAL(12,2)` | No | — | quantity × unit_price − discount_amount; ARS sin IVA ni envío. |

## fact_payment

**Grano:** Un registro de pago.

**Origen:** raw.payment y fact_order.

El conjunto contiene un pago por pedido. date_key es la fecha del pedido y paid_date_key es la del pago.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `payment_id` | `BIGINT` | No | PK | Identificador único del registro de pago. |
| `order_id` | `BIGINT` | No | — | Identificador del pedido en el origen. Referencia lógica a fact_order.order_id, sin FK física declarada. |
| `date_key` | `INTEGER` | No | FK → dim_date.date_key | Fecha principal del hecho; YYYYMMDD; referencia al calendario. |
| `paid_date_key` | `INTEGER` | Sí | FK → dim_date.date_key | Fecha calendario de paid_at; nula si no existe. |
| `customer_key` | `INTEGER` | No | FK → dim_customer.customer_key | Clave subrogada del cliente; -1 para desconocido o anónimo. |
| `channel_key` | `INTEGER` | No | FK → dim_channel.channel_key | Clave subrogada del canal comercial. |
| `store_key` | `INTEGER` | No | FK → dim_store.store_key | Clave subrogada de tienda; -1 cuando no aplica o no se resuelve. |
| `province_key` | `INTEGER` | Sí | FK → dim_province.province_key | Clave subrogada de provincia; puede ser nula si no se resuelve la localización. |
| `method` | `VARCHAR(20)` | No | — | Método de pago: CASH, CARD, TRANSFER o GATEWAY; dominio de origen sin CHECK en este hecho. |
| `status` | `VARCHAR(20)` | No | — | Estado de pago: PENDING, PAID, FAILED o REFUNDED; dominio del origen, sin CHECK declarado. |
| `amount` | `DECIMAL(12,2)` | No | — | Importe del registro de pago en ARS. |
| `paid_at` | `TIMESTAMP` | Sí | — | Fecha y hora del pago; opcional. |
| `transaction_ref` | `VARCHAR(80)` | Sí | — | Referencia opcional de transacción. |

## fact_shipment

**Grano:** Un envío asociado a un pedido.

**Origen:** raw.shipment y fact_order.

No todos los pedidos tienen envío. Se distinguen las fechas de pedido, despacho y entrega.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `shipment_id` | `BIGINT` | No | PK | Identificador único del envío. |
| `order_id` | `BIGINT` | No | — | Identificador del pedido en el origen. Referencia lógica a fact_order.order_id, sin FK física declarada. |
| `date_key` | `INTEGER` | No | FK → dim_date.date_key | Fecha principal del hecho; YYYYMMDD; referencia al calendario. |
| `shipped_date_key` | `INTEGER` | Sí | FK → dim_date.date_key | Fecha calendario de shipped_at; opcional. |
| `delivered_date_key` | `INTEGER` | Sí | FK → dim_date.date_key | Fecha calendario de delivered_at; opcional. |
| `customer_key` | `INTEGER` | No | FK → dim_customer.customer_key | Clave subrogada del cliente; -1 para desconocido o anónimo. |
| `channel_key` | `INTEGER` | No | FK → dim_channel.channel_key | Clave subrogada del canal comercial. |
| `store_key` | `INTEGER` | No | FK → dim_store.store_key | Clave subrogada de tienda; -1 cuando no aplica o no se resuelve. |
| `province_key` | `INTEGER` | Sí | FK → dim_province.province_key | Clave subrogada de provincia; puede ser nula si no se resuelve la localización. |
| `carrier` | `VARCHAR(40)` | Sí | — | Transportista; opcional. |
| `tracking_number` | `VARCHAR(60)` | Sí | — | Código de seguimiento; opcional. |
| `status` | `VARCHAR(20)` | No | — | Estado de envío: READY, SHIPPED, DELIVERED o CANCELLED; dominio del origen, sin CHECK declarado. |
| `shipped_at` | `TIMESTAMP` | Sí | — | Fecha y hora de despacho; opcional. |
| `delivered_at` | `TIMESTAMP` | Sí | — | Fecha y hora de entrega; opcional. |
| `delivery_days` | `DECIMAL(12,4)` | Sí | — | Diferencia entre entrega y despacho en días, incluidos decimales; NULL si falta una fecha. |

## fact_web_session

**Grano:** Una sesión web.

**Origen:** raw.web_session y dim_customer.

visitor_key permite contar identificados distintos y sesiones anónimas sin colisiones entre ambos espacios de identificadores.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `session_id` | `BIGINT` | No | PK | Identificador único de la sesión. |
| `date_key` | `INTEGER` | No | FK → dim_date.date_key | Fecha principal del hecho; YYYYMMDD; referencia al calendario. |
| `customer_key` | `INTEGER` | No | FK → dim_customer.customer_key | Clave subrogada del cliente; -1 para desconocido o anónimo. |
| `visitor_key` | `VARCHAR` | No | — | customer_<customer_id> si identificado; session_<session_id> si anónimo. |
| `started_at` | `TIMESTAMP` | No | — | Inicio de la sesión; determina date_key. |
| `ended_at` | `TIMESTAMP` | Sí | — | Fin de sesión; puede ser nulo. |
| `source` | `VARCHAR(50)` | Sí | — | Fuente de tráfico: ads, direct, referral u organic en el conjunto; puede ser nula. |
| `device` | `VARCHAR(30)` | Sí | — | Dispositivo registrado en el origen; puede ser nulo. |

## mart_activity

**Grano:** Un intervalo de meses completos.

**Origen:** fact_web_session, dim_date y mart_periods.

**Clave lógica:** `desde, hasta`. No hay restricciones PK/FK declaradas.

Los distintos se resuelven para cada intervalo; no se suman distintos mensuales ni se usa promedio mensual.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `desde` | `VARCHAR` | Sí | — | Mes inicial inclusivo del intervalo, como YYYY-MM. |
| `hasta` | `VARCHAR` | Sí | — | Mes final inclusivo del intervalo, como YYYY-MM. |
| `usuarios_activos` | `BIGINT` | Sí | — | COUNT(DISTINCT visitor_key) del intervalo. |
| `usuarios_identificados` | `BIGINT` | Sí | — | Visitantes identificados distintos del intervalo, excluyendo customer_key -1. |
| `sesiones_anonimas` | `BIGINT` | Sí | — | Sesiones con customer_key -1 dentro del intervalo. |
| `usuarios_miles` | `DOUBLE` | Sí | — | Usuarios activos / 1.000, precalculado en SQL. |

## mart_charts

**Grano:** Un gráfico para un intervalo y combinación aplicable de filtros.

**Origen:** mart_sales, mart_activity, mart_nps y mart_periods.

**Clave lógica:** `desde, hasta, canal, provincia, grafico`. No hay restricciones PK/FK declaradas.

El SVG terminado contiene valores, ejes, coordenadas y trazos calculados en SQL. La web inserta el contenido sin calcular el gráfico.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `desde` | `VARCHAR` | Sí | — | Mes inicial inclusivo del intervalo, como YYYY-MM. |
| `hasta` | `VARCHAR` | Sí | — | Mes final inclusivo del intervalo, como YYYY-MM. |
| `canal` | `VARCHAR` | Sí | — | Código comercial; cadena vacía para todos los canales. |
| `provincia` | `VARCHAR` | Sí | — | Nombre de provincia; cadena vacía para todas; Sin provincia si no se resuelve en los hechos. |
| `grafico` | `VARCHAR` | Sí | — | Tipo de serie: ventas, usuarios o nps. |
| `contenido` | `VARCHAR` | Sí | — | SVG generado por SQL, o mensaje HTML cuando no hay datos. |

## mart_filters

**Grano:** Una opción de un tipo de filtro.

**Origen:** mart_periods, dim_channel, dim_province y dim_product.

**Clave lógica:** `tipo, valor`. No hay restricciones PK/FK declaradas.

Contiene meses, canales, provincias y productos; las opciones Todos/Todas se definen en el HTML.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `tipo` | `VARCHAR` | Sí | — | Tipo de opción: mes, canal, provincia o producto. |
| `valor` | `VARCHAR` | Sí | — | Valor que utiliza el filtro; product_id se representa como texto. |
| `etiqueta` | `VARCHAR` | Sí | — | Texto visible de la opción. |

## mart_nps

**Grano:** Un intervalo y un canal, incluido el total de canales.

**Origen:** fact_nps, dim_channel, dim_date y mart_periods.

**Clave lógica:** `desde, hasta, canal`. No hay restricciones PK/FK declaradas.

Un canal vacío indica total. Sin respuestas el NPS es NULL, no cero. No se promedian los NPS mensuales.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `desde` | `VARCHAR` | Sí | — | Mes inicial inclusivo del intervalo, como YYYY-MM. |
| `hasta` | `VARCHAR` | Sí | — | Mes final inclusivo del intervalo, como YYYY-MM. |
| `canal` | `VARCHAR` | Sí | — | Código comercial; cadena vacía para todos los canales. |
| `respuestas` | `BIGINT` | Sí | — | Cantidad de respuestas de encuesta del intervalo y canal. |
| `promotores` | `BIGINT` | Sí | — | Respuestas con score 9 o 10. |
| `detractores` | `BIGINT` | Sí | — | Respuestas con score 0 a 6. |
| `nps` | `DOUBLE` | Sí | — | AVG(nps_value) × 100, redondeado a dos decimales; escala -100 a 100; NULL sin respuestas. |

## mart_periods

**Grano:** Un intervalo contiguo de meses completos.

**Origen:** fact_order y dim_date.

**Clave lógica:** `desde, hasta`. No hay restricciones PK/FK declaradas.

Para 21 meses se generan 231 intervalos, incluidos los de un solo mes.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `desde` | `VARCHAR` | Sí | — | Mes inicial inclusivo del intervalo, como YYYY-MM. |
| `hasta` | `VARCHAR` | Sí | — | Mes final inclusivo del intervalo, como YYYY-MM. |
| `fecha_desde` | `DATE` | Sí | — | Primer día del mes inicial. |
| `fecha_hasta` | `DATE` | Sí | — | Último día del mes final. |

## mart_products

**Grano:** Un producto en un mes y combinación de canal y provincia, incluyendo totales.

**Origen:** fact_order_item, dimensiones y agregación mensual.

**Clave lógica:** `mes, canal, provincia, product_id`. No hay restricciones PK/FK declaradas.

Solo ventas válidas. DENSE_RANK asigna puestos por importe descendente; los empates comparten posición. El filtro web de producto conserva la posición ya calculada.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `mes` | `VARCHAR` | Sí | — | Mes de venta como YYYY-MM. |
| `canal` | `VARCHAR` | Sí | — | Código comercial; cadena vacía para todos los canales. |
| `provincia` | `VARCHAR` | Sí | — | Nombre de provincia; cadena vacía para todas; Sin provincia si no se resuelve en los hechos. |
| `product_id` | `VARCHAR` | Sí | — | Identificador natural del producto. Convertido a VARCHAR para el filtro web. |
| `producto` | `VARCHAR` | Sí | — | Nombre del producto para presentación. |
| `unidades` | `HUGEINT` | Sí | — | Suma de quantity de líneas de venta válidas. |
| `ventas_producto` | `DECIMAL(38,2)` | Sí | — | Suma de line_total de líneas válidas; ARS sin IVA ni envío. |
| `posicion` | `BIGINT` | Sí | — | DENSE_RANK mensual por ventas_producto descendentes, dentro de cada canal y provincia. |

## mart_sales

**Grano:** Un intervalo y una combinación de canal y provincia, incluyendo totales.

**Origen:** fact_order, dimensiones, mart_periods y vistas de opciones.

**Clave lógica:** `desde, hasta, canal, provincia`. No hay restricciones PK/FK declaradas.

El canal o provincia vacíos indican total. Esas filas no deben sumarse con las filas de detalle. Combinaciones sin pedidos: importes cero y ticket nulo.

| Columna | Tipo | Admite NULL | Clave declarada | Significado y dominio |
|---|---|:---:|---|---|
| `desde` | `VARCHAR` | Sí | — | Mes inicial inclusivo del intervalo, como YYYY-MM. |
| `hasta` | `VARCHAR` | Sí | — | Mes final inclusivo del intervalo, como YYYY-MM. |
| `canal` | `VARCHAR` | Sí | — | Código comercial; cadena vacía para todos los canales. |
| `provincia` | `VARCHAR` | Sí | — | Nombre de provincia; cadena vacía para todas; Sin provincia si no se resuelve en los hechos. |
| `pedidos_validos` | `BIGINT` | Sí | — | Cantidad de pedidos PAID o FULFILLED del intervalo y filtros. |
| `ventas_totales` | `DECIMAL(38,2)` | Sí | — | Suma de total_amount de pedidos válidos; ARS con IVA y envío. |
| `subtotal` | `DECIMAL(38,2)` | Sí | — | Importe de productos después de descuentos, sin IVA ni envío; ARS. |
| `ventas_millones` | `DOUBLE` | Sí | — | ventas_totales / 1.000.000, precalculado en SQL. |
| `ticket_promedio` | `DOUBLE` | Sí | — | Ventas / pedidos válidos, redondeado a dos decimales; NULL si no hay pedidos. |
| `ticket_miles` | `DOUBLE` | Sí | — | Ventas / pedidos válidos / 1.000; NULL si no hay pedidos. |
| `ancho_barra` | `DOUBLE` | Sí | — | Porcentaje respecto de la provincia con más ventas del intervalo y canal; 0 a 100. NULL en fila total de provincias. |

## Criterios de modelado y uso

Las categorías y familias se aplanan en dim_product; los domicilios de tienda se aplanan en dim_store. La dirección del pedido tiene dos roles mediante billing_address_key y shipping_address_key. El calendario también tiene roles distintos en pagos y envíos.

order_id se conserva en líneas, pagos y envíos como identificador del pedido. Esas referencias no tienen FK física entre hechos; las FK declaradas apuntan a dimensiones. Los JOIN de carga y la conciliación permiten revisar la correspondencia.

Los hechos conservan todos los estados. Los marts de ventas y productos aplican PAID/FULFILLED. El total por producto usa line_total, por eso no coincide con ventas_totales, que incorpora IVA y envío.

Las filas de marts para diferentes intervalos o niveles de total se superponen. La web debe seleccionar la clave lógica exacta; sumar esas filas duplicaría importes o personas. Cada intervalo tiene su propio COUNT DISTINCT y su propio NPS y ticket.

El filtro de canal no afecta usuarios; provincia no afecta usuarios ni NPS; producto selecciona únicamente filas del ranking. No se imputan dimensiones ausentes a sesiones o encuestas.

Ver [arquitectura del tablero](arquitectura_tablero.md) para las fórmulas, el alcance de filtros y las limitaciones. Las vistas reporte_canales y reporte_provincias son auxiliares del ETL, no se exportan como tablas ni son consumidas por la web.
