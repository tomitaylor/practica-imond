# Tablero y marts precalculados

## Recorrido de los datos

El proceso se ejecuta con `python run_sql.py`: los CSV originales alimentan las dimensiones y los hechos; luego los marts se construyen exclusivamente desde ese modelo estrella. La web lee únicamente archivos `dw/mart_*.csv`. No consulta `raw/`, dimensiones ni hechos.

Los SQL se ejecutan por su numeración: dimensiones `1000`, hechos `2000`, períodos `2900`, marts `3000`, consultas `4000` y validaciones `9000`.

## Períodos

Los filtros aceptan meses completos. Para los 21 meses entre enero de 2024 y septiembre de 2025, el ETL prepara los 231 intervalos contiguos posibles. La tarjeta de usuarios muestra los distintos del intervalo seleccionado, calculados directamente desde los hechos para ese intervalo. No suma usuarios mensuales ni muestra un promedio mensual.

Por ejemplo, un cliente identificado que aparece en enero y febrero cuenta una sola vez en enero-febrero. Una sesión anónima se utiliza como identificador sustituto, según la fórmula de la consigna; esto no permite reconocer a una misma persona entre sesiones anónimas.

## Contrato de los marts

| Mart | Una fila representa | Medidas o contenido |
|---|---|---|
| `mart_periods` | Un intervalo de meses completos | Mes inicial y final y sus fechas límite |
| `mart_filters` | Una opción de filtro | Tipo, valor y etiqueta |
| `mart_sales` | Intervalo, canal y provincia | Pedidos válidos, ventas, subtotal, ticket y ancho de barra |
| `mart_activity` | Un intervalo | Usuarios distintos, identificados, sesiones anónimas y usuarios en miles |
| `mart_nps` | Intervalo y canal | Respuestas, promotores, detractores y NPS |
| `mart_products` | Mes, canal, provincia y producto | Unidades, ventas y posición mensual |
| `mart_charts` | Intervalo, canal, provincia y tipo de gráfico | SVG y filas de «Ver datos» para el mismo corte, preparados desde SQL |

Las vistas `ventas_diarias` y `nps_diario` exponen componentes sumables en un grano diario sin subtotales. El ETL calcula ticket y NPS después de agregar esos componentes. Usuarios activos se recalcula como distinto para cada intervalo. Los marts exportados representan resultados de presentación para una combinación exacta de filtros. Las tablas de métricas y gráficos se generan a partir de vistas de reporte con origen en hechos y dimensiones.

En los marts, el canal o provincia vacíos representan el total de esa dimensión. Son filas de total independientes: no se suman con las filas de detalle. Las combinaciones sin pedidos tienen ventas y pedidos en cero y ticket nulo. Sin respuestas, el NPS es nulo, no cero.

Los importes en millones y miles también vienen calculados desde SQL. La web solo aplica formato numérico local para mostrarlos.

## Definiciones

| Indicador | Cálculo en SQL |
|---|---|
| Ventas totales | Suma de `total_amount` de pedidos `PAID` o `FULFILLED`; incluye IVA y envío |
| Ticket promedio | Ventas totales divididas por pedidos válidos del mismo intervalo y filtros |
| Usuarios activos | `COUNT(DISTINCT visitor_key)` del intervalo; prefijos diferentes para clientes y sesiones |
| NPS | Promedio de `nps_value` por 100; promotor 1, pasivo 0, detractor -1 |
| Ventas por provincia | Ventas totales agrupadas por provincia de envío |
| Ranking mensual | `DENSE_RANK` por ventas de productos después de descuentos, sin IVA ni envío |

Los empates comparten posición. El filtro de producto selecciona filas del ranking calculado y conserva su posición; no vuelve a ordenar los productos ni cambia el puesto de un producto seleccionado.

## Alcance de los filtros

| Filtro | Indicadores afectados |
|---|---|
| Mes inicial y final | Todos |
| Canal | Ventas, ticket, NPS, provincias y productos |
| Provincia | Ventas, ticket, provincias y productos |
| Producto y Top N | Ranking de productos |

Las sesiones no tienen canal comercial, provincia ni producto; no se les asignan esas dimensiones a partir de otras tablas. Las respuestas NPS tienen canal, pero no una provincia de compra o producto atribuibles sin supuestos adicionales.

## Responsabilidad de la web

`data.js` descarga y lee los CSV de marts. `app.js` selecciona las filas correspondientes al filtro y muestra sus campos. `charts.js` inserta los SVG del mart y las barras cuyo ancho ya calculó SQL, además de las tablas de datos.

JavaScript no suma importes, no divide medidas, no cuenta usuarios distintos, no calcula NPS y no construye rankings. Tampoco calcula escalas o coordenadas de los gráficos. La lectura del formato CSV y la selección de filas forman parte de la carga y presentación.

## Validación

`9000_validaciones.sql` compara cantidades de origen y hechos y concilia los indicadores del intervalo completo entre marts y modelo estrella. Los archivos de origen se usan allí como referencia de control del ETL, nunca como fuente del tablero o de sus marts.

Valores de referencia del conjunto entregado:

- Pedidos válidos: 10.998.
- Ventas totales: ARS 382.410.636,00.
- Ticket promedio: ARS 34.770,93.
- Subtotal de productos: ARS 309.891.600,00.
- Usuarios activos del intervalo completo: 73.828.
- NPS del intervalo completo: 30,00.

## Límites

El tablero no permite días sueltos: trabaja con meses completos. Si se agregan meses a los hechos, hay que volver a ejecutar el ETL para generar los nuevos intervalos y gráficos. La cantidad de intervalos crece con la extensión del calendario; esta solución está pensada para la ventana de 21 meses de la práctica.
