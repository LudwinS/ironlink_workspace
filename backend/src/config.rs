use std::env;

/// Configuración global de la aplicación cargada desde variables de entorno
#[derive(Clone, Debug)]
pub struct AppConfig {
    pub jwt_secret: String,
    pub smtp_username: String,
    pub smtp_password: String,
    pub smtp_from: String,
}

impl AppConfig {
    /// Carga la configuración desde las variables de entorno.
    /// Aborta el proceso si alguna variable requerida no está definida.
    pub fn from_env() -> Self {
        Self {
            jwt_secret: env::var("JWT_SECRET")
                .expect("La variable de entorno JWT_SECRET no está definida"),
            smtp_username: env::var("SMTP_USERNAME")
                .expect("La variable de entorno SMTP_USERNAME no está definida"),
            smtp_password: env::var("SMTP_PASSWORD")
                .expect("La variable de entorno SMTP_PASSWORD no está definida"),
            smtp_from: env::var("SMTP_FROM")
                .expect("La variable de entorno SMTP_FROM no está definida"),
        }
    }
}
