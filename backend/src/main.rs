use axum::{routing::post, Router};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};

mod db;
mod auth; // 1. Registramos el módulo auth para que compile

#[tokio::main]
async fn main() {
    // 2. Cargar variables de entorno
    dotenvy::dotenv().expect("Abortando, no se encontro el archivo .env en la raiz del backend");

    println!("Inicializando...");

    // 3. Conectar a la base de datos (PgPool)
    let pool = db::conn::establish_connexion().await;
    println!("Conectado a la base de datos con éxito.");

    // Configurar CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // 4. Crear el enrutador de Axum y montar la ruta /register
    // Le pasamos el 'pool' como estado (State) para que 'register_user' pueda usarlo
    let app = Router::new()
        .route("/register", post(auth::service::register_user))
        .layer(cors)
        .with_state(pool);

    // 5. Configurar la dirección local (localhost en el puerto 8080)
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("Servidor web escuchando en: http://{}", addr);

    // 6. Enlazar el socket TCP y arrancar el servidor
    let listener = tokio::net::TcpListener::bind(addr).await
        .expect("Error crítico: No se pudo enlazar el puerto 8080. ¿Ya está en uso?");

    axum::serve(listener, app).await
        .expect("Error al ejecutar el servidor web de Axum");
}