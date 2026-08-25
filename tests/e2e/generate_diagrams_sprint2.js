const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const outputDir = '/Users/ludwin/Developer/ironlink_workspace/tests/e2e/diagrams';
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const diagrams = [
  {
    name: 'diag_07_profile.png',
    html: `
    <div class="canvas">
      <div class="header">
        <div class="logo">⚡ IRONLINK IAM</div>
        <div class="title">Flujo 6 — Perfil de Usuario y Personalización (IRL-IAM-US-05)</div>
        <div class="subtitle">Gestión de Identidad, Presencia, Paleta de Color de Avatar y Seguridad Criptográfica</div>
      </div>
      <div class="flow-container">
        <div class="step-card">
          <div class="step-badge">PASO 1</div>
          <h4>Apertura del Perfil</h4>
          <p>El usuario pulsa su avatar o nombre en la barra superior / sidebar.</p>
          <div class="tag">GET /users/me</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card highlight">
          <div class="step-badge">PASO 2</div>
          <h4>Personalización Visual</h4>
          <p>Selección de color de avatar (8 tonos), estado de presencia ('En línea', 'Ocupado') y biografía.</p>
          <div class="tag tag-accent">StateNotifier (Riverpod)</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">PASO 3</div>
          <h4>Seguridad de Contraseña</h4>
          <p>Verificación de clave actual con Argon2id y validación de entropía para nueva clave.</p>
          <div class="tag">PUT /users/me/password</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card">
          <div class="step-badge">PASO 4</div>
          <h4>Persistencia & Reactividad</h4>
          <p>Actualización en PostgreSQL <code>users</code> y propagación instantánea a la interfaz.</p>
          <div class="tag">PUT /users/me ➔ 200 OK</div>
        </div>
      </div>
      <div class="footer-note">
        🔒 <b>Seguridad y Datos:</b> El correo electrónico es inmutable tras la verificación. Las contraseñas se almacenan con salt criptográfico aleatorio y función de costo Argon2id.
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
        <div class="title">Flujo 7 — Creación y Gestión de Subgrupos (IRL-WKS-US-02)</div>
        <div class="subtitle">Estructuración de Equipos Temáticos, Control de Privacidad y Membresías</div>
      </div>
      <div class="grid-3">
        <div class="card client">
          <div class="badge">1. CREACIÓN DE SUBGRUPO</div>
          <h3>Configuración del Espacio</h3>
          <div class="item">📝 <b>Nombre & Descripción</b>: Definición de temática</div>
          <div class="item">🔒 <b>Privacidad</b>: Flag <code>es_privado</code> (Público / Privado)</div>
          <div class="item">👑 <b>Auto-Asignación</b>: Creador ingresa automáticamente</div>
          <div class="tag">POST /nodos/{id}/subgrupos</div>
        </div>
        <div class="card backend">
          <div class="badge badge-accent">2. CONTROL DE ACCESO (RBAC)</div>
          <h3>Validación en Backend</h3>
          <div class="item">🛡️ <b>Membresía de Nodo</b>: Solo miembros del nodo acceden</div>
          <div class="item">👥 <b>Gestión de Miembros</b>: Inserción en <code>subgrupo_miembros</code></div>
          <div class="item">🚪 <b>Unirse / Salir</b>: Toggle de participación autónoma</div>
          <div class="tag tag-accent">POST /nodos/{id}/subgrupos/{sub_id}/join</div>
        </div>
        <div class="card db">
          <div class="badge badge-db">3. PERSISTENCIA & CANALES</div>
          <h3>Tablas Relacionales</h3>
          <div class="item">🗄️ <b>subgrupos</b>: Metadatos y propietario</div>
          <div class="item">🔗 <b>subgrupo_miembros</b>: Relación N:M usuario-subgrupo</div>
          <div class="item">🗑️ <b>Cascade Delete</b>: Eliminación limpia al borrar nodo</div>
          <div class="tag">DELETE /nodos/{id}/subgrupos/{sub_id}</div>
        </div>
      </div>
      <div class="footer-note">
        💡 <b>Colaboración Eficiente:</b> Permite a los equipos de desarrollo, estudiantes o departamentos dividirse en células de trabajo sin perder el contexto del nodo principal.
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
        <div class="title">Flujo 8 — Programación de Reuniones de Nodo (IRL-WKS-US-04)</div>
        <div class="subtitle">Agenda de Sesiones Síncronas, Integración de Videollamadas y Notificaciones</div>
      </div>
      <div class="flow-container">
        <div class="step-card">
          <div class="step-badge">1. AGENDAR</div>
          <h4>Formulario de Sesión</h4>
          <p>Título, descripción, fecha/hora, selector de duración (15-90 min) y link de Meet/Zoom.</p>
          <div class="tag">POST /nodos/{id}/reuniones</div>
        </div>
        <div class="flow-arrow">➔</div>
        <div class="step-card highlight">
          <div class="step-badge">2. PERSISTENCIA</div>
          <h4>Registro en Base de Datos</h4>
          <p>Validación de timestamps UTC, guardado en tabla <code>reuniones</code> e indexación por fecha.</p>
          <div class="tag tag-accent">PostgreSQL 18</div>
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
          <p>Botón interactivo "Unirse a Meet" para acceso inmediato a la sala virtual.</p>
          <div class="tag">Direct Video Link</div>
        </div>
      </div>
      <div class="footer-note">
        📅 <b>Sincronización Total:</b> Los creadores o administradores de nodo pueden reprogramar o cancelar las reuniones en cualquier momento con confirmación modal.
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
        <div class="subtitle">Plataforma Completa de Comunicación Cifrada, Gestión de Nodos y Colaboración</div>
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
          <div class="item">👥 <b>IRL-WKS-US-02</b>: Subgrupos dentro de nodos (públicos/privados)</div>
          <div class="item">📅 <b>IRL-WKS-US-04</b>: Programación de reuniones y sesiones síncronas</div>
          <div class="item">🎨 <b>IRL-IAM-US-05</b>: Perfil de usuario, presencia y paleta de avatar</div>
          <div class="item">⚡ <b>Workspace Tabs</b>: Interfaz modular con selector dinámico</div>
        </div>
      </div>
      <div class="footer-note">
        🚀 <b>Estado del Proyecto:</b> Ambos Sprints han sido completados en backend y frontend, verificados mediante pruebas automatizadas end-to-end sobre Flutter Web.
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
    console.log(`Renderizando ${diag.name}...`);
    await page.setContent(template(diag.html), { waitUntil: 'networkidle' });
    const canvas = page.locator('.canvas');
    await canvas.screenshot({ path: path.join(outputDir, diag.name) });
  }

  await browser.close();
  console.log('✅ Todos los diagramas de Sprint 2 generados en alta resolución.');
}

renderDiagrams();
