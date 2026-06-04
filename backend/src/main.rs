use axum::{
    middleware,
    routing::{delete, get, post, put},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};

mod db;
mod auth;
mod config;
mod mailer;
mod nodos;

use auth::verification::AppState;

#[tokio::main]
async fn main() {
    // 1. Cargar variables de entorno
    dotenvy::dotenv().ok();

    println!("Inicializando IronLink Backend...");

    // 2. Cargar configuración desde variables de entorno
    let app_config = config::AppConfig::from_env();
    let app_config_arc = std::sync::Arc::new(app_config);
    println!("Configuración cargada correctamente.");

    // 3. Conectar a la base de datos (PgPool)
    let pool = db::conn::establish_connexion().await;
    println!("Conectado a la base de datos con éxito.");

    // Ejecutar migraciones SQL
    println!("Ejecutando migraciones SQL del Sprint 1...");
    let migration_sql = std::fs::read_to_string("migrations/001_sprint1_complete.sql")
        .expect("No se pudo leer el archivo de migración migrations/001_sprint1_complete.sql");
    match sqlx::raw_sql(sqlx::AssertSqlSafe(migration_sql)).execute(&pool).await {
        Ok(_) => println!("Migraciones ejecutadas/verificadas con éxito."),
        Err(e) => println!("Advertencia/Error al ejecutar migraciones: {}", e),
    }

    // Inicializar el mailer SMTP global
    let mailer = mailer::create_mailer(&app_config_arc)
        .expect("Error crítico al inicializar el mailer SMTP global");

    // 4. Crear estado compartido de la aplicación
    let app_state = AppState {
        pool,
        config: app_config_arc.clone(),
        mailer,
    };

    // 5. Configurar CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // 6. Rutas públicas (no requieren autenticación)
    let public_routes = Router::new()
        .route("/register", post(auth::service::register_user))
        .route("/login", post(auth::service::login))
        .route("/request-verification", post(auth::verification::request_verification))
        .route("/verify-email", post(auth::verification::verify_email))
        .route("/verify-link/{token}", get(auth::verification::verify_link));

    // 7. Rutas protegidas (requieren JWT válido)
    let protected_routes = Router::new()
        .route("/nodos", post(nodos::service::create_nodo))
        .route("/nodos", get(nodos::service::list_nodos))
        .route("/nodos/join/{token}", post(nodos::service::join_nodo))
        .route("/nodos/{id}", delete(nodos::service::delete_nodo))
        .layer(middleware::from_fn(auth::middleware::jwt_auth));

    // 8. Rutas de administrador (requieren JWT + rol ADMIN)
    let admin_routes = Router::new()
        .route("/admin/users/{id}/role", put(auth::service::change_user_role))
        .layer(middleware::from_fn(auth::middleware::require_admin))
        .layer(middleware::from_fn(auth::middleware::jwt_auth));

    // 9. Combinar todas las rutas
    let app = Router::new()
        .merge(public_routes)
        .merge(protected_routes)
        .merge(admin_routes)
        .layer(cors)
        .layer(axum::Extension(app_config_arc))
        .with_state(app_state);

    // 10. Configurar la dirección local (localhost en el puerto 8080)
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("Servidor web escuchando en: http://{}", addr);

    // 11. Enlazar el socket TCP y arrancar el servidor
    let listener = tokio::net::TcpListener::bind(addr).await
        .expect("Error crítico: No se pudo enlazar el puerto 8080. ¿Ya está en uso?");

    axum::serve(listener, app).await
        .expect("Error al ejecutar el servidor web de Axum");
}