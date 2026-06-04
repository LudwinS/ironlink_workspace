-- Migración Sprint 1: Tablas y columnas adicionales para IronLink (Auto-inicialización completa)

-- 1. Crear tipos enumerados de forma segura si no existen
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estados') THEN
        CREATE TYPE estados AS ENUM('PENDING', 'ACTIVE', 'SUSPENDED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'roles') THEN
        CREATE TYPE roles AS ENUM('ADMIN', 'MODERATOR', 'MEMBER');
    END IF;
END$$;

-- 2. Crear tabla de usuarios de forma segura si no existe
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    telefono TEXT NOT NULL UNIQUE,
    rol roles NOT NULL DEFAULT 'MEMBER',
    estado estados NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Crear función y disparador de actualización para users de forma segura
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_set_updated_at') THEN
        CREATE TRIGGER trigger_set_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at();
    END IF;
END$$;

-- 4. Agregar columnas adicionales para seguridad a la tabla users
ALTER TABLE users ADD COLUMN IF NOT EXISTS intentos_fallidos INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bloqueado_hasta TIMESTAMPTZ;

-- 5. Tabla de tokens de verificación (OTP y links)
CREATE TABLE IF NOT EXISTS verification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    token VARCHAR(64),  -- Para verificación por enlace
    method VARCHAR(10) NOT NULL DEFAULT 'code', -- 'code' o 'link'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);

-- 6. Tabla de refresh tokens para sesiones JWT
CREATE TABLE IF NOT EXISTS refresh_tokens (
    token UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Tabla de nodos (espacios de trabajo/aulas virtuales)
CREATE TABLE IF NOT EXISTS nodos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    token_acceso VARCHAR(32) NOT NULL UNIQUE,
    creador_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    estado VARCHAR(10) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Tabla de miembros de nodos
CREATE TABLE IF NOT EXISTS nodo_miembros (
    nodo_id UUID REFERENCES nodos(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rol VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (nodo_id, user_id)
);

-- 9. Índices para optimizar consultas del Sprint 1
CREATE INDEX IF NOT EXISTS idx_verification_tokens_user_id ON verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_tokens_token ON verification_tokens(token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_nodo_miembros_user_id ON nodo_miembros(user_id);
