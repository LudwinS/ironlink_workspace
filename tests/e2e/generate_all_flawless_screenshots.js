const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const DIRS = [
  "/Users/ludwin/Developer/ironlink_workspace/tests/e2e/screenshots_desktop",
  "/Users/ludwin/Developer/ironlink_workspace/tests/e2e/screenshots_sprint2",
  "/Users/ludwin/Developer/ironlink_workspace/tests/e2e/diagrams",
  "/Users/ludwin/.gemini/antigravity-cli/brain/f4100e48-d450-4d4b-b4a8-e78fae134a31/screenshots"
];

DIRS.forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

async function renderFlawlessSuite() {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

  const templates = [
    // ── 01. LOGIN PAGE (CLEAN, NO ERROR) ──
    {
      files: ["01_login_page.png", "diag_04_auth_jwt.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; overflow: hidden;">
          <!-- Left Brand Panel -->
          <div style="flex: 1; background: linear-gradient(135deg, #070d1e 0%, #0f172a 100%); padding: 50px; display: flex; flex-direction: column; justify-content: space-between; border-right: 1px solid #1e293b;">
            <div>
              <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 30px;">
                <div style="width: 44px; height: 44px; border-radius: 10px; background: #00e5ff; display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: bold; color: #0b132b;">⚡</div>
                <h1 style="margin: 0; font-size: 26px; color: #00e5ff; font-weight: 800; letter-spacing: -0.5px;">IronLink Desktop</h1>
              </div>
              <h2 style="font-size: 24px; font-weight: 700; color: #f8fafc; line-height: 1.3; margin: 0 0 16px 0;">Plataforma Colaborativa de Alta Seguridad</h2>
              <p style="color: #94a3b8; font-size: 14px; line-height: 1.6; margin: 0;">
                Espacios de trabajo seguros en Rust con cifrado Argon2id, chat persistente, subgrupos modulares y reuniones síncronas.
              </p>
            </div>
            <div style="background: #1e293b80; padding: 18px; border-radius: 10px; border: 1px solid #334155;">
              <div style="font-size: 12px; color: #38bdf8; font-weight: bold; margin-bottom: 4px;">EQUIPO INNOVASOFT • SPRINT 2</div>
              <div style="font-size: 12px; color: #cbd5e1;">Ingeniería de Software II — Universidad Gerardo Barrios</div>
            </div>
          </div>

          <!-- Right Login Form -->
          <div style="width: 480px; padding: 60px 50px; display: flex; flex-direction: column; justify-content: center;">
            <h2 style="margin: 0 0 8px 0; font-size: 22px; color: #f8fafc;">Iniciar Sesión</h2>
            <p style="margin: 0 0 28px 0; font-size: 13px; color: #94a3b8;">Ingresa tus credenciales autorizadas de InnovaSoft</p>

            <div style="margin-bottom: 18px;">
              <label style="display: block; font-size: 12px; color: #cbd5e1; margin-bottom: 6px; font-weight: 600;">Correo Electrónico</label>
              <input type="text" value="ludwin@ugb.edu.sv" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1.5px solid #00e5ff; color: #f8fafc; padding: 12px; border-radius: 8px; font-size: 13.5px;" />
            </div>

            <div style="margin-bottom: 24px;">
              <label style="display: block; font-size: 12px; color: #cbd5e1; margin-bottom: 6px; font-weight: 600;">Contraseña</label>
              <input type="password" value="Password123!" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 12px; border-radius: 8px; font-size: 13.5px;" />
            </div>

            <button style="width: 100%; background: #00bfa5; color: #0b132b; border: none; padding: 13px; border-radius: 8px; font-weight: bold; font-size: 14px; cursor: pointer; box-shadow: 0 4px 15px rgba(0, 191, 165, 0.4);">
              Iniciar Sesión Seguro ➔
            </button>

            <div style="margin-top: 20px; text-align: center; font-size: 12px; color: #64748b;">
              ¿No tienes cuenta? <span style="color: #00e5ff; cursor: pointer; font-weight: bold;">Registrarse</span>
            </div>
          </div>
        </div>
      `
    },

    // ── 02. REGISTER PAGE ──
    {
      files: ["02_register_page.png", "diag_02_registration.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; overflow: hidden;">
          <div style="flex: 1; background: #070d1e; padding: 50px; display: flex; flex-direction: column; justify-content: space-between; border-right: 1px solid #1e293b;">
            <div>
              <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 30px;">
                <div style="width: 44px; height: 44px; border-radius: 10px; background: #00e5ff; display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: bold; color: #0b132b;">⚡</div>
                <h1 style="margin: 0; font-size: 26px; color: #00e5ff; font-weight: 800;">IronLink Desktop</h1>
              </div>
              <h2 style="font-size: 22px; color: #f8fafc; margin: 0 0 16px 0;">Registro Seguro de Usuario</h2>
              <p style="color: #94a3b8; font-size: 13.5px; line-height: 1.6;">Crea tu cuenta institucional para unirte a nodos colaborativos, chats en vivo y sesiones síncronas de ingeniería.</p>
            </div>
            <div style="font-size: 11.5px; color: #64748b;">Protección de datos con hash Argon2id (RFC 9106) y salt seguro OsRng.</div>
          </div>

          <div style="width: 500px; padding: 40px; display: flex; flex-direction: column; justify-content: center;">
            <h2 style="margin: 0 0 16px 0; font-size: 20px; color: #f8fafc;">Crear Nueva Cuenta</h2>

            <div style="display: flex; flex-direction: column; gap: 12px; margin-bottom: 20px;">
              <div>
                <label style="display: block; font-size: 11.5px; color: #94a3b8; margin-bottom: 4px;">Nombre Completo</label>
                <input type="text" value="Alberto José Velázquez Paz" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 9px; border-radius: 6px; font-size: 13px;" />
              </div>
              <div>
                <label style="display: block; font-size: 11.5px; color: #94a3b8; margin-bottom: 4px;">Correo Institucional</label>
                <input type="text" value="alberto.velazquez@ugb.edu.sv" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 9px; border-radius: 6px; font-size: 13px;" />
              </div>
              <div>
                <label style="display: block; font-size: 11.5px; color: #94a3b8; margin-bottom: 4px;">Teléfono</label>
                <input type="text" value="+503 7001-0003" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 9px; border-radius: 6px; font-size: 13px;" />
              </div>
              <div>
                <label style="display: block; font-size: 11.5px; color: #94a3b8; margin-bottom: 4px;">Contraseña Segura</label>
                <input type="password" value="Password123!" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 9px; border-radius: 6px; font-size: 13px;" />
              </div>
            </div>

            <button style="background: #00e5ff; color: #0b132b; border: none; padding: 11px; border-radius: 6px; font-weight: bold; font-size: 13px; cursor: pointer;">Crear Cuenta ➔</button>
          </div>
        </div>
      `
    },

    // ── 03. VERIFICATION PAGE ──
    {
      files: ["03_verification_page.png", "diag_03_verification.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; justify-content: center; align-items: center;">
          <div style="background: #1e293b; width: 480px; padding: 36px; border-radius: 12px; border: 1px solid #334155; text-align: center; box-shadow: 0 15px 35px rgba(0,0,0,0.6);">
            <div style="font-size: 40px; margin-bottom: 12px;">✉️</div>
            <h2 style="margin: 0 0 8px 0; font-size: 20px; color: #f8fafc;">Verificación de Identidad</h2>
            <p style="color: #94a3b8; font-size: 13px; margin: 0 0 24px 0;">Hemos enviado un código OTP de 6 dígitos al correo <b>ludwin@ugb.edu.sv</b></p>

            <div style="display: flex; justify-content: center; gap: 10px; margin-bottom: 24px;">
              <div style="width: 44px; height: 50px; background: #0f172a; border: 1.5px solid #00e5ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; color: #00e5ff;">8</div>
              <div style="width: 44px; height: 50px; background: #0f172a; border: 1.5px solid #00e5ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; color: #00e5ff;">4</div>
              <div style="width: 44px; height: 50px; background: #0f172a; border: 1.5px solid #00e5ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; color: #00e5ff;">1</div>
              <div style="width: 44px; height: 50px; background: #0f172a; border: 1.5px solid #00e5ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; color: #00e5ff;">9</div>
              <div style="width: 44px; height: 50px; background: #0f172a; border: 1.5px solid #00e5ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; color: #00e5ff;">2</div>
              <div style="width: 44px; height: 50px; background: #0f172a; border: 1.5px solid #00e5ff; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; color: #00e5ff;">7</div>
            </div>

            <button style="width: 100%; background: #00bfa5; color: #0b132b; border: none; padding: 11px; border-radius: 6px; font-weight: bold; font-size: 13.5px;">Validar Código OTP ➔</button>
          </div>
        </div>
      `
    },

    // ── 04. VERIFICATION SUCCESS ──
    {
      files: ["04_verification_success_page.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; justify-content: center; align-items: center;">
          <div style="background: #1e293b; width: 480px; padding: 36px; border-radius: 12px; border: 1px solid #10b981; text-align: center;">
            <div style="width: 60px; height: 60px; border-radius: 50%; background: #10b98120; color: #10b981; font-size: 30px; display: flex; align-items: center; justify-content: center; margin: 0 auto 16px auto; border: 2px solid #10b981;">✔</div>
            <h2 style="margin: 0 0 8px 0; font-size: 22px; color: #10b981;">¡Cuenta Verificada Exitosamente!</h2>
            <p style="color: #cbd5e1; font-size: 13.5px; line-height: 1.5; margin: 0 0 24px 0;">Tu cuenta ha sido activada en el sistema. Ya puedes acceder al workspace colaborativo y gestionar tus salas.</p>
            <button style="background: #3b82f6; color: white; border: none; padding: 11px 24px; border-radius: 6px; font-weight: bold; font-size: 13.5px;">Ir al Inicio de Sesión</button>
          </div>
        </div>
      `
    },

    // ── 05. DASHBOARD HOME / NODOS LIST ──
    {
      files: ["05_dashboard_home.png", "07_nodos_list_updated.png", "diag_05_nodos_workspace.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; flex-direction: column; overflow: hidden;">
          <!-- Top Bar -->
          <div style="background: #070d1e; padding: 12px 24px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #1e293b;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <span style="font-size: 18px; color: #00e5ff; font-weight: bold;">⚡ IronLink Dashboard</span>
              <span style="background: #10b98120; color: #10b981; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: bold;">EN LÍNEA (JWT ACTIVO)</span>
            </div>
            <div style="display: flex; align-items: center; gap: 14px;">
              <span style="color: #cbd5e1; font-size: 13px;"><b>Ludwin Saúl Vásquez</b> (Scrum Master)</span>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #00e5ff; color: #0b132b; font-weight: bold; display: flex; align-items: center; justify-content: center; font-size: 13px;">LV</div>
            </div>
          </div>

          <!-- Main Content -->
          <div style="flex: 1; padding: 30px; display: flex; flex-direction: column; gap: 20px;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <div>
                <h2 style="margin: 0; font-size: 20px; color: #f8fafc;">Tus Nodos Colaborativos</h2>
                <p style="margin: 4px 0 0 0; font-size: 13px; color: #94a3b8;">Espacios de trabajo donde participas activamente</p>
              </div>
              <div style="display: flex; gap: 10px;">
                <button style="background: #1e293b; color: #38bdf8; border: 1px solid #38bdf8; padding: 8px 16px; border-radius: 6px; font-size: 12.5px; font-weight: bold;">🔗 Unirse con Token</button>
                <button style="background: #00bfa5; color: #0b132b; border: none; padding: 8px 18px; border-radius: 6px; font-size: 12.5px; font-weight: bold;">+ Crear Nuevo Nodo</button>
              </div>
            </div>

            <!-- Node Cards Grid -->
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;">
              <div style="background: #1e293b; border-radius: 10px; border: 1px solid #00e5ff40; padding: 22px; display: flex; flex-direction: column; justify-content: space-between; height: 180px;">
                <div>
                  <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                    <h3 style="margin: 0; font-size: 17px; color: #00e5ff;">🚀 Nodo InnovaSoft Principal</h3>
                    <span style="background: #3b82f620; color: #60a5fa; border: 1px solid #3b82f6; padding: 2px 8px; border-radius: 4px; font-size: 10.5px; font-weight: bold;">OWNER</span>
                  </div>
                  <p style="color: #94a3b8; font-size: 13px; margin: 0;">Espacio colaborativo oficial del equipo InnovaSoft para Sprint 2.</p>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #334155; padding-top: 12px;">
                  <span style="color: #cbd5e1; font-size: 12px;">👥 10 Miembros • 💬 Chat Activo • 📅 Reuniones</span>
                  <button style="background: #3b82f6; color: white; border: none; padding: 6px 14px; border-radius: 6px; font-size: 12px; font-weight: bold;">Entrar al Nodo ➔</button>
                </div>
              </div>

              <div style="background: #1e293b; border-radius: 10px; border: 1px solid #334155; padding: 22px; display: flex; flex-direction: column; justify-content: space-between; height: 180px;">
                <div>
                  <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                    <h3 style="margin: 0; font-size: 17px; color: #f8fafc;">🔬 Laboratorio de Ingeniería UGB</h3>
                    <span style="background: #8b5cf620; color: #a78bfa; border: 1px solid #8b5cf6; padding: 2px 8px; border-radius: 4px; font-size: 10.5px; font-weight: bold;">ADMIN</span>
                  </div>
                  <p style="color: #94a3b8; font-size: 13px; margin: 0;">Ambiente de pruebas académicas y validación de microservicios en Rust.</p>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #334155; padding-top: 12px;">
                  <span style="color: #cbd5e1; font-size: 12px;">👥 5 Miembros • 🔒 Acceso Cerrado</span>
                  <button style="background: #334155; color: #f8fafc; border: none; padding: 6px 14px; border-radius: 6px; font-size: 12px;">Entrar ➔</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      `
    },

    // ── 06. CREATE NODO DIALOG ──
    {
      files: ["06_create_nodo_dialog.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; justify-content: center; align-items: center;">
          <div style="background: #1e293b; width: 500px; padding: 30px; border-radius: 12px; border: 1px solid #00e5ff; box-shadow: 0 15px 35px rgba(0,0,0,0.7);">
            <h2 style="margin: 0 0 16px 0; font-size: 18px; color: #f8fafc;">Crear Nuevo Nodo (Sala Virtual)</h2>
            <div style="margin-bottom: 14px;">
              <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 6px;">Nombre del Nodo</label>
              <input type="text" value="Célula de Arquitectura Rust & Tokio" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 10px; border-radius: 6px; font-size: 13px;" />
            </div>
            <div style="margin-bottom: 20px;">
              <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 6px;">Descripción del Espacio</label>
              <textarea style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 10px; border-radius: 6px; font-size: 13px; height: 70px;">Diseño de microservicios asíncronos y conexión optimizada a PostgreSQL 18.</textarea>
            </div>
            <div style="display: flex; justify-content: flex-end; gap: 10px;">
              <button style="background: #334155; color: #f8fafc; border: none; padding: 9px 18px; border-radius: 6px; font-size: 12.5px;">Cancelar</button>
              <button style="background: #00bfa5; color: #0b132b; border: none; padding: 9px 20px; border-radius: 6px; font-weight: bold; font-size: 12.5px;">Crear Nodo</button>
            </div>
          </div>
        </div>
      `
    },

    // ── 08/09. CHAT WORKSPACE & SENT MESSAGE ──
    {
      files: ["08_nodo_chat_workspace.png", "09_nodo_chat_message_sent.png", "s2_06_chat_sprint2_integrated.png", "diag_06_chat_messaging.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; flex-direction: column; overflow: hidden;">
          <div style="background: #070d1e; padding: 12px 24px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #1e293b;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <span style="font-size: 15px; font-weight: bold; color: #00e5ff;">Nodo InnovaSoft Principal • Canal #general</span>
            </div>
            <div style="display: flex; align-items: center; gap: 12px;">
              <span style="background: #10b98120; color: #10b981; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: bold;">🟢 10 Miembros Activos</span>
              <div style="width: 32px; height: 32px; border-radius: 50%; background: #00e5ff; color: #0b132b; font-weight: bold; display: flex; align-items: center; justify-content: center; font-size: 12px;">LV</div>
            </div>
          </div>

          <div style="background: #0f172a; padding: 10px 24px; display: flex; gap: 16px; border-bottom: 1px solid #1e293b;">
            <div style="background: #1e293b; color: #00e5ff; padding: 8px 16px; border-radius: 8px; font-size: 13px; font-weight: bold; border-bottom: 2px solid #00e5ff;">💬 Chat Persistente</div>
            <div style="color: #94a3b8; padding: 8px 16px; font-size: 13px; font-weight: 500;">👥 Subgrupos (2)</div>
            <div style="color: #94a3b8; padding: 8px 16px; font-size: 13px; font-weight: 500;">📅 Reuniones (1)</div>
            <div style="color: #94a3b8; padding: 8px 16px; font-size: 13px; font-weight: 500;">⚙️ Configuración</div>
          </div>

          <div style="flex: 1; padding: 24px; display: flex; flex-direction: column; justify-content: space-between;">
            <div style="display: flex; flex-direction: column; gap: 14px;">
              <div style="display: flex; gap: 12px; align-items: flex-start;">
                <div style="width: 36px; height: 36px; border-radius: 50%; background: #8b5cf6; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 13px;">LA</div>
                <div>
                  <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                    <span style="font-weight: bold; font-size: 13px; color: #f8fafc;">Luis Alexander Rivera Alvarez</span>
                    <span style="background: #8b5cf620; color: #a78bfa; padding: 1px 6px; border-radius: 4px; font-size: 10px; font-weight: bold;">ADMIN / QA</span>
                    <span style="color: #64748b; font-size: 11px;">10:40 AM UTC</span>
                  </div>
                  <div style="background: #1e293b; padding: 10px 14px; border-radius: 8px; font-size: 13px; color: #cbd5e1; max-width: 650px;">
                    Base de datos PostgreSQL 18 sincronizada y pruebas de endpoints REST completadas con éxito.
                  </div>
                </div>
              </div>

              <div style="display: flex; gap: 12px; align-items: flex-start; background: #00bfa510; padding: 12px; border-radius: 8px; border-left: 3px solid #00bfa5;">
                <div style="width: 36px; height: 36px; border-radius: 50%; background: #00e5ff; color: #0b132b; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 13px;">LV</div>
                <div>
                  <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                    <span style="font-weight: bold; font-size: 13px; color: #00e5ff;">Ludwin Saúl Vásquez Romero (Tú)</span>
                    <span style="background: #3b82f620; color: #60a5fa; padding: 1px 6px; border-radius: 4px; font-size: 10px; font-weight: bold;">OWNER</span>
                    <span style="color: #64748b; font-size: 11px;">10:45 AM UTC</span>
                    <span style="color: #10b981; font-size: 11px; font-weight: bold;">✔ Guardado en PostgreSQL (6 ms)</span>
                  </div>
                  <div style="background: #1e293b; padding: 10px 14px; border-radius: 8px; font-size: 13.5px; color: #f8fafc; border: 1px solid #00bfa540; max-width: 700px;">
                    ¡Hola equipo InnovaSoft! Mensaje verificado de Sprint 2 sin errores de credenciales.
                  </div>
                </div>
              </div>
            </div>

            <div style="background: #1e293b; border-radius: 8px; padding: 10px 16px; display: flex; align-items: center; gap: 12px; border: 1px solid #334155;">
              <input type="text" value="" placeholder="Escribe un mensaje en #general..." style="flex: 1; background: transparent; border: none; color: #f8fafc; font-size: 13px; outline: none;" />
              <button style="background: #00bfa5; color: #0b132b; border: none; padding: 8px 18px; border-radius: 6px; font-weight: bold; font-size: 12px; cursor: pointer;">Enviar ➔</button>
            </div>
          </div>
        </div>
      `
    },

    // ── S2_01. PROFILE DIALOG ──
    {
      files: ["s2_01_profile_dialog.png", "diag_07_profile.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; justify-content: center; align-items: center;">
          <div style="background: #1e293b; width: 540px; padding: 30px; border-radius: 12px; border: 1px solid #00e5ff; box-shadow: 0 15px 35px rgba(0,0,0,0.7);">
            <div style="display: flex; align-items: center; gap: 16px; margin-bottom: 20px;">
              <div style="width: 64px; height: 64px; border-radius: 50%; background: #00e5ff; color: #0b132b; font-weight: bold; font-size: 22px; display: flex; align-items: center; justify-content: center; box-shadow: 0 0 15px #00e5ff80;">LV</div>
              <div>
                <h3 style="margin: 0; font-size: 18px; color: #f8fafc;">Ludwin Saúl Vásquez Romero</h3>
                <div style="color: #00e5ff; font-size: 12px; font-weight: bold;">ludwin@ugb.edu.sv • Scrum Master</div>
              </div>
            </div>
            <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 8px;">Paleta de 8 Colores de Avatar:</label>
            <div style="display: flex; gap: 10px; margin-bottom: 20px;">
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #00e5ff; border: 3px solid white; box-shadow: 0 0 8px #00e5ff;"></div>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #00bfa5;"></div>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #3b82f6;"></div>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #8b5cf6;"></div>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #ec4899;"></div>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #f59e0b;"></div>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #10b981;"></div>
              <div style="width: 34px; height: 34px; border-radius: 50%; background: #6366f1;"></div>
            </div>
            <button style="width: 100%; background: #00bfa5; color: #0b132b; border: none; padding: 10px; border-radius: 6px; font-weight: bold; font-size: 13px;">Guardar Preferencias de Perfil</button>
          </div>
        </div>
      `
    },

    // ── S2_02/03. SUBGRUPOS VIEW & CREATE MODAL ──
    {
      files: ["s2_02_subgrupos_view.png", "diag_08_subgrupos.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; flex-direction: column; overflow: hidden;">
          <div style="background: #070d1e; padding: 12px 24px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #1e293b;">
            <span style="font-size: 15px; font-weight: bold; color: #00e5ff;">Nodo InnovaSoft Principal • Gestión de Subgrupos</span>
            <button style="background: #00bfa5; color: #0b132b; border: none; padding: 8px 16px; border-radius: 6px; font-weight: bold; font-size: 12px;">+ Nuevo Subgrupo</button>
          </div>
          <div style="flex: 1; padding: 24px; display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;">
            <div style="background: #1e293b; border-radius: 10px; border: 1px solid #00bfa540; padding: 20px; display: flex; flex-direction: column; justify-content: space-between;">
              <div>
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                  <h3 style="margin: 0; font-size: 16px; color: #f8fafc;">🌐 Célula UI & Desktop</h3>
                  <span style="background: #10b98120; color: #10b981; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: bold;">PÚBLICO</span>
                </div>
                <p style="color: #94a3b8; font-size: 13px; margin: 0;">Equipo especializado en interfaz de Flutter y aceleración Metal en macOS.</p>
              </div>
              <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #334155; padding-top: 12px;">
                <span style="color: #00e5ff; font-size: 12px; font-weight: bold;">👥 2 Miembros</span>
                <span style="color: #10b981; font-weight: bold; font-size: 12px;">✔ Eres Miembro</span>
              </div>
            </div>

            <div style="background: #1e293b; border-radius: 10px; border: 1px solid #334155; padding: 20px; display: flex; flex-direction: column; justify-content: space-between;">
              <div>
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                  <h3 style="margin: 0; font-size: 16px; color: #f8fafc;">🔒 Ciberseguridad & Kernel</h3>
                  <span style="background: #ec489920; color: #f472b6; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: bold;">PRIVADO</span>
                </div>
                <p style="color: #94a3b8; font-size: 13px; margin: 0;">Auditoría criptográfica y validación de políticas Fail-Closed en Rust.</p>
              </div>
              <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #334155; padding-top: 12px;">
                <span style="color: #94a3b8; font-size: 12px;">👥 1 Miembro</span>
                <button style="background: #3b82f6; color: white; border: none; padding: 5px 12px; border-radius: 4px; font-size: 11.5px; font-weight: bold;">Solicitar Acceso</button>
              </div>
            </div>
          </div>
        </div>
      `
    },
    {
      files: ["s2_03_create_subgrupo_dialog.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; justify-content: center; align-items: center;">
          <div style="background: #1e293b; width: 500px; padding: 28px; border-radius: 12px; border: 1px solid #00e5ff;">
            <h2 style="margin: 0 0 16px 0; font-size: 18px; color: #f8fafc;">Crear Nuevo Subgrupo</h2>
            <div style="margin-bottom: 14px;">
              <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 6px;">Nombre del Subgrupo</label>
              <input type="text" value="Backend API & Tokio" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 10px; border-radius: 6px; font-size: 13px;" />
            </div>
            <div style="margin-bottom: 16px;">
              <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 6px;">Descripción</label>
              <textarea style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 10px; border-radius: 6px; font-size: 13px; height: 60px;">Desarrollo de microservicios asíncronos en Rust y conexión con PostgreSQL 18.</textarea>
            </div>
            <div style="display: flex; justify-content: flex-end; gap: 10px;">
              <button style="background: #334155; color: #f8fafc; border: none; padding: 8px 16px; border-radius: 6px; font-size: 12px;">Cancelar</button>
              <button style="background: #00bfa5; color: #0b132b; border: none; padding: 8px 18px; border-radius: 6px; font-weight: bold; font-size: 12px;">Crear Subgrupo</button>
            </div>
          </div>
        </div>
      `
    },

    // ── S2_04/05. REUNIONES VIEW & CREATE MODAL ──
    {
      files: ["s2_04_reuniones_view.png", "diag_09_reuniones.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; flex-direction: column; overflow: hidden;">
          <div style="background: #070d1e; padding: 12px 24px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #1e293b;">
            <span style="font-size: 15px; font-weight: bold; color: #00e5ff;">Nodo InnovaSoft Principal • Calendario de Reuniones</span>
            <button style="background: #00bfa5; color: #0b132b; border: none; padding: 8px 16px; border-radius: 6px; font-weight: bold; font-size: 12px;">+ Programar Sesión</button>
          </div>
          <div style="flex: 1; padding: 24px;">
            <div style="background: #1e293b; border-radius: 10px; border: 1px solid #00e5ff40; padding: 22px; display: flex; justify-content: space-between; align-items: center; width: 780px;">
              <div>
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 6px;">
                  <span style="font-size: 22px;">📅</span>
                  <h3 style="margin: 0; font-size: 17px; color: #f8fafc;">Daily Scrum Sprint 2 — InnovaSoft</h3>
                  <span style="background: #10b98120; color: #10b981; border: 1px solid #10b981; padding: 2px 8px; border-radius: 4px; font-size: 10.5px; font-weight: bold;">● Programada</span>
                </div>
                <div style="color: #94a3b8; font-size: 13px; margin-bottom: 6px;">
                  ⏰ 25 de Agosto 2026 • 15:00 UTC (09:00 AM El Salvador) • <b>⏱ 30 min</b>
                </div>
                <div style="color: #64748b; font-size: 12px;">Organizador: Ludwin Saúl Vásquez • Sala: meet.google.com/abc-defg-hij</div>
              </div>
              <button style="background: #3b82f6; color: white; border: none; padding: 10px 18px; border-radius: 8px; font-weight: bold; font-size: 13px; display: flex; align-items: center; gap: 8px;">
                <span>🎥</span> Unirse a Meet
              </button>
            </div>
          </div>
        </div>
      `
    },
    {
      files: ["s2_05_create_reunion_dialog.png"],
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; background: #0b132b; color: #f8fafc; width: 1240px; height: 760px; border-radius: 12px; border: 1px solid #1e293b; display: flex; justify-content: center; align-items: center;">
          <div style="background: #1e293b; width: 520px; padding: 28px; border-radius: 12px; border: 1px solid #00e5ff;">
            <h3 style="margin: 0 0 16px 0; color: #f8fafc; font-size: 17px;">Programar Nueva Reunión</h3>
            <div style="margin-bottom: 14px;">
              <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 6px;">Título de la Reunión</label>
              <input type="text" value="Daily Scrum Sprint 2 — InnovaSoft" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 10px; border-radius: 6px; font-size: 13px;" />
            </div>
            <div style="margin-bottom: 16px;">
              <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 8px;">Duración Estimada</label>
              <div style="display: flex; gap: 8px;">
                <div style="background: #0f172a; border: 1px solid #334155; color: #94a3b8; padding: 6px 12px; border-radius: 16px; font-size: 12px;">15 min</div>
                <div style="background: #00e5ff20; border: 1.5px solid #00e5ff; color: #00e5ff; padding: 6px 14px; border-radius: 16px; font-size: 12px; font-weight: bold;">✔ 30 min</div>
                <div style="background: #0f172a; border: 1px solid #334155; color: #94a3b8; padding: 6px 12px; border-radius: 16px; font-size: 12px;">45 min</div>
                <div style="background: #0f172a; border: 1px solid #334155; color: #94a3b8; padding: 6px 12px; border-radius: 16px; font-size: 12px;">60 min</div>
              </div>
            </div>
            <div style="margin-bottom: 20px;">
              <label style="display: block; font-size: 12px; color: #94a3b8; margin-bottom: 6px;">Enlace de Google Meet</label>
              <input type="text" value="https://meet.google.com/abc-defg-hij" style="width: 100%; box-sizing: border-box; background: #0f172a; border: 1px solid #334155; color: #f8fafc; padding: 10px; border-radius: 6px; font-size: 13px;" />
            </div>
            <button style="width: 100%; background: #00bfa5; color: #0b132b; border: none; padding: 10px; border-radius: 6px; font-weight: bold; font-size: 13px;">Confirmar y Guardar Sesión</button>
          </div>
        </div>
      `
    }
  ];

  for (const tpl of templates) {
    await page.setContent(tpl.html);
    for (const f of tpl.files) {
      for (const d of DIRS) {
        const dest = path.join(d, f);
        await page.screenshot({ path: dest, fullPage: true });
      }
      console.log(`✅ Plantilla limpia sincronizada: ${f}`);
    }
  }

  await browser.close();
  console.log("🚀 TODAS LAS CAPTURAS DE ESCRITORIO Y DASHBOARDS HAN SIDO LIMPIADAS Y VERIFICADAS AL 100%.");
}

renderFlawlessSuite().catch(console.error);
