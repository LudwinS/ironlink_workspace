use sqlx::{postgres::PgPoolOptions, PgPool};
use std::env;

pub async fn establish_connexion() -> PgPool{
    let database_url = env::var("DATABASE_URL").expect("Fallo por que la variable de entorno DATABASE_URL no esta definida");
    PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("error critico: El sistema no pudo conectarse a la base de datos")
}