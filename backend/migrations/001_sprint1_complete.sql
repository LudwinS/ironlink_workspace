-- Migración Sprint 1: Tablas y columnas adicionales para IronLink
-- Ejecutar manualmente contra la base de datos PostgreSQL

-- Agregar columnas a la tabla users para control de intentos de login
ALTER TABLE users ADD COLUMN IF NOT EXISTS intentos_fallidos INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bloqueado_hasta TIMESTAMPTZ;

-- Tabla de tokens de verificación (OTP y links)
CREATE TABLE IF NOT EXISTS verification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    token VARCHAR(64),  -- Para verificación por enlace
    method VARCHAR(10) NOT NULL DEFAULT 'code', -- 'code' o 'link'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);

-- Tabla de refresh tokens para sesiones JWT
CREATE TABLE IF NOT EXISTS refresh_tokens (
    token UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de nodos (espacios de trabajo/aulas virtuales)
CREATE TABLE IF NOT EXISTS nodos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    token_acceso VARCHAR(32) NOT NULL UNIQUE,
    creador_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    estado VARCHAR(10) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de miembros de nodos
CREATE TABLE IF NOT EXISTS nodo_miembros (
    nodo_id UUID REFERENCES nodos(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rol VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (nodo_id, user_id)
);
