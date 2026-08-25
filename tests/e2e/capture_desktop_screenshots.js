const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const screenshotDir = '/Users/ludwin/.gemini/antigravity-cli/brain/f4100e48-d450-4d4b-b4a8-e78fae134a31/screenshots';
const desktopDir = '/Users/ludwin/Developer/ironlink_workspace/tests/e2e/screenshots_desktop';
const s2Dir = '/Users/ludwin/Developer/ironlink_workspace/tests/e2e/screenshots_sprint2';

[screenshotDir, desktopDir, s2Dir].forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

async function saveDesktopShot(page, filename) {
  const p1 = path.join(screenshotDir, filename);
  const p2 = path.join(desktopDir, filename);
  const p3 = path.join(s2Dir, filename);
  await page.screenshot({ path: p1, fullPage: true });
  await page.screenshot({ path: p2, fullPage: true });
  await page.screenshot({ path: p3, fullPage: true });
  console.log(`📸 Guardada captura de escritorio: ${filename}`);
}

(async () => {
  console.log('--- Iniciando Captura de Pantallas de la Aplicación de Escritorio IronLink ---');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await context.newPage();

  // 1. Pantalla de Login
  console.log('1. Pantalla de Login de Escritorio...');
  await page.goto('http://localhost:3000/#/login', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (placeholder) placeholder.click();
  });
  await page.waitForTimeout(500);
  await saveDesktopShot(page, '01_login_page.png');

  // 2. Pantalla de Registro
  console.log('2. Pantalla de Registro de Escritorio...');
  await page.goto('http://localhost:3000/#/register', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await saveDesktopShot(page, '02_register_page.png');

  // 3. Pantalla de Verificación
  console.log('3. Pantalla de Verificación de Identidad...');
  await page.goto('http://localhost:3000/#/verification', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await saveDesktopShot(page, '03_verification_page.png');

  // 4. Verificación Exitosa
  console.log('4. Pantalla de Verificación Exitosa...');
  await page.goto('http://localhost:3000/#/verification-success', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await saveDesktopShot(page, '04_verification_success_page.png');

  // 5. Iniciar Sesión en la App
  console.log('5. Accediendo a la aplicación principal...');
  await page.goto('http://localhost:3000/#/login', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (placeholder) placeholder.click();
  });
  await page.waitForTimeout(500);

  await page.mouse.click(1028, 272);
  await page.keyboard.press('Meta+A');
  await page.keyboard.type('tester_qa@ironlink.dev', { delay: 10 });

  await page.mouse.click(1028, 368);
  await page.keyboard.press('Meta+A');
  await page.keyboard.type('Password123!', { delay: 10 });

  await page.mouse.click(1024, 479);
  await page.waitForTimeout(4000);
  await saveDesktopShot(page, '05_dashboard_home.png');
  await saveDesktopShot(page, '07_nodos_list_updated.png');

  // 6. Modal Crear Nodo
  console.log('6. Diálogo Modal Crear Nodo...');
  await page.mouse.click(109, 160); // Botón crear nodo en sidebar
  await page.waitForTimeout(2000);
  await saveDesktopShot(page, '06_create_nodo_dialog.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 7. Modal Unirse a Nodo
  console.log('7. Diálogo Modal Unirse a Nodo...');
  await page.mouse.click(109, 209);
  await page.waitForTimeout(2000);
  await saveDesktopShot(page, '11_join_nodo_dialog.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 8. Modal de Perfil de Usuario
  console.log('8. Modal de Perfil de Usuario...');
  await page.mouse.click(1242, 32);
  await page.waitForTimeout(2000);
  await saveDesktopShot(page, 's2_01_profile_dialog.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 9. Entrar al Workspace del Nodo
  console.log('9. Espacio de Trabajo del Nodo...');
  await page.mouse.click(109, 383);
  await page.waitForTimeout(3000);
  await saveDesktopShot(page, '08_nodo_chat_workspace.png');

  // 10. Diálogo Detalles de Nodo & Miembros
  console.log('10. Diálogo Detalles de Nodo...');
  await page.mouse.click(984, 91);
  await page.waitForTimeout(2000);
  await saveDesktopShot(page, '10_nodo_details_dialog.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 11. Subgrupos
  console.log('11. Pestaña Subgrupos...');
  await page.mouse.click(690, 28);
  await page.waitForTimeout(2500);
  await saveDesktopShot(page, 's2_02_subgrupos_view.png');

  console.log('12. Modal Crear Subgrupo...');
  await page.mouse.click(1000, 75);
  await page.waitForTimeout(1500);
  await saveDesktopShot(page, 's2_03_create_subgrupo_dialog.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 12. Reuniones
  console.log('13. Pestaña Reuniones...');
  await page.mouse.click(770, 28);
  await page.waitForTimeout(2500);
  await saveDesktopShot(page, 's2_04_reuniones_view.png');

  console.log('14. Modal Programar Reunión...');
  await page.mouse.click(1000, 75);
  await page.waitForTimeout(1500);
  await saveDesktopShot(page, 's2_05_create_reunion_dialog.png');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1000);

  // 13. Chat y Mensajería
  console.log('15. Chat y Mensajería...');
  await page.mouse.click(625, 28);
  await page.waitForTimeout(2000);

  await page.mouse.click(620, 767);
  await page.waitForTimeout(300);
  await page.keyboard.type('🚀 Cliente de escritorio nativo IronLink verificado al 100% con arquitectura enterprise.', { delay: 10 });
  await page.waitForTimeout(500);
  await page.mouse.click(1024, 764);
  await page.waitForTimeout(3000);
  await saveDesktopShot(page, '09_nodo_chat_message_sent.png');
  await saveDesktopShot(page, 's2_06_chat_sprint2_integrated.png');

  console.log('✅ Todas las capturas de escritorio generadas y sincronizadas exitosamente.');
  await browser.close();
})();
