const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const outputDir = '/Users/ludwin/Developer/ironlink_workspace/tests/e2e/diagrams';
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const diagrams = [
  {
    name: 'diag_01_architecture.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK</div>
        <div class="title">Arquitectura Global del Sistema</div>
        <div class="subtitle">Interacción entre Flutter Web, Rust (Axum), PostgreSQL y Servicios de Red</div>
      </div>
      <div class="grid-3">
        <div class="card client">
          <div class="badge">FRONTEND (CLIENTE)</div>
          <h3>Flutter Multiplataforma</h3>
          <div class="item">🖥️ <b>Flutter Web / Desktop</b>: Interfaz reactiva</div>
          <div class="item">🔄 <b>Flutter Riverpod</b>: Gestión de estado global</div>
          <div class="item">🗺️ <b>GoRouter</b>: Enrutamiento dinámico y Route Guards</div>
          <div class="item">🌐 <b>Dio Client</b>: Interceptores HTTP y auto-refresh JWT</div>
          <div class="item">🔒 <b>SecureVault</b>: Persistencia cifrada en local</div>
        </div>
        <div class="card backend">
          <div class="badge badge-accent">BACKEND (API REST + WS)</div>
          <h3>Rust + Tokio + Axum</h3>
          <div class="item">🛡️ <b>Auth Middleware</b>: Validación JWT y RBAC</div>
          <div class="item">📬 <b>Mailer SMTP</b>: Envío de OTPs y Enlaces mágicos</div>
          <div class="item">💼 <b>Nodos Service</b>: Gestión de salas y miembros</div>
          <div class="item">💬 <b>Chat Service</b>: Mensajería persistente en canales</div>
          <div class="item">⚡ <b>Tokio Async</b>: Alto rendimiento y concurrencia</div>
        </div>
        <div class="card db">
          <div class="badge badge-db">PERSISTENCIA & SERVICIOS</div>
          <h3>PostgreSQL 18 + SQLx</h3>
          <div class="item">👥 <b>users</b>: Cuentas con hash Argon2id y roles</div>
          <div class="item">🔑 <b>verification_tokens</b>: OTPs y magic links</div>
          <div class="item">🎫 <b>refresh_tokens</b>: Sesiones activas rotativas</div>
          <div class="item">🌐 <b>nodos & nodo_miembros</b>: Espacios y RBAC</div>
          <div class="item">💬 <b>mensajes</b>: Historial persistente de chats</div>
        </div>
      </div>
      <div class="footer-arrows">
        <div class="arrow-box"><span>⇄</span> Cliente Flutter conecta mediante REST API / WebSockets con Bearer JWT al Backend</div>
        <div class="arrow-box"><span>⇄</span> Backend ejecuta consultas asíncronas parametrizadas con SQLx a PostgreSQL</div>
      </div>
    </div>
    `
  },
  {
    name: 'diag_02_registration.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK IAM</div>
        <div class="title">Flujo 1: Registro de Usuarios y Creación de Cuenta</div>
        <div class="subtitle">Validación, Hashing Criptográfico y Estado Pendiente de Activación</div>
      </div>
      <div class="flow-steps">
        <div class="step-card">
          <div class="step-num">1</div>
          <h4>Formulario de Registro</h4>
          <p>El usuario ingresa su Nombre, Correo, Teléfono y Contraseña en la interfaz Flutter.</p>
          <div class="code-tag">POST /register</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">2</div>
          <h4>Validación & Argon2id</h4>
          <p>El backend valida formato de email, teléfono único y calcula el hash Argon2id con salt aleatorio.</p>
          <div class="badge-mini">Seguridad Fail-Closed</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">3</div>
          <h4>Guardado en PostgreSQL</h4>
          <p>Se inserta el usuario con rol <b>MEMBER</b> y estado inicial obligatorio <b>PENDING</b>.</p>
          <div class="code-tag">estado = 'PENDING'</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">4</div>
          <h4>Redirección a Verificación</h4>
          <p>El frontend recibe confirmación 200 OK y redirige de inmediato a <code>/verification</code>.</p>
          <div class="badge-mini">GoRouter Navigation</div>
        </div>
      </div>
    </div>
    `
  },
  {
    name: 'diag_03_verification.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK IAM</div>
        <div class="title">Flujo 2: Verificación de Cuenta por Doble Canal</div>
        <div class="subtitle">Activación segura de cuenta mediante Código OTP (6 dígitos) o Enlace Mágico por Correo</div>
      </div>
      <div class="split-flow">
        <div class="split-top">
          <div class="mini-box">
            <b>Paso 1: Solicitud de Verificación</b><br/>
            Usuario elige método en la pantalla Flutter ➔ <code>POST /request-verification</code> (Rust backend genera token)
          </div>
        </div>
        <div class="channels-grid">
          <div class="channel-card otp">
            <div class="channel-badge">CANAL 1: CÓDIGO OTP</div>
            <h4>Código de 6 Dígitos</h4>
            <div class="bullet">1. Backend guarda código aleatorio en <code>verification_tokens</code>.</div>
            <div class="bullet">2. Mailer SMTP envía el código al correo del usuario.</div>
            <div class="bullet">3. Usuario ingresa los 6 dígitos en pantalla ➔ <code>POST /verify-email</code>.</div>
            <div class="bullet">4. Se valida coincidencia y tiempo de expiración.</div>
          </div>
          <div class="channel-card link">
            <div class="channel-badge">CANAL 2: ENLACE MÁGICO</div>
            <h4>Enlace por Correo</h4>
            <div class="bullet">1. Backend genera un token criptográfico SHA-256 de 64 caracteres.</div>
            <div class="bullet">2. Mailer SMTP envía un enlace clicable al correo.</div>
            <div class="bullet">3. Usuario hace clic en <code>GET /verify-link/{token}</code>.</div>
            <div class="bullet">4. Servidor valida el token directamente.</div>
          </div>
        </div>
        <div class="split-bottom">
          <div class="success-box">
            <b>Paso Final: Activación</b> ➔ Se ejecuta <code>UPDATE users SET estado = 'ACTIVE'</code>, se borra el token de verificación y el usuario avanza a <code>/verification-success</code>.
          </div>
        </div>
      </div>
    </div>
    `
  },
  {
    name: 'diag_04_auth_jwt.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK SEGURIDAD</div>
        <div class="title">Flujo 3: Autenticación, JWT y Manejo de Sesión</div>
        <div class="subtitle">Esquema de Tokens Desacoplados, Persistencia en SecureVault e Interceptores Dio</div>
      </div>
      <div class="flow-steps">
        <div class="step-card">
          <div class="step-num">1</div>
          <h4>Petición de Login</h4>
          <p>Usuario ingresa credenciales en <code>/login</code>. Opcionalmente activa "Recuérdame".</p>
          <div class="code-tag">POST /login</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">2</div>
          <h4>Verificación Backend</h4>
          <p>Axum valida contraseña con Argon2id y comprueba que el estado sea <code>ACTIVE</code>.</p>
          <div class="badge-mini">Argon2id + Fail-Closed</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">3</div>
          <h4>Generación de Tokens</h4>
          <p>Se emite un <b>Access Token (JWT)</b> de corta duración y un <b>Refresh Token (UUID)</b> en DB.</p>
          <div class="code-tag">JWT + UUID Token</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">4</div>
          <h4>Guardado & Navegación</h4>
          <p>Tokens se guardan en <code>SecureVault</code>. Interceptor Dio inyecta <code>Bearer JWT</code> en cada request.</p>
          <div class="badge-mini">Redirect /home</div>
        </div>
      </div>
    </div>
    `
  },
  {
    name: 'diag_05_nodos_workspace.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK WORKSPACES</div>
        <div class="title">Flujo 4: Gestión de Nodos y Colaboración</div>
        <div class="subtitle">Creación de Espacios, Generación de Tokens de Acceso y Modelo de Roles (RBAC)</div>
      </div>
      <div class="grid-2">
        <div class="workflow-card">
          <div class="badge">A. CREACIÓN DE NODO</div>
          <h4>Propietario / Administrador</h4>
          <div class="step-line"><b>1.</b> Clic en "+ Crear nodo" ➔ Ingresa Nombre y Descripción.</div>
          <div class="step-line"><b>2.</b> <code>POST /nodos</code> (con Bearer JWT).</div>
          <div class="step-line"><b>3.</b> Backend genera <code>token_acceso</code> único de 32 caracteres hexadecimales.</div>
          <div class="step-line"><b>4.</b> Se asigna automáticamente rol <code>ADMIN / OWNER</code> al creador.</div>
          <div class="step-line"><b>5.</b> El nodo aparece de inmediato en el Tablero y en la barra de canales.</div>
        </div>
        <div class="workflow-card">
          <div class="badge badge-accent">B. UNIÓN MEDIANTE TOKEN</div>
          <h4>Nuevos Integrantes</h4>
          <div class="step-line"><b>1.</b> Administrador copia y comparte el token del nodo.</div>
          <div class="step-line"><b>2.</b> Nuevo miembro abre diálogo "Unirse a un nodo".</div>
          <div class="step-line"><b>3.</b> <code>POST /nodos/join/{token}</code>.</div>
          <div class="step-line"><b>4.</b> Backend valida que el usuario no esté baneado y lo añade como <code>MEMBER</code>.</div>
          <div class="step-line"><b>5.</b> Se desbloquea el acceso instantáneo a la sala de chat del nodo.</div>
        </div>
      </div>
    </div>
    `
  },
  {
    name: 'diag_06_chat_messaging.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK CHAT</div>
        <div class="title">Flujo 5: Chat Persistente en Canales de Nodo</div>
        <div class="subtitle">Carga Histórica de Mensajes, Publicación en Vivo y Registro en Base de Datos</div>
      </div>
      <div class="flow-steps">
        <div class="step-card">
          <div class="step-num">1</div>
          <h4>Selección de Canal</h4>
          <p>Usuario hace clic en el canal <code># Laboratorio de Ingenieria</code> en la barra lateral.</p>
          <div class="code-tag">GET /nodos/{id}/mensajes</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">2</div>
          <h4>Carga de Historial</h4>
          <p>PostgreSQL retorna los mensajes ordenados con nombre de autor, avatar y timestamp.</p>
          <div class="badge-mini">Renderizado en Lista</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">3</div>
          <h4>Envío de Mensaje</h4>
          <p>Usuario escribe en la barra inferior y presiona el botón de envío.</p>
          <div class="code-tag">POST /nodos/{id}/mensajes</div>
        </div>
        <div class="step-arrow">➔</div>
        <div class="step-card">
          <div class="step-num">4</div>
          <h4>Persistencia & Stream</h4>
          <p>Backend inserta en tabla <code>mensajes</code>. Riverpod actualiza la interfaz reactivamente.</p>
          <div class="badge-mini">Burbuja Actualizada</div>
        </div>
      </div>
    </div>
    `
  }
];

const css = `
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
  body { background: #000c18; padding: 20px; display: flex; justify-content: center; }
  .canvas { width: 1000px; background: #001524; border: 1px solid #1e3a5f; border-radius: 16px; padding: 28px; color: #f1f5f9; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
  .header { border-bottom: 1px solid #1e3a5f; padding-bottom: 16px; margin-bottom: 24px; }
  .logo { font-size: 12px; font-weight: 800; letter-spacing: 2px; color: #00e5ff; margin-bottom: 4px; }
  .title { font-size: 22px; font-weight: 700; color: #ffffff; margin-bottom: 4px; }
  .subtitle { font-size: 13px; color: #94a3b8; }
  
  .grid-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 16px; margin-bottom: 16px; }
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
  
  .card { background: #002238; border: 1px solid #1e40af44; border-radius: 12px; padding: 18px; }
  .card.client { border-top: 4px solid #00e5ff; }
  .card.backend { border-top: 4px solid #00bfa5; }
  .card.db { border-top: 4px solid #f59e0b; }
  
  .badge { display: inline-block; font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 6px; background: #00e5ff22; color: #00e5ff; margin-bottom: 8px; }
  .badge-accent { background: #00bfa522; color: #00bfa5; }
  .badge-db { background: #f59e0b22; color: #f59e0b; }
  .badge-mini { display: inline-block; font-size: 10px; padding: 2px 6px; border-radius: 4px; background: #00e5ff15; color: #00e5ff; margin-top: 6px; }
  
  h3 { font-size: 16px; font-weight: 700; margin-bottom: 12px; color: #ffffff; }
  h4 { font-size: 15px; font-weight: 600; margin-bottom: 6px; color: #ffffff; }
  
  .item { font-size: 12px; color: #cbd5e1; margin-bottom: 8px; line-height: 1.4; }
  .item b { color: #f8fafc; }
  
  .footer-arrows { display: flex; flex-direction: column; gap: 8px; margin-top: 12px; }
  .arrow-box { background: #002a45; border: 1px dashed #00e5ff66; border-radius: 8px; padding: 8px 14px; font-size: 12px; color: #94a3b8; }
  .arrow-box span { color: #00e5ff; font-weight: bold; margin-right: 6px; }
  
  .flow-steps { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-top: 10px; }
  .step-card { flex: 1; background: #002238; border: 1px solid #1e3a5f; border-radius: 12px; padding: 16px 12px; text-align: center; min-height: 170px; display: flex; flex-direction: column; align-items: center; }
  .step-num { width: 32px; height: 32px; border-radius: 50%; background: #00bfa5; color: #001524; font-weight: 800; font-size: 15px; display: flex; align-items: center; justify-content: center; margin-bottom: 10px; }
  .step-card h4 { font-size: 13px; color: #ffffff; margin-bottom: 6px; }
  .step-card p { font-size: 11px; color: #94a3b8; line-height: 1.35; flex-grow: 1; }
  .step-arrow { color: #00bfa5; font-size: 20px; font-weight: bold; flex-shrink: 0; }
  .code-tag { font-family: monospace; font-size: 10px; background: #00101d; border: 1px solid #1e3a5f; color: #38bdf8; padding: 2px 6px; border-radius: 4px; margin-top: 6px; }
  
  .split-flow { display: flex; flex-direction: column; gap: 14px; }
  .split-top { background: #002238; border: 1px solid #1e3a5f; border-radius: 10px; padding: 12px 16px; font-size: 13px; color: #cbd5e1; }
  .channels-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .channel-card { background: #002238; border: 1px solid #1e3a5f; border-radius: 12px; padding: 16px; }
  .channel-card.otp { border-left: 4px solid #00e5ff; }
  .channel-card.link { border-left: 4px solid #00bfa5; }
  .channel-badge { font-size: 10px; font-weight: 800; color: #00e5ff; margin-bottom: 6px; }
  .channel-card.link .channel-badge { color: #00bfa5; }
  .bullet { font-size: 12px; color: #94a3b8; margin-bottom: 6px; line-height: 1.4; }
  .bullet code { background: #00101d; color: #38bdf8; padding: 1px 4px; border-radius: 3px; font-family: monospace; font-size: 11px; }
  .split-bottom .success-box { background: #002b28; border: 1px solid #00bfa5; border-radius: 10px; padding: 12px 16px; font-size: 13px; color: #6ee7b7; }
  
  .workflow-card { background: #002238; border: 1px solid #1e3a5f; border-radius: 12px; padding: 18px; }
  .step-line { font-size: 12px; color: #cbd5e1; margin-bottom: 8px; line-height: 1.4; }
  .step-line b { color: #00e5ff; }
`;

(async () => {
  console.log('Generating high-res diagram images...');
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 1040, height: 600 },
    deviceScaleFactor: 2 // 2x high resolution retina
  });

  for (const diag of diagrams) {
    const fullHtml = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>${css}</style>
        </head>
        <body>${diag.html}</body>
      </html>
    `;

    await page.setContent(fullHtml, { waitUntil: 'load' });
    const canvasElement = await page.$('.canvas');
    const outPath = path.join(outputDir, diag.name);
    await canvasElement.screenshot({ path: outPath });
    console.log('Generated diagram:', outPath);
  }

  await browser.close();
  console.log('All diagrams generated successfully!');
})();
