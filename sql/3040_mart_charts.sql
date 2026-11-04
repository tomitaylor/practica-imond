CREATE TABLE mart_charts AS
WITH series AS (
    SELECT p.desde, p.hasta, m.canal, m.provincia, 'ventas' AS grafico,
           m.desde AS mes, m.ventas_millones AS valor
    FROM reporte_periodos AS p
    JOIN reporte_sales AS m ON m.desde = m.hasta AND m.desde BETWEEN p.desde AND p.hasta
    UNION ALL
    SELECT p.desde, p.hasta, '', '', 'usuarios', m.desde, m.usuarios_activos
    FROM reporte_periodos AS p
    JOIN reporte_activity AS m ON m.desde = m.hasta AND m.desde BETWEEN p.desde AND p.hasta
    UNION ALL
    SELECT p.desde, p.hasta, m.canal, '', 'nps', m.desde, m.nps
    FROM reporte_periodos AS p
    JOIN reporte_nps AS m ON m.desde = m.hasta AND m.desde BETWEEN p.desde AND p.hasta
), escalas AS (
    SELECT *, ROW_NUMBER() OVER ventana AS indice,
           COUNT(*) OVER grupo AS cantidad,
           CASE WHEN grafico = 'nps' THEN -100.0 ELSE 0.0 END AS minimo,
           CASE WHEN grafico = 'nps' THEN 100.0
                ELSE GREATEST(COALESCE(MAX(valor) OVER grupo, 0), 1) * 1.1 END AS maximo
    FROM series
    WINDOW grupo AS (PARTITION BY desde, hasta, canal, provincia, grafico),
           ventana AS (PARTITION BY desde, hasta, canal, provincia, grafico ORDER BY mes)
), coordenadas AS (
    SELECT *, ROUND(65 + (indice - 1) * 490.0 / GREATEST(cantidad - 1, 1), 2) AS x,
           ROUND(245 - (valor - minimo) * 225.0 / (maximo - minimo), 2) AS y
    FROM escalas
), tramos AS (
    SELECT *, SUM(CASE WHEN valor IS NULL THEN 1 ELSE 0 END) OVER (
        PARTITION BY desde, hasta, canal, provincia, grafico ORDER BY mes
    ) AS tramo
    FROM coordenadas
), lineas AS (
    SELECT desde, hasta, canal, provincia, grafico, tramo,
           '<polyline fill="none" stroke="#237855" stroke-width="3" points="' ||
           STRING_AGG(x || ',' || y, ' ' ORDER BY mes) || '"/>' AS linea
    FROM tramos
    WHERE valor IS NOT NULL
    GROUP BY desde, hasta, canal, provincia, grafico, tramo
), caminos AS (
    SELECT desde, hasta, canal, provincia, grafico,
           STRING_AGG(linea, '' ORDER BY tramo) AS lineas
    FROM lineas
    GROUP BY desde, hasta, canal, provincia, grafico
), detalles AS (
    SELECT desde, hasta, canal, provincia, grafico, minimo, maximo,
           COUNT(valor) AS valores,
           STRING_AGG(
               CASE WHEN valor IS NULL THEN '' ELSE
                   '<circle cx="' || x || '" cy="' || y ||
                   '" r="4" fill="#237855"><title>' || mes || ': ' ||
                   ROUND(valor, 2) || '</title></circle>' END ||
               CASE WHEN (indice - 1) % CAST(CEIL(cantidad / 5.0) AS INTEGER) = 0
                         OR indice = cantidad THEN
                   '<text x="' || x || '" y="280" text-anchor="middle" fill="#61736a" font-size="11">' ||
                   mes || '</text>' ELSE '' END,
               '' ORDER BY mes
           ) AS marcas
    FROM coordenadas
    GROUP BY desde, hasta, canal, provincia, grafico, minimo, maximo
), ejes AS (
    SELECT d.desde, d.hasta, d.canal, d.provincia, d.grafico,
           STRING_AGG(
               '<line x1="65" x2="555" y1="' || (245 - t.i * 56.25) ||
               '" y2="' || (245 - t.i * 56.25) || '" stroke="#e3eae5"/>' ||
               '<text x="55" y="' || (249 - t.i * 56.25) ||
               '" text-anchor="end" fill="#61736a" font-size="11">' ||
               ROUND(d.minimo + (d.maximo - d.minimo) * t.i / 4.0, 1) || '</text>',
               '' ORDER BY t.i
           ) AS ejes
    FROM detalles AS d CROSS JOIN RANGE(5) AS t(i)
    GROUP BY d.desde, d.hasta, d.canal, d.provincia, d.grafico
)
SELECT d.desde, d.hasta, d.canal, d.provincia, d.grafico,
       CASE WHEN d.valores = 0 THEN '<p>Sin datos para estos filtros.</p>' ELSE
           '<svg viewBox="0 0 600 300" role="img" aria-label="Serie mensual; consultar tabla de datos">' ||
           e.ejes || COALESCE(c.lineas, '') || d.marcas || '</svg>' END AS contenido
FROM detalles AS d
JOIN ejes AS e USING (desde, hasta, canal, provincia, grafico)
LEFT JOIN caminos AS c USING (desde, hasta, canal, provincia, grafico)
ORDER BY d.desde, d.hasta, d.canal, d.provincia, d.grafico;
