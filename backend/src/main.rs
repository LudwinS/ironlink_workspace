use axum::{routing::get, Router};
use tokio::net::TcpListener;

mod db;

async fn health_check() -> &'static str {
    "Hola mundo.\nQue tal\nTengo sueño :("
}

#[tokio::main]
async fn main() {
    dotenvy::dotenv().expect("Abortando: no se encontro el archivo .env en la raiz del backend");

    println!("Inicializando el plano de control de IronLink...");

    let pool = db::conn::establish_connexion().await;
    println!("Conexión persistente a PostgreSQL establecida con éxito.");

    let listener = TcpListener::bind("0.0.0.0:8080")
        .await
        .expect("Fallo de red: No se pudo reservar el puerto 8080 en el sistema");
    println!("Servidor web escuchando en http://localhost:8080 ...");

    let app = Router::new()
        .route("/health", get(health_check))
        .with_state(pool);

    axum::serve(listener, app)
        .await
        .expect("Error fatal: El servidor web de Axum colapsó");
}
