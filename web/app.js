import { cargarDatos } from "./data.js";

import { mostrarGraficos } from "./charts.js";

const elemento = id => document.getElementById(id);

const numero = (valor, decimales = 2) =>
    valor.toLocaleString("es-AR", {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales
    });

function sumar(filas, columna) {
    return filas.reduce((total, fila) => {
        const valor = Number(fila[columna]);

        if (fila[columna] === "" || !Number.isFinite(valor)) {
            throw new Error(`Valor inválido en ${columna}`);
        }

        return total + valor;
    }, 0);
}

function completarOpciones(id, filas, columna) {
    const opciones = [...new Set(filas.map(fila => fila[columna]))]
        .filter(Boolean)
        .sort((a, b) => a.localeCompare(b, "es"));

    const selector = elemento(id);

    while (selector.options.length > 1) selector.remove(1);

    for (const valor of opciones) {
        selector.add(new Option(valor, valor));
    }
}

function filtrar(filas, dimensiones = []) {
    const desde = elemento("fecha-desde").value;
    const hasta = elemento("fecha-hasta").value;

    return filas.filter(fila =>
        (!desde || fila.fecha >= desde) &&
        (!hasta || fila.fecha <= hasta) &&
        dimensiones.every(dimension => {
            const valor = elemento(dimension).value;
            return !valor || fila[dimension] === valor;
        })
    );
}

function mostrarTarjetas(ventas, actividad, encuestas) {
    const total = sumar(ventas, "total_amount");
    const ticket = ventas.length ? total / ventas.length : null;
    const usuarios = new Set(
        actividad.map(fila => fila.visitor_key)
    ).size;


    const nps = encuestas.length
        ? sumar(encuestas, "nps_value") / encuestas.length * 100
        : null;

    elemento("kpi-ventas").textContent =
        `$${numero(total / 1000000)} M`;

    elemento("kpi-ticket").textContent =
        ticket === null ? "—" : `$${numero(ticket / 1000)} K`;

    elemento("kpi-usuarios").textContent =
        `${numero(usuarios / 1000)} K`;

    elemento("kpi-nps").textContent =
        nps === null ? "—" : numero(nps, 1);
}

function mostrarRanking(productos) {
    const grupos = new Map();

    for (const fila of productos) {
        const mes = fila.fecha.slice(0, 7);
        const clave = JSON.stringify([mes, fila.product_id]);

        if (!grupos.has(clave)) {
            grupos.set(clave, {
                mes,
                producto: fila.producto,
                unidades: 0,
                centavos: 0
            });
        }

        const grupo = grupos.get(clave);
        grupo.unidades += Number(fila.unidades);
        grupo.centavos += Math.round(Number(fila.ventas_producto) * 100);
    }

    const filas = [...grupos.values()].sort((a, b) =>
        a.mes.localeCompare(b.mes) ||
        b.centavos - a.centavos ||
        a.producto.localeCompare(b.producto)
    );

    const cuerpo = elemento("ranking");
    cuerpo.replaceChildren();

    let mesAnterior = "";
    let importeAnterior = null;
    let posicion = 0;

    for (const fila of filas) {
        if (fila.mes !== mesAnterior) {
            mesAnterior = fila.mes;
            importeAnterior = null;
            posicion = 0;
        }

        if (fila.centavos !== importeAnterior) posicion++;
        importeAnterior = fila.centavos;

        if (posicion > Number(elemento("top-n").value)) continue;

        const tr = document.createElement("tr");
        const valores = [
            fila.mes,
            posicion,
            fila.producto,
            numero(fila.unidades, 0),
            `$${numero(fila.centavos / 100)}`
        ];

        for (const valor of valores) {
            const td = document.createElement("td");
            td.textContent = valor;
            tr.append(td);
        }

        cuerpo.append(tr);
    }

    if (!cuerpo.children.length) {
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 5;
        td.textContent = "No hay ventas de productos para estos filtros.";
        tr.append(td);
        cuerpo.append(tr);
    }
}

function actualizar(datos) {
    const desde = elemento("fecha-desde").value;
    const hasta = elemento("fecha-hasta").value;

    if (!elemento("filtros").checkValidity() ||
        (desde && hasta && desde > hasta)) {
        elemento("estado").textContent =
            "Revisá las fechas. Los resultados conservan la selección anterior.";
        return;
    }

    const ventas = filtrar(datos.mart_sales, ["canal", "provincia"]);
    const actividad = filtrar(datos.mart_activity);
    const encuestas = filtrar(datos.mart_nps, ["canal"]);
    const productos = filtrar(
        datos.mart_products,
        ["canal", "provincia", "producto"]
    );

    mostrarTarjetas(ventas, actividad, encuestas);
    mostrarRanking(productos);
    mostrarGraficos(ventas, actividad, encuestas);

    elemento("estado").textContent =
        `Datos actualizados · ${numero(ventas.length, 0)} pedidos válidos.`;

    elemento("alcance-filtros").textContent =
        "Fecha: todos los indicadores. Canal: ventas, ticket, NPS y productos. " +
        "Provincia: ventas, ticket y productos. Producto: solo ranking. " +
        "Usuarios cuenta identificados únicos más sesiones anónimas del período.";
}

function configurarFiltros(datos) {
    completarOpciones("canal", datos.mart_sales, "canal");
    completarOpciones("provincia", datos.mart_sales, "provincia");
    completarOpciones("producto", datos.mart_products, "producto");

    for (const id of ["fecha-desde", "fecha-hasta"]) {
        const campo = elemento(id);
        campo.min = "2024-01-01";
        campo.max = "2025-09-30";
        campo.defaultValue = id === "fecha-desde"
            ? "2024-01-01"
            : "2025-09-30";
        campo.value = campo.defaultValue;
    }

    const formulario = elemento("filtros");

    formulario.querySelectorAll("input, select, button")
        .forEach(control => control.disabled = false);

    elemento("top-n").disabled = false;

    formulario.addEventListener("submit", evento => evento.preventDefault());
    formulario.addEventListener("change", () => actualizar(datos));

    formulario.addEventListener("reset", () => {
        setTimeout(() => actualizar(datos), 0);
    });

    elemento("top-n").addEventListener("change", () => actualizar(datos));
}

async function iniciar() {
    try {
        const datos = await cargarDatos();
        configurarFiltros(datos);
        actualizar(datos);
    } catch (error) {
        elemento("estado").textContent =
            `No se pudieron cargar los datos: ${error.message}`;
        console.error(error);
    }
}

iniciar();