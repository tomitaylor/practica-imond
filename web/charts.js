function formato(valor) {
    return valor === "" ? "Sin datos" : Number(valor).toLocaleString("es-AR", {
        maximumFractionDigits: 2
    });
}

function agregarTabla(contenedor, filas, unidad) {
    const detalle = document.createElement("details");
    const resumen = document.createElement("summary");
    resumen.textContent = "Ver datos";
    const tabla = document.createElement("table");
    const cabecera = document.createElement("thead");
    const encabezado = document.createElement("tr");
    for (const titulo of ["Mes", unidad]) {
        const th = document.createElement("th");
        th.scope = "col";
        th.textContent = titulo;
        encabezado.append(th);
    }
    cabecera.append(encabezado);
    tabla.append(cabecera);
    const cuerpo = document.createElement("tbody");
    for (const fila of filas) {
        const tr = document.createElement("tr");
        for (const texto of [fila.mes, formato(fila.valor ?? "")]) {
            const td = document.createElement("td");
            td.textContent = texto;
            tr.append(td);
        }
        cuerpo.append(tr);
    }
    tabla.append(cuerpo);
    detalle.append(resumen, tabla);
    contenedor.append(detalle);
}

function mostrarSerie(graficos, id, unidad) {
    const contenedor = document.getElementById(`grafico-${id}`);
    const grafico = graficos.find(fila => fila.grafico === id);
    contenedor.replaceChildren();
    if (!grafico) {
        contenedor.textContent = "Gráfico no disponible en el mart.";
        return;
    }
    contenedor.innerHTML = grafico.contenido;
    agregarTabla(contenedor, JSON.parse(grafico.datos_tabla), unidad);
}

function mostrarProvincias(filas) {
    const contenedor = document.getElementById("grafico-provincias");
    contenedor.replaceChildren();
    for (const dato of filas) {
        const fila = document.createElement("div");
        fila.className = "fila-barra";
        const etiqueta = document.createElement("span");
        etiqueta.textContent = dato.provincia;
        const fondo = document.createElement("div");
        fondo.className = "fondo-barra";
        const barra = document.createElement("div");
        barra.className = "barra";
        barra.style.width = `${dato.ancho_barra}%`;
        fondo.append(barra);
        const valor = document.createElement("strong");
        valor.textContent = `$${formato(dato.ventas_millones)} M`;
        fila.append(etiqueta, fondo, valor);
        contenedor.append(fila);
    }
}

export function mostrarGraficos(datos) {
    mostrarSerie(datos.graficos, "ventas", "ARS");
    mostrarSerie(datos.graficos, "usuarios", "Usuarios activos");
    mostrarSerie(datos.graficos, "nps", "NPS");
    mostrarProvincias(datos.provincias);
}
