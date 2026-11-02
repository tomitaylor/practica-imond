function leerCSV(texto) {
    const filas = [];
    let fila = [];
    let campo = "";
    let entreComillas = false;

    texto = texto.replace(/^\uFEFF/, "");

    for (let i = 0; i < texto.length; i++) {
        const caracter = texto[i];

        if (caracter === '"') {
            if (entreComillas && texto[i + 1] === '"') {
                campo += '"';
                i++;
            } else {
                entreComillas = !entreComillas;
            }
        } else if (caracter === "," && !entreComillas) {
            fila.push(campo);
            campo = "";
        } else if (
            (caracter === "\n" || caracter === "\r") &&
            !entreComillas
        ) {
            fila.push(campo);
            if (fila.some(valor => valor !== "")) filas.push(fila);
            fila = [];
            campo = "";
            if (caracter === "\r" && texto[i + 1] === "\n") i++;
        } else {
            campo += caracter;
        }
    }

    if (entreComillas) throw new Error("CSV con comillas sin cerrar");

    if (campo !== "" || fila.length > 0) {
        fila.push(campo);
        filas.push(fila);
    }

    const columnas = filas.shift();
    if (!columnas) throw new Error("CSV vacío");

    return filas.map(valores => {
        if (valores.length !== columnas.length) {
            throw new Error("CSV con cantidad de columnas incorrecta");
        }

        return Object.fromEntries(
            columnas.map((columna, indice) => [columna, valores[indice]])
        );
    });
}

async function cargarCSV(nombre) {
    const respuesta = await fetch(`../dw/${nombre}.csv`);

    if (!respuesta.ok) {
        throw new Error(`No se pudo cargar ${nombre}: ${respuesta.status}`);
    }

    return leerCSV(await respuesta.text());
}

export async function cargarDatos() {
    const nombres = [
        "mart_sales",
        "mart_products",
        "mart_activity",
        "mart_nps",
        "mart_periods",
        "mart_filters",
        "mart_charts"
    ];

    const tablas = await Promise.all(nombres.map(cargarCSV));

    return Object.fromEntries(
        nombres.map((nombre, indice) => [nombre, tablas[indice]])
    );
}