use lettre::message::header::ContentType;
use lettre::transport::smtp::authentication::Credentials;
use lettre::{AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor};

use crate::config::AppConfig;

pub type SmtpMailer = AsyncSmtpTransport<Tokio1Executor>;

/// Inicializa el transporte SMTP reutilizable a partir de la configuración
pub fn create_mailer(config: &AppConfig) -> Result<SmtpMailer, String> {
    let creds = Credentials::new(
        config.smtp_username.clone(),
        config.smtp_password.clone(),
    );

    // Conectar a Gmail SMTP con STARTTLS en puerto 587
    let transport = AsyncSmtpTransport::<Tokio1Executor>::starttls_relay("smtp.gmail.com")
        .map_err(|e| format!("Error al configurar transporte SMTP: {}", e))?
        .credentials(creds)
        .port(587)
        .build();
    Ok(transport)
}

/// Envía un código de verificación OTP por correo electrónico usando el transporte compartido
pub async fn send_verification_code(
    mailer: &SmtpMailer,
    from_email: &str,
    to: &str,
    code: &str,
) -> Result<(), String> {
    let html_body = format!(
        r#"
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 500px; margin: auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                <h2 style="color: #2c3e50; text-align: center;">🔗 IronLink</h2>
                <p style="color: #333;">Tu código de verificación es:</p>
                <div style="text-align: center; margin: 20px 0;">
                    <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #2980b9; background: #ecf0f1; padding: 10px 20px; border-radius: 6px;">{code}</span>
                </div>
                <p style="color: #666; font-size: 14px;">Este código expira en 10 minutos. Si no solicitaste este código, ignora este mensaje.</p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="color: #999; font-size: 12px; text-align: center;">IronLink — Plataforma de aprendizaje colaborativo</p>
            </div>
        </body>
        </html>
        "#
    );

    send_email(mailer, from_email, to, "IronLink — Código de verificación", &html_body).await
}

/// Envía un código OTP para restablecer la contraseña
pub async fn send_password_reset_code(
    mailer: &SmtpMailer,
    from_email: &str,
    to: &str,
    code: &str,
) -> Result<(), String> {
    let html_body = format!(
        r#"
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #0b132b; color: #f8fafc; padding: 20px;">
            <div style="max-width: 500px; margin: auto; background: #1e293b; border-radius: 12px; padding: 32px; border: 1px solid #334155;">
                <h2 style="color: #00e5ff; text-align: center; margin-top: 0;">⚡ IronLink Security</h2>
                <h3 style="color: #f8fafc; text-align: center;">Recuperación de Contraseña</h3>
                <p style="color: #cbd5e1; font-size: 14px;">Hemos recibido una solicitud para restablecer tu contraseña. Tu código de seguridad de 6 dígitos es:</p>
                <div style="text-align: center; margin: 24px 0;">
                    <span style="font-size: 34px; font-weight: bold; letter-spacing: 8px; color: #00e5ff; background: #0f172a; padding: 12px 24px; border-radius: 8px; border: 1.5px solid #00e5ff;">{code}</span>
                </div>
                <p style="color: #94a3b8; font-size: 13px;">Este código es de uso único y tiene una vigencia de <b>15 minutos</b>. Si no solicitaste este cambio, puedes ignorar este correo; tu cuenta seguirá protegida.</p>
                <hr style="border: none; border-top: 1px solid #334155; margin: 24px 0;">
                <p style="color: #64748b; font-size: 11px; text-align: center;">IronLink Security • Cifrado Argon2id</p>
            </div>
        </body>
        </html>
        "#
    );

    send_email(mailer, from_email, to, "IronLink — Código de Recuperación de Contraseña", &html_body).await
}

/// Envía un enlace de verificación por correo electrónico usando el transporte compartido
pub async fn send_verification_link(
    mailer: &SmtpMailer,
    from_email: &str,
    to: &str,
    link: &str,
) -> Result<(), String> {
    let html_body = format!(
        r#"
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"></head>
        <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 500px; margin: auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                <h2 style="color: #2c3e50; text-align: center;">🔗 IronLink</h2>
                <p style="color: #333;">Haz clic en el siguiente botón para verificar tu cuenta:</p>
                <div style="text-align: center; margin: 25px 0;">
                    <a href="{link}" style="display: inline-block; background-color: #2980b9; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-size: 16px; font-weight: bold;">Verificar mi cuenta</a>
                </div>
                <p style="color: #666; font-size: 14px;">O copia y pega este enlace en tu navegador:</p>
                <p style="color: #2980b9; font-size: 13px; word-break: break-all;">{link}</p>
                <p style="color: #666; font-size: 14px;">Este enlace expira en 10 minutos.</p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="color: #999; font-size: 12px; text-align: center;">IronLink — Plataforma de aprendizaje colaborativo</p>
            </div>
        </body>
        </html>
        "#
    );

    send_email(mailer, from_email, to, "IronLink — Verifica tu cuenta", &html_body).await
}

/// Función interna para enviar correos electrónicos vía Gmail SMTP usando el transporte existente
async fn send_email(
    mailer: &SmtpMailer,
    from_email: &str,
    to: &str,
    subject: &str,
    html_body: &str,
) -> Result<(), String> {
    let email = Message::builder()
        .from(
            from_email
                .parse()
                .map_err(|e| format!("Error al parsear remitente SMTP: {}", e))?,
        )
        .to(to
            .parse()
            .map_err(|e| format!("Error al parsear destinatario: {}", e))?)
        .subject(subject)
        .header(ContentType::TEXT_HTML)
        .body(html_body.to_string())
        .map_err(|e| format!("Error al construir el correo: {}", e))?;

    mailer
        .send(email)
        .await
        .map_err(|e| format!("Error al enviar correo: {}", e))?;

    Ok(())
}
