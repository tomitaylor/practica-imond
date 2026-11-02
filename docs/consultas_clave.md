# Consultas clave

Las consultas siguientes se ejecutan en DuckDB después de `python run_sql.py`. Para explorarlas, usar `python run_sql.py --ui` y pegarlas en el editor SQL. Son consultas de revisión y análisis, no código ejecutado en el navegador.

## Consultas incluidas en el proceso

| Archivo | Resultado |
|---|---|
| [4010_kpi_sales.sql](../sql/4010_kpi_sales.sql) | Ventas, pedidos y ticket; evolución por canal y distribución por provincia |
| [4020_kpi_activity.sql](../sql/4020_kpi_activity.sql) | Usuarios activos por mes |
| [4030_kpi_nps.sql](../sql/4030_kpi_nps.sql) | Respuestas y NPS mensual por canal |
| [4040_kpi_products.sql](../sql/4040_kpi_products.sql) | Unidades, ventas y posición mensual por producto |
| [9000_validaciones.sql](../sql/9000_validaciones.sql) | Cantidades de origen y hechos; conciliación entre marts y modelo |

Estos archivos se ejecutan automáticamente en cada reconstrucción. Los módulos `3000` a `3040` calculan y materializan los resultados que utiliza el tablero.

## 1. Tarjetas del período completo

Se selecciona una única fila de cada mart para el intervalo completo. El canal y la provincia vacíos representan los totales de cada dimensión.

```sql
SELECT s.desde, s.hasta, s.pedidos_validos, s.ventas_totales,
       s.ticket_promedio, a.usuarios_activos, n.respuestas, n.nps
FROM mart_sales AS s
JOIN mart_activity AS a USING (desde, hasta)
JOIN mart_nps AS n USING (desde, hasta, canal)
WHERE s.desde = '2024-01'
  AND s.hasta = '2025-09'
  AND s.canal = ''
  AND s.provincia = '';
```

Resultado de referencia: 10.998 pedidos, ventas $382.410.636,00, ticket $34.770,93, 73.828 usuarios, 3.083 respuestas y NPS 30,00.

## 2. Series mensuales de los indicadores

Las filas con `desde = hasta` corresponden a meses individuales. La columna `usuarios_activos` no se suma para obtener los usuarios del intervalo completo.

```sql
SELECT s.desde AS mes, s.ventas_totales, s.ticket_promedio,
       a.usuarios_activos, n.nps
FROM mart_sales AS s
JOIN mart_activity AS a USING (desde, hasta)
JOIN mart_nps AS n USING (desde, hasta, canal)
WHERE s.desde = s.hasta AND s.canal = '' AND s.provincia = ''
ORDER BY mes;
```

Se obtienen 21 meses. Diciembre de 2024 muestra ventas por $28.448.502,00.

## 3. Ventas y NPS por canal

El porcentaje se calcula en esta consulta de análisis. No se agrega ningún cálculo al JavaScript del tablero.

```sql
SELECT s.canal, s.pedidos_validos, s.ventas_totales, s.ticket_promedio,
       ROUND(100.0 * s.ventas_totales / t.ventas_totales, 2) AS participacion_pct,
       n.respuestas, n.nps
FROM mart_sales AS s
JOIN mart_sales AS t ON t.desde = s.desde AND t.hasta = s.hasta
    AND t.canal = '' AND t.provincia = ''
JOIN mart_nps AS n ON n.desde = s.desde AND n.hasta = s.hasta AND n.canal = s.canal
WHERE s.desde = '2024-01' AND s.hasta = '2025-09'
  AND s.provincia = '' AND s.canal <> ''
ORDER BY s.ventas_totales DESC;
```

ONLINE: ventas $227.012.130,00, participación 59,36 %, NPS 24,01. OFFLINE: ventas $155.398.506,00, participación 40,64 %, NPS 40,93.

## 4. Ventas por provincia

```sql
SELECT s.provincia, s.pedidos_validos, s.ventas_totales,
       ROUND(100.0 * s.ventas_totales / t.ventas_totales, 2) AS participacion_pct
FROM mart_sales AS s
JOIN mart_sales AS t ON t.desde = s.desde AND t.hasta = s.hasta
    AND t.canal = '' AND t.provincia = ''
WHERE s.desde = '2024-01' AND s.hasta = '2025-09'
  AND s.canal = '' AND s.provincia <> ''
ORDER BY s.ventas_totales DESC;
```

Buenos Aires: $142.699.252,50 (37,32 %); Córdoba: $89.535.175,50 (23,41 %); Santa Fe: $87.547.407,00 (22,89 %); Mendoza: $62.628.801,00 (16,38 %).

## 5. Ranking mensual Top N

El puesto ya viene calculado por SQL. Cambiar `posicion <= 2` por `posicion <= 1` selecciona el Top 1. Para seleccionar un producto sin recalcular su puesto, agregar la condición sobre `product_id`.

```sql
SELECT mes, posicion, producto, unidades, ventas_producto
FROM mart_products
WHERE canal = '' AND provincia = ''
  AND mes BETWEEN '2024-01' AND '2025-09'
  AND posicion <= 2
ORDER BY mes, posicion, producto;
```

Enero de 2024: Sport B Bottle, puesto 1, 519 unidades y $7.706.250,00; Classic A Bottle, puesto 2, 440 unidades y $5.236.200,00.

## 6. Identificados y sesiones anónimas

```sql
SELECT desde, hasta, usuarios_activos, usuarios_identificados, sesiones_anonimas
FROM mart_activity
WHERE desde = '2024-01' AND hasta = '2025-09';
```

Resultado: 73.828 identificadores de actividad, de los cuales 3.077 son clientes identificados distintos y 70.751 son sesiones anónimas. Estas sesiones no identifican necesariamente personas diferentes.

## 7. Comparación de períodos equivalentes

Se comparan los mismos nueve meses de ambos años. El crecimiento se calcula con los importes del período, no con un promedio de tasas mensuales.

```sql
SELECT a.ventas_totales AS ventas_2024, b.ventas_totales AS ventas_2025,
       a.pedidos_validos AS pedidos_2024, b.pedidos_validos AS pedidos_2025,
       a.ticket_promedio AS ticket_2024, b.ticket_promedio AS ticket_2025,
       ROUND((b.ventas_totales / a.ventas_totales - 1) * 100, 2)
           AS crecimiento_nominal_pct
FROM mart_sales AS a
JOIN mart_sales AS b ON b.desde = '2025-01' AND b.hasta = '2025-09'
    AND b.canal = '' AND b.provincia = ''
WHERE a.desde = '2024-01' AND a.hasta = '2024-09'
  AND a.canal = '' AND a.provincia = '';
```

Resultado: $146.308.315,50 en 2024 frente a $170.630.917,50 en 2025, crecimiento nominal del 16,62 %.

## 8. Importe, unidades y meses liderados por producto

Esta suma utiliza exclusivamente el nivel total de canal y provincia, con una fila por producto y mes. No se suman otros niveles de agregación del mart.

```sql
SELECT producto, SUM(unidades) AS unidades,
       SUM(ventas_producto) AS ventas_producto,
       COUNT(CASE WHEN posicion = 1 THEN 1 END) AS meses_primero
FROM mart_products
WHERE canal = '' AND provincia = ''
GROUP BY producto
ORDER BY ventas_producto DESC;
```

Sport B: $162.717.000,00, 11.047 unidades, primero en 12 meses. Classic A: $147.174.600,00, 12.498 unidades, primero en 9 meses.

## Evitar duplicaciones al consultar marts

En `mart_sales` hay filas para distintos intervalos y distintos niveles de canal y provincia. Sumar todas las filas del archivo duplica las ventas. Seleccionar siempre un intervalo y el nivel de agregación que se necesita. Lo mismo se aplica a NPS, actividad y gráficos. Para el ranking, elegir un único nivel de canal y provincia dentro de cada mes.
