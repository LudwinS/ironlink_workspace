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
        <div class="logo">⚡ IRONLINK ENTERPRISE</div>
        <div class="title">Arquitectura Global del Sistema de Escritorio</div>
        <div class="subtitle">Interacción entre la Aplicación Nativa de Escritorio, Backend en Rust (Axum), PostgreSQL 18 y Servicios de Red</div>
      </div>
      <div class="grid-3">
        <div class="card client">
          <div class="badge">APLICACIÓN DE ESCRITORIO (CLIENTE)</div>
          <h3>Cliente Nativo Desktop</h3>
          <div class="item">🖥️ <b>Flutter Desktop (C++ Runner)</b>: Interfaz nativa acelerada por GPU</div>
          <div class="item">🔄 <b>Flutter Riverpod</b>: Gestión de estado reactivo y unidireccional</div>
          <div class="item">🗺️ <b>GoRouter</b>: Enrutamiento seguro y Route Guards locales</div>
          <div class="item">🌐 <b>Dio Client</b>: Interceptores de red y auto-refresh de JWT</div>
          <div class="item">🔒 <b>SecureVault</b>: Almacenamiento cifrado en Windows DPAPI / macOS Keychain</div>
        </div>
        <div class="card backend">
          <div class="badge badge-accent">BACKEND (API REST ASÍNCRONA)</div>
          <h3>Rust Tokio Runtime + Axum</h3>
          <div class="item">🛡️ <b>Auth Middleware</b>: Validación criptográfica de JWT y RBAC</div>
          <div class="item">📬 <b>Mailer SMTP</b>: Servicio de entrega de OTPs y Enlaces de activación</div>
          <div class="item">💼 <b>Nodos Service</b>: Gestión de espacios de trabajo, subgrupos y roles</div>
          <div class="item">💬 <b>Chat Service</b>: Mensajería persistente en canales en tiempo real</div>
          <div class="item">⚡ <b>Tokio Engine</b>: Concurrencia de ultra-baja latencia (< 1ms)</div>
        </div>
        <div class="card db">
          <div class="badge badge-db">PERSISTENCIA DE DATOS & ACID</div>
          <h3>PostgreSQL 18 Enterprise</h3>
          <div class="item">👥 <b>users</b>: Cuentas con hash Argon2id y control de presencia</div>
          <div class="item">🔑 <b>verification_tokens</b>: OTPs de 6 dígitos y magic links</div>
          <div class="item">🎫 <b>refresh_tokens</b>: Sesiones activas con rotación de UUID</div>
          <div class="item">🌐 <b>nodos & nodo_miembros</b>: Espacios y jerarquías RBAC</div>
          <div class="item">💬 <b>mensajes & subgrupos</b>: Historial relacional y células temáticas</div>
        </div>
      </div>
      <div class="footer-arrows">
        <div class="arrow-box"><span>⇄</span> Cliente de Escritorio conecta mediante REST API segura con Bearer JWT al Servidor Rust</div>
        <div class="arrow-box"><span>⇄</span> Backend ejecuta consultas parametrizadas asíncronas con SQLx Pool hacia PostgreSQL 18</div>
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
        <div class="subtitle">Validación de Entropía, Hashing Argon2id y Estado Pendiente de Activación</div>
      </div>
      <div class="flow-container">
        <div class="step-card">
          <div class="step-badge">PASO 1</div>
          <h4>Formulario de Registro</h4>
          <p>El usuario ingresa Nombre, Correo institucional, Teléfono y Contraseña en la aplicación de escritorio.</p>
          <div class="tag">POST /register</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card highlight">
          <div class="step-badge">PASO 2</div>
          <h4>Validación & Argon2id</h4>
          <p>El backend valida formato de email, unicidad y genera el hash Argon2id con salt aleatorio de hardware OsRng.</p>
          <div class="tag tag-accent">Salt Criptográfico OsRng</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">PASO 3</div>
          <h4>Guardado en PostgreSQL</h4>
          <p>Se inserta el registro con rol MEMBER y estado inicial obligatorio PENDING para impedir accesos no autorizados.</p>
          <div class="tag">estado = 'PENDING'</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">PASO 4</div>
          <h4>Transición a Verificación</h4>
          <p>La aplicación recibe respuesta 200 OK y abre automáticamente la pantalla de verificación de identidad.</p>
          <div class="tag">Navegación Local</div>
        </div>
      </div>
      <div class="footer-note">
        🔒 <b>Seguridad de Contraseñas:</b> Las contraseñas nunca se transmiten ni almacenan en texto plano. Argon2id protege contra ataques de diccionario y fuerza bruta acelerada por GPU.
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
        <div class="title">Flujo 2: Verificación de Identidad por Doble Canal (OTP & Enlace)</div>
        <div class="subtitle">Activación Segura de Cuenta mediante Código de 6 Dígitos o Enlace Criptográfico</div>
      </div>
      <div class="grid-2">
        <div class="card client">
          <div class="badge">CANAL A: CÓDIGO OTP (6 DÍGITOS)</div>
          <h3>Verificación Directa en App</h3>
          <div class="item">🔢 <b>Generación Criptográfica</b>: Código aleatorio de 6 dígitos</div>
          <div class="item">⏱️ <b>Vigencia Temporal</b>: Expiración estricta de 15 minutos</div>
          <div class="item">⚡ <b>Validación Inmediata</b>: Usuario digita el código en la app</div>
          <div class="tag">POST /verify-email</div>
        </div>
        <div class="card backend">
          <div class="badge badge-accent">CANAL B: ENLACE MÁGICO</div>
          <h3>Activación de un Solo Uso</h3>
          <div class="item">🔗 <b>Token Hexadecimal</b>: Cadena segura de 64 caracteres</div>
          <div class="item">📧 <b>Entrega SMTP</b>: Envío seguro al buzón del usuario</div>
          <div class="item">🛡️ <b>Consumo Único</b>: Invalidación atómica tras el primer clic</div>
          <div class="tag tag-accent">GET /verify-link/{token}</div>
        </div>
      </div>
      <div class="footer-note">
        ✅ <b>Transición Atómica:</b> Al verificar exitosamente, PostgreSQL actualiza <code>estado = 'ACTIVE'</code>, habilita el inicio de sesión y purga los tokens utilizados.
      </div>
    </div>
    `
  },
  {
    name: 'diag_04_auth_jwt.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK IAM</div>
        <div class="title">Flujo 3: Autenticación, JWT Dual y Manejo de Sesión Segura</div>
        <div class="subtitle">Emisión de Access Token de Corta Duración y Refresh Token Rotativo en Almacén Cifrado</div>
      </div>
      <div class="flow-container">
        <div class="step-card">
          <div class="step-badge">1. CREDENCIALES</div>
          <h4>Envío de Acceso</h4>
          <p>Usuario ingresa credenciales en la aplicación de escritorio.</p>
          <div class="tag">POST /login</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card highlight">
          <div class="step-badge">2. ARGON2ID & ESTADO</div>
          <h4>Verificación Backend</h4>
          <p>Verifica hash Argon2id, confirma estado 'ACTIVE' y revisa contador de reintentos.</p>
          <div class="tag tag-accent">Anti-Fuerza Bruta</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">3. TOKENS DUALES</div>
          <h4>Emisión de JWT</h4>
          <p>Genera Access Token (15 min) y Refresh Token UUIDv4 (7 días) en PostgreSQL.</p>
          <div class="tag">JWT HMAC-SHA256</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">4. SECURE VAULT</div>
          <h4>Persistencia Cifrada</h4>
          <p>La aplicación guarda los tokens en Windows DPAPI / macOS Keychain local.</p>
          <div class="tag">Almacén Seguro OS</div>
        </div>
      </div>
      <div class="footer-note">
        🛡️ <b>Protección Fail-Safe:</b> Ante 5 intentos fallidos, la cuenta se bloquea por 15 minutos. El Access Token viaja en la cabecera <code>Authorization: Bearer</code> de cada petición.
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
        <div class="title">Flujo 4: Gestión de Nodos y Control de Acceso Jerárquico RBAC</div>
        <div class="subtitle">Creación de Espacios, Invitaciones Criptográficas y Moderación de Integrantes</div>
      </div>
      <div class="grid-3">
        <div class="card client">
          <div class="badge">1. CREACIÓN DE NODO</div>
          <h3>Espacio Colaborativo</h3>
          <div class="item">📝 <b>Metadatos</b>: Nombre y descripción del espacio</div>
          <div class="item">🔑 <b>Token de Acceso</b>: 32 caracteres hexadecimales únicos</div>
          <div class="item">👑 <b>Rol OWNER</b>: Asignación automática al creador</div>
          <div class="tag">POST /nodos</div>
        </div>
        <div class="card backend">
          <div class="badge badge-accent">2. UNIÓN POR INVITACIÓN</div>
          <h3>Ingreso de Integrantes</h3>
          <div class="item">🚪 <b>Validación de Token</b>: Búsqueda del nodo activo</div>
          <div class="item">🚫 <b>Comprobación de Baneo</b>: Verificación en <code>nodo_baneos</code></div>
          <div class="item">👥 <b>Registro</b>: Inserción en <code>nodo_miembros</code> con rol MEMBER</div>
          <div class="tag tag-accent">POST /nodos/join/{token}</div>
        </div>
        <div class="card db">
          <div class="badge badge-db">3. MODERACIÓN & RBAC</div>
          <h3>Control Administrativo</h3>
          <div class="item">⚡ <b>Expulsión (Kick)</b>: Salida inmediata de la sala</div>
          <div class="item">⛔ <b>Baneo (Ban)</b>: Bloqueo permanente de reingreso</div>
          <div class="item">🔄 <b>Jerarquía</b>: OWNER > ADMIN > MODERATOR > MEMBER</div>
          <div class="tag">DELETE /nodos/{id}/miembros</div>
        </div>
      </div>
      <div class="footer-note">
        💼 <b>Aislamiento Total:</b> Cada nodo funciona como una unidad de trabajo independiente con sus propios canales, subgrupos, reuniones y listas de integrantes.
      </div>
    </div>
    `
  },
  {
    name: 'diag_06_chat_messaging.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK MESSAGING</div>
        <div class="title">Flujo 5: Chat Persistente en Canales en Tiempo Real</div>
        <div class="subtitle">Comunicación Segura dentro del Espacio de Trabajo con Retención en PostgreSQL</div>
      </div>
      <div class="flow-container">
        <div class="step-card">
          <div class="step-badge">1. COMPOSICIÓN</div>
          <h4>Envío de Mensaje</h4>
          <p>El integrante escribe en el canal y la app valida texto no vacío.</p>
          <div class="tag">POST /nodos/{id}/mensajes</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card highlight">
          <div class="step-badge">2. PERSISTENCIA</div>
          <h4>Escritura en BD</h4>
          <p>El backend guarda el mensaje asociando nodo_id, usuario_id y timestamp UTC.</p>
          <div class="tag tag-accent">PostgreSQL 18 tabla mensajes</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">3. RESOLUCIÓN</div>
          <h4>Carga Histórica</h4>
          <p>Mapeo relacional con tabla <code>users</code> para obtener nombre, rol y avatar del autor.</p>
          <div class="tag">GET /nodos/{id}/mensajes</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">4. RENDERIZADO</div>
          <h4>Experiencia de Usuario</h4>
          <p>Renderizado con burbujas diferenciadas, autoría clara y auto-scroll inteligente.</p>
          <div class="tag">UI Nativa Acelerada</div>
        </div>
      </div>
      <div class="footer-note">
        💬 <b>Disponibilidad Continua:</b> Los integrantes pueden consultar todo el historial de conversaciones previas al incorporarse al nodo en cualquier momento.
      </div>
    </div>
    `
  },
  {
    name: 'diag_07_profile.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK IAM</div>
        <div class="title">Flujo 6: Perfil de Usuario, Presencia y Seguridad Criptográfica</div>
        <div class="subtitle">Personalización de Avatar, Biografía, Estados de Presencia y Cambio de Clave con Argon2id</div>
      </div>
      <div class="flow-container">
        <div class="step-card">
          <div class="step-badge">PASO 1</div>
          <h4>Apertura de Perfil</h4>
          <p>El usuario pulsa su avatar o nombre en la barra de herramientas.</p>
          <div class="tag">GET /users/me</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card highlight">
          <div class="step-badge">PASO 2</div>
          <h4>Personalización Visual</h4>
          <p>Selección de paleta de color (8 tonos), estado de presencia ('En línea', 'Ocupado') y biografía.</p>
          <div class="tag tag-accent">StateNotifier (Riverpod)</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">PASO 3</div>
          <h4>Seguridad de Acceso</h4>
          <p>Verificación de clave actual con Argon2id y validación de entropía para la nueva contraseña.</p>
          <div class="tag">PUT /users/me/password</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">PASO 4</div>
          <h4>Persistencia & Red</h4>
          <p>Actualización en PostgreSQL <code>users</code> y propagación instantánea a la interfaz de escritorio.</p>
          <div class="tag">PUT /users/me ➔ 200 OK</div>
        </div>
      </div>
      <div class="footer-note">
        🔒 <b>Privacidad y Control:</b> El correo electrónico permanece inmutable tras la verificación. La actualización de presencia permite a los integrantes coordinar tiempos de trabajo eficazmente.
      </div>
    </div>
    `
  },
  {
    name: 'diag_08_subgrupos.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK WORKSPACES</div>
        <div class="title">Flujo 7: Creación y Gestión de Subgrupos de Nodo</div>
        <div class="subtitle">Estructuración de Células de Trabajo Temáticas, Control de Privacidad y Membresías</div>
      </div>
      <div class="grid-3">
        <div class="card client">
          <div class="badge">1. CREACIÓN DE CÉLULA</div>
          <h3>Configuración del Subgrupo</h3>
          <div class="item">📝 <b>Nombre & Temática</b>: Definición de objetivos</div>
          <div class="item">🔒 <b>Privacidad</b>: Selector Público / Privado</div>
          <div class="item">👑 <b>Auto-Asignación</b>: Inclusión automática del creador</div>
          <div class="tag">POST /nodos/{id}/subgrupos</div>
        </div>
        <div class="card backend">
          <div class="badge badge-accent">2. CONTROL DE ACCESO (RBAC)</div>
          <h3>Validación en Servidor</h3>
          <div class="item">🛡️ <b>Membresía de Nodo</b>: Solo miembros activos acceden</div>
          <div class="item">👥 <b>Gestión de Integrantes</b>: Registro en <code>subgrupo_miembros</code></div>
          <div class="item">🚪 <b>Unirse / Salir</b>: Participación voluntaria del integrante</div>
          <div class="tag tag-accent">POST .../subgrupos/{id}/join</div>
        </div>
        <div class="card db">
          <div class="badge badge-db">3. PERSISTENCIA & CANALES</div>
          <h3>Tablas Relacionales</h3>
          <div class="item">🗄️ <b>subgrupos</b>: Metadatos y propietario</div>
          <div class="item">🔗 <b>subgrupo_miembros</b>: Relación N:M de participantes</div>
          <div class="item">🗑️ <b>Cascade Delete</b>: Eliminación limpia sin registros huérfanos</div>
          <div class="tag">DELETE .../subgrupos/{id}</div>
        </div>
      </div>
      <div class="footer-note">
        💡 <b>Especialización Técnica:</b> Permite a los equipos dividirse en ramas de trabajo (Frontend, Backend, Ciberseguridad, Redes) manteniendo sincronía con el nodo principal.
      </div>
    </div>
    `
  },
  {
    name: 'diag_09_reuniones.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK WORKSPACES</div>
        <div class="title">Flujo 8: Programación y Agenda de Reuniones de Nodo</div>
        <div class="subtitle">Planificación de Sesiones Síncronas, Integración de Videollamadas y Estado Dinámico</div>
      </div>
      <div class="flow-container">
        <div class="step-card">
          <div class="step-badge">1. AGENDAR</div>
          <h4>Formulario de Sesión</h4>
          <p>Título, descripción, fecha/hora, selector de duración (15-90 min) y enlace de Google Meet.</p>
          <div class="tag">POST /nodos/{id}/reuniones</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card highlight">
          <div class="step-badge">2. PERSISTENCIA</div>
          <h4>Registro en Base de Datos</h4>
          <p>Validación de timestamps UTC, guardado en tabla <code>reuniones</code> e indexación temporal.</p>
          <div class="tag tag-accent">PostgreSQL 18 tabla reuniones</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">3. CALENDARIO</div>
          <h4>Visualización en Workspace</h4>
          <p>Cálculo de estado dinámico (● Programada / Finalizada) y desglose de fecha con día y mes.</p>
          <div class="tag">GET /nodos/{id}/reuniones</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">4. ACCESO DIRECTO</div>
          <h4>Unirse a la Sesión</h4>
          <p>Botón interactivo de un solo clic para conexión inmediata a la videollamada.</p>
          <div class="tag">Enlace Directo Meet</div>
        </div>
      </div>
      <div class="footer-note">
        📅 <b>Sincronización de Equipos:</b> Facilita dailies, revisiones de sprint y sesiones de pair programming con notificación clara de estado para todos los miembros del nodo.
      </div>
    </div>
    `
  },
  {
    name: 'diag_10_sprint2_overview.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK ROADMAP</div>
        <div class="title">Matriz Integral de Funcionalidades — Sprint 1 & Sprint 2</div>
        <div class="subtitle">Plataforma Enterprise de Comunicación Cifrada, Nodos Colaborativos y Rendimiento Asíncrono</div>
      </div>
      <div class="grid-2">
        <div class="card client">
          <div class="badge">SPRINT 1 (FINALIZADO 100%)</div>
          <h3>Seguridad, Identidad & Nodos</h3>
          <div class="item">🛡️ <b>IRL-IAM-US-01</b>: Registro con hashing Argon2id y validaciones</div>
          <div class="item">📧 <b>IRL-IAM-US-02</b>: Verificación por OTP (6 dígitos) y Magic Link</div>
          <div class="item">🔑 <b>IRL-IAM-US-04</b>: Autenticación JWT y Refresh Tokens (15 min / 7 d)</div>
          <div class="item">👑 <b>IRL-IAM-US-06</b>: Control de acceso RBAC (Admin, Mod, Member)</div>
          <div class="item">🌐 <b>IRL-WKS-US-01</b>: Gestión de Nodos, Tokens y Moderación (Kick/Ban)</div>
        </div>
        <div class="card backend">
          <div class="badge badge-accent">SPRINT 2 (FINALIZADO 100%)</div>
          <h3>Colaboración, Espacios & Personalización</h3>
          <div class="item">💬 <b>IRL-WKS-US-03</b>: Chat persistente en canales con historial PostgreSQL</div>
          <div class="item">👥 <b>IRL-WKS-US-02</b>: Subgrupos dentro de nodos (públicos y privados)</div>
          <div class="item">📅 <b>IRL-WKS-US-04</b>: Programación de reuniones y sesiones síncronas</div>
          <div class="item">🎨 <b>IRL-IAM-US-05</b>: Perfil de usuario, presencia y paleta de avatar</div>
          <div class="item">⚡ <b>Workspace Tabs</b>: Interfaz modular con selector de pestañas</div>
        </div>
      </div>
      <div class="footer-note">
        🚀 <b>Estado del Sistema:</b> Ambos Sprints completados al 100% en backend y aplicación de escritorio nativa, certificados mediante auditoría de arquitectura y pruebas automatizadas.
      </div>
    </div>
    `
  }
];

const template = (body) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
    body { background: #050B14; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 40px; }
    .canvas {
      width: 1100px;
      background: #0B132B;
      border: 1px solid #1E293B;
      border-radius: 20px;
      padding: 36px 40px;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.7);
    }
    .header { margin-bottom: 28px; border-bottom: 1px solid #1E293B; padding-bottom: 18px; }
    .logo { color: #00E5FF; font-weight: 800; font-size: 13px; letter-spacing: 2px; margin-bottom: 6px; }
    .title { color: #F8FAFC; font-size: 24px; font-weight: 700; }
    .subtitle { color: #94A3B8; font-size: 14px; margin-top: 4px; }
    
    .grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
    .grid-2 { display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px; }
    
    .card {
      background: #0F172A;
      border: 1px solid #1E293B;
      border-radius: 14px;
      padding: 22px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .card.client { border-top: 3px solid #00E5FF; }
    .card.backend { border-top: 3px solid #00BFA5; }
    .card.db { border-top: 3px solid #8B5CF6; }
    
    .badge {
      display: inline-block;
      font-size: 10px;
      font-weight: 800;
      letter-spacing: 1px;
      color: #00E5FF;
      background: rgba(0, 229, 255, 0.1);
      padding: 4px 8px;
      border-radius: 6px;
      align-self: flex-start;
    }
    .badge-accent { color: #00BFA5; background: rgba(0, 191, 165, 0.1); }
    .badge-db { color: #8B5CF6; background: rgba(139, 92, 246, 0.1); }
    
    .card h3 { color: #F8FAFC; font-size: 16px; font-weight: 700; margin-bottom: 2px; }
    .card .item { color: #CBD5E1; font-size: 12.5px; line-height: 1.5; }
    
    .flow-container {
      display: flex;
      align-items: stretch;
      justify-content: space-between;
      gap: 10px;
      margin: 10px 0;
    }
    .step-card {
      flex: 1;
      background: #0F172A;
      border: 1px solid #1E293B;
      border-radius: 12px;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .step-card.highlight {
      border-color: #00BFA5;
      background: rgba(0, 191, 165, 0.04);
    }
    .step-badge {
      font-size: 10px;
      font-weight: 800;
      color: #00E5FF;
      background: rgba(0, 229, 255, 0.1);
      padding: 3px 6px;
      border-radius: 4px;
      align-self: flex-start;
    }
    .step-card h4 { color: #F8FAFC; font-size: 14px; font-weight: 700; }
    .step-card p { color: #94A3B8; font-size: 11.5px; line-height: 1.4; flex-grow: 1; }
    
    .flow-arrow {
      display: flex;
      align-items: center;
      justify-content: center;
      color: #00E5FF;
      font-size: 20px;
      font-weight: bold;
    }
    
    .tag {
      font-family: monospace;
      font-size: 10.5px;
      color: #00E5FF;
      background: rgba(0, 229, 255, 0.08);
      padding: 4px 8px;
      border-radius: 4px;
      border: 1px solid rgba(0, 229, 255, 0.2);
      margin-top: 4px;
    }
    .tag-accent {
      color: #00BFA5;
      background: rgba(0, 191, 165, 0.08);
      border-color: rgba(0, 191, 165, 0.2);
    }
    
    .footer-note {
      margin-top: 24px;
      padding: 14px 18px;
      background: #0F172A;
      border: 1px solid #1E293B;
      border-radius: 10px;
      color: #94A3B8;
      font-size: 12.5px;
      line-height: 1.5;
    }
    .footer-arrows {
      margin-top: 22px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .arrow-box {
      background: #0F172A;
      border: 1px solid #1E293B;
      border-radius: 8px;
      padding: 10px 14px;
      color: #CBD5E1;
      font-size: 12px;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .arrow-box span { color: #00E5FF; font-size: 16px; font-weight: bold; }
  </style>
</head>
<body>
  ${body}
</body>
</html>
`;

async function renderDiagrams() {
  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: 1200, height: 750 },
    deviceScaleFactor: 2
  });

  for (const diag of diagrams) {
    console.log(`Renderizando diagrama de escritorio: ${diag.name}...`);
    await page.setContent(template(diag.html), { waitUntil: 'networkidle' });
    const canvas = page.locator('.canvas');
    await canvas.screenshot({ path: path.join(outputDir, diag.name) });
  }

  await browser.close();
  console.log('✅ Todos los 10 diagramas de arquitectura de escritorio generados con éxito.');
}

renderDiagrams();
