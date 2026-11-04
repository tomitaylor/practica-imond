import { cargarDatos } from "./data.js";
import { mostrarGraficos } from "./charts.js";

const elemento = id => document.getElementById(id);
const numero = (valor, decimales = 2) =>
    valor === "" ? "—" : Number(valor).toLocaleString("es-AR", {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales
    });

function completarOpciones(id, opciones) {
    const selector = elemento(id);
    for (const opcion of opciones) {
        selector.add(new Option(opcion.etiqueta, opcion.valor));
    }
}

function mostrarRanking(filas) {
    const cuerpo = elemento("ranking");
    cuerpo.replaceChildren();
    for (const fila of filas) {
        const tr = document.createElement("tr");
        for (const valor of [fila.mes, fila.posicion, fila.producto,
            numero(fila.unidades, 0), `$${numero(fila.ventas_producto)}`]) {
            const td = document.createElement("td");
            td.textContent = valor;
            tr.append(td);
        }
        cuerpo.append(tr);
    }
    if (!cuerpo.hasChildNodes()) {
        const tr = document.createElement("tr");
        const td = document.createElement("td");
        td.colSpan = 5;
        td.textContent = "Sin productos para estos filtros y posiciones.";
        tr.append(td);
        cuerpo.append(tr);
    }
}

function actualizar(datos) {
    const desde = elemento("fecha-desde").value;
    const hasta = elemento("fecha-hasta").value;
    const canal = elemento("canal").value;
    const provincia = elemento("provincia").value;
    const producto = elemento("producto").value;
    const top = elemento("top-n").value;

    if (!elemento("filtros").checkValidity() || desde > hasta) {
        elemento("estado").textContent =
            "Revisá los meses. Se conserva la selección anterior.";
        return;
    }

    const periodo = fila => fila.desde === desde && fila.hasta === hasta;
    const ventas = datos.mart_sales.find(fila => periodo(fila) &&
        fila.canal === canal && fila.provincia === provincia);
    const actividad = datos.mart_activity.find(periodo);
    const encuestas = datos.mart_nps.find(fila => periodo(fila) && fila.canal === canal);

    if (!ventas || !actividad || !encuestas) {
        elemento("estado").textContent = "Este período no está disponible en los marts.";
        return;
    }

    elemento("kpi-ventas").textContent = `$${numero(ventas.ventas_millones)} M`;
    elemento("kpi-ticket").textContent = ventas.ticket_miles === ""
        ? "—" : `$${numero(ventas.ticket_miles)} K`;
    elemento("kpi-usuarios").textContent = `${numero(actividad.usuarios_miles)} K`;
    elemento("kpi-nps").textContent = numero(encuestas.nps, 1);

    mostrarRanking(datos.mart_products.filter(fila =>
        fila.mes >= desde && fila.mes <= hasta &&
        fila.canal === canal && fila.provincia === provincia &&
        (!producto || fila.product_id === producto) && Number(fila.posicion) <= Number(top)
    ));

    mostrarGraficos({
        graficos: datos.mart_charts.filter(fila => periodo(fila) && (
            (fila.grafico === "ventas" && fila.canal === canal && fila.provincia === provincia) ||
            (fila.grafico === "usuarios") ||
            (fila.grafico === "nps" && fila.canal === canal)
        )),
        provincias: datos.mart_sales.filter(fila => periodo(fila) &&
            fila.canal === canal && fila.provincia !== "" &&
            (!provincia || fila.provincia === provincia))
    });

    elemento("estado").textContent =
        `Datos del mart · ${numero(ventas.pedidos_validos, 0)} pedidos válidos.`;
    elemento("alcance-filtros").textContent =
        "Meses completos. Canal: ventas, ticket, NPS y productos. " +
        "Provincia: ventas, ticket y productos. Producto: solo ranking; conserva su posición mensual. " +
        "Usuarios: identificados únicos más sesiones anónimas del intervalo. " +
        "Todos los indicadores y gráficos se calculan en el ETL.";
}

function configurarFiltros(datos) {
    for (const tipo of ["canal", "provincia", "producto"]) {
        completarOpciones(tipo, datos.mart_filters.filter(fila => fila.tipo === tipo));
    }
    const meses = datos.mart_filters.filter(fila => fila.tipo === "mes");
    const primero = meses.at(0).valor;
    const ultimo = meses.at(-1).valor;
    for (const id of ["fecha-desde", "fecha-hasta"]) {
        const campo = elemento(id);
        campo.min = primero;
        campo.max = ultimo;
        campo.defaultValue = id === "fecha-desde" ? primero : ultimo;
        campo.value = campo.defaultValue;
    }
    const formulario = elemento("filtros");
    formulario.addEventListener("submit", evento => evento.preventDefault());
    formulario.addEventListener("change", () => actualizar(datos));
    formulario.addEventListener("reset", () => {
        elemento("top-n").value = "2";
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
        elemento("estado").textContent = `No se pudieron cargar los datos: ${error.message}`;
        console.error(error);
    }
}

iniciar();
