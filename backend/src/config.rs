use std::env;

/// Configuración global de la aplicación cargada desde variables de entorno
#[derive(Clone)]
pub struct AppConfig {
    pub jwt_secret: String,
    pub smtp_username: String,
    pub smtp_password: String,
    pub smtp_from: String,
    pub app_base_url: String,
}

impl std::fmt::Debug for AppConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AppConfig")
            .field("smtp_username", &self.smtp_username)
            .field("smtp_from", &self.smtp_from)
            .field("app_base_url", &self.app_base_url)
            .field("jwt_secret", &"[REDACTED]")
            .field("smtp_password", &"[REDACTED]")
            .finish()
    }
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
            app_base_url: env::var("APP_BASE_URL")
                .unwrap_or_else(|_| "http://localhost:8080".to_string()),
        }
    }
}
