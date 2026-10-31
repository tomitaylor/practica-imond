const NS = "http://www.w3.org/2000/svg";

function crearSVG(tipo, atributos = {}, texto = null) {
    const nodo = document.createElementNS(NS, tipo);

    for (const [clave, valor] of Object.entries(atributos)) {
        nodo.setAttribute(clave, valor);
    }

    if (texto !== null) nodo.textContent = texto;
    return nodo;
}

function formato(valor) {
    return valor.toLocaleString("es-AR", {
        maximumFractionDigits: 1
    });
}

function mesesSeleccionados() {
    const desde = document.getElementById("fecha-desde").value
        || "2024-01-01";
    const hasta = document.getElementById("fecha-hasta").value
        || "2025-09-30";

    const meses = [];
    let [anio, mes] = desde.slice(0, 7).split("-").map(Number);

    while (true) {
        const clave = `${anio}-${String(mes).padStart(2, "0")}`;
        if (clave > hasta.slice(0, 7)) break;
        meses.push(clave);

        mes++;
        if (mes === 13) {
            mes = 1;
            anio++;
        }
    }

    return meses;
}

function agruparMes(filas) {
    const grupos = new Map(
        mesesSeleccionados().map(mes => [mes, []])
    );

    for (const fila of filas) {
        const mes = fila.fecha.slice(0, 7);
        if (grupos.has(mes)) grupos.get(mes).push(fila);
    }

    return [...grupos.entries()];
}

function agregarTabla(contenedor, puntos, unidad) {
    const detalle = document.createElement("details");
    const resumen = document.createElement("summary");
    resumen.textContent = "Ver datos";
    detalle.append(resumen);

    const tabla = document.createElement("table");
    const cabecera = document.createElement("thead");
    const trCabecera = document.createElement("tr");

    for (const titulo of ["Período / categoría", unidad]) {
        const th = document.createElement("th");
        th.scope = "col";
        th.textContent = titulo;
        trCabecera.append(th);
    }

    cabecera.append(trCabecera);
    tabla.append(cabecera);

    const cuerpo = document.createElement("tbody");

    for (const [etiqueta, valor] of puntos) {
        const tr = document.createElement("tr");

        for (const texto of [
            etiqueta,
            valor === null ? "Sin datos" : formato(valor)
        ]) {
            const td = document.createElement("td");
            td.textContent = texto;
            tr.append(td);
        }

        cuerpo.append(tr);
    }

    tabla.append(cuerpo);
    detalle.append(tabla);
    contenedor.append(detalle);
}

function dibujarSerie(id, puntos, unidad, limites = null) {
    const contenedor = document.getElementById(id);
    contenedor.replaceChildren();

    const valores = puntos
        .map(([, valor]) => valor)
        .filter(valor => valor !== null);

    if (!valores.length) {
        contenedor.textContent = "Sin datos para estos filtros.";
        return;
    }

    const ancho = 600;
    const alto = 300;
    const izquierda = 65;
    const derecha = 45;
    const arriba = 20;
    const abajo = 55;

    const minimo = limites ? limites[0] : 0;
    const maximo = limites ? limites[1]
        : Math.max(...valores, 1) * 1.1;

    const x = indice => izquierda +
        indice * (ancho - izquierda - derecha) /
        Math.max(puntos.length - 1, 1);

    const y = valor => alto - abajo -
        (valor - minimo) / (maximo - minimo) *
        (alto - arriba - abajo);

    const svg = crearSVG("svg", {
        viewBox: `0 0 ${ancho} ${alto}`,
        role: "img",
        "aria-label": `${unidad}. Datos disponibles debajo del gráfico.`
    });

    for (let i = 0; i <= 4; i++) {
        const valor = minimo + (maximo - minimo) * i / 4;

        svg.append(crearSVG("line", {
            x1: izquierda,
            x2: ancho - derecha,
            y1: y(valor),
            y2: y(valor),
            stroke: "#e3eae5"
        }));

        svg.append(crearSVG("text", {
            x: izquierda - 10,
            y: y(valor) + 4,
            "text-anchor": "end",
            fill: "#61736a",
            "font-size": 11
        }, formato(valor)));
    }

    let tramo = [];

    function cerrarTramo() {
        if (tramo.length) {
            svg.append(crearSVG("polyline", {
                points: tramo.join(" "),
                fill: "none",
                stroke: "#237855",
                "stroke-width": 3
            }));
        }

        tramo = [];
    }

    puntos.forEach(([etiqueta, valor], indice) => {
        if (valor === null) {
            cerrarTramo();
        } else {
            tramo.push(`${x(indice)},${y(valor)}`);
        }
    });

    cerrarTramo();

    const paso = Math.max(1, Math.ceil(puntos.length / 5));

    puntos.forEach(([etiqueta, valor], indice) => {
        if (indice % paso === 0 || indice === puntos.length - 1) {
            svg.append(crearSVG("text", {
                x: x(indice),
                y: alto - 20,
                "text-anchor": "middle",
                fill: "#61736a",
                "font-size": 11
            }, etiqueta));
        }

        if (valor !== null) {
            const circulo = crearSVG("circle", {
                cx: x(indice),
                cy: y(valor),
                r: 4,
                fill: "#237855"
            });

            circulo.append(crearSVG(
                "title",
                {},
                `${etiqueta}: ${formato(valor)} ${unidad}`
            ));

            svg.append(circulo);
        }
    });

    contenedor.append(svg);
    agregarTabla(contenedor, puntos, unidad);
}

function dibujarProvincias(ventas) {
    const contenedor = document.getElementById("grafico-provincias");
    contenedor.replaceChildren();

    const totales = new Map();

    for (const fila of ventas) {
        totales.set(
            fila.provincia,
            (totales.get(fila.provincia) || 0) + Number(fila.total_amount)
        );
    }

    const puntos = [...totales.entries()]
        .sort((a, b) => b[1] - a[1]);

    if (!puntos.length) {
        contenedor.textContent = "Sin ventas para estos filtros.";
        return;
    }

    const maximo = puntos[0][1];

    for (const [provincia, importe] of puntos) {
        const fila = document.createElement("div");
        fila.className = "fila-barra";

        const etiqueta = document.createElement("span");
        etiqueta.textContent = provincia;

        const fondo = document.createElement("div");
        fondo.className = "fondo-barra";

        const barra = document.createElement("div");
        barra.className = "barra";
        barra.style.width = `${maximo ? importe / maximo * 100 : 0}%`;
        fondo.append(barra);

        const valor = document.createElement("strong");
        valor.textContent = `$${formato(importe / 1000000)} M`;

        fila.append(etiqueta, fondo, valor);
        contenedor.append(fila);
    }
}

export function mostrarGraficos(ventas, actividad, encuestas) {
    const ventasMes = agruparMes(ventas).map(([mes, filas]) => [
        mes,
        filas.reduce(
            (total, fila) => total + Number(fila.total_amount),
            0
        ) / 1000000
    ]);

    const usuariosMes = agruparMes(actividad).map(([mes, filas]) => [
        mes,
        new Set(filas.map(fila => fila.visitor_key)).size
    ]);

    const npsMes = agruparMes(encuestas).map(([mes, filas]) => [
        mes,
        filas.length
            ? filas.reduce(
                (total, fila) => total + Number(fila.nps_value),
                0
            ) / filas.length * 100
            : null
    ]);

    dibujarSerie("grafico-ventas", ventasMes, "Millones de ARS");
    dibujarSerie("grafico-usuarios", usuariosMes, "Usuarios activos");
    dibujarSerie("grafico-nps", npsMes, "NPS", [-100, 100]);
    dibujarProvincias(ventas);
}