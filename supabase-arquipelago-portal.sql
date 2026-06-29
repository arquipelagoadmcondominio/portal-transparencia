-- =========================================================
-- SUPABASE - PORTAL TRANSPARÊNCIA ARQUIPÉLAGO
-- Administração de Condomínios
-- Execute este arquivo no SQL Editor do Supabase do projeto novo.
-- Script não destrutivo: usa CREATE TABLE IF NOT EXISTS.
-- =========================================================

create extension if not exists pgcrypto;

-- =========================
-- CONDOMÍNIOS
-- =========================
create table if not exists public.condominios (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cnpj text,
  endereco text,
  cidade text default 'Manaus',
  estado text default 'AM',
  sindico_nome text,
  sindico_telefone text,
  sindico_email text,
  status text not null default 'ativo' check (status in ('ativo','inativo')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- USUÁRIOS / LOGINS DO PORTAL
-- perfis: admin, morador, portaria
-- senha_hash pode receber a senha gerada pelo seu app ou hash.
-- =========================
create table if not exists public.logins (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  email text unique,
  cpf text,
  telefone text,
  perfil text not null check (perfil in ('admin','morador','portaria')),
  senha_hash text not null,
  condominio_id uuid references public.condominios(id) on delete set null,
  ativo boolean not null default true,
  ultimo_acesso timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- MORADORES
-- =========================
create table if not exists public.moradores (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid not null references public.condominios(id) on delete cascade,
  login_id uuid references public.logins(id) on delete set null,
  nome text not null,
  cpf text,
  email text,
  telefone text,
  bloco text,
  unidade text,
  tipo text default 'proprietario' check (tipo in ('proprietario','inquilino','dependente','outro')),
  status text not null default 'ativo' check (status in ('ativo','inativo')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- PORTEIROS / PORTARIA
-- =========================
create table if not exists public.porteiros (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid not null references public.condominios(id) on delete cascade,
  login_id uuid references public.logins(id) on delete set null,
  nome text not null,
  cpf text,
  telefone text,
  turno text,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- LANÇAMENTOS FINANCEIROS
-- tipo: receita ou despesa
-- status: pago, pendente, vencido, cancelado
-- =========================
create table if not exists public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid not null references public.condominios(id) on delete cascade,
  morador_id uuid references public.moradores(id) on delete set null,
  tipo text not null check (tipo in ('receita','despesa')),
  categoria text not null,
  descricao text not null,
  competencia date,
  vencimento date,
  data_pagamento date,
  valor numeric(12,2) not null default 0,
  status text not null default 'pendente' check (status in ('pago','pendente','vencido','cancelado')),
  observacoes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- ANEXOS / DOCUMENTOS
-- Use a coluna arquivo_url para salvar URL do Storage/Supabase.
-- =========================
create table if not exists public.anexos (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  lancamento_id uuid references public.lancamentos(id) on delete cascade,
  ocorrencia_id uuid,
  titulo text not null,
  descricao text,
  arquivo_url text not null,
  arquivo_nome text,
  arquivo_tipo text,
  categoria text default 'documento',
  visivel_morador boolean not null default true,
  created_at timestamptz not null default now()
);

-- =========================
-- MENSAGENS MORADOR ↔ ADMIN
-- =========================
create table if not exists public.mensagens (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  remetente_id uuid references public.logins(id) on delete set null,
  destinatario_id uuid references public.logins(id) on delete set null,
  assunto text,
  mensagem text not null,
  lida boolean not null default false,
  created_at timestamptz not null default now()
);

-- =========================
-- OCORRÊNCIAS
-- =========================
create sequence if not exists public.ocorrencias_seq start 1;

create table if not exists public.ocorrencias (
  id uuid primary key default gen_random_uuid(),
  protocolo text unique not null default ('OC-' || lpad(nextval('public.ocorrencias_seq')::text, 4, '0')),
  condominio_id uuid not null references public.condominios(id) on delete cascade,
  morador_id uuid references public.moradores(id) on delete set null,
  criado_por uuid references public.logins(id) on delete set null,
  responsavel_id uuid references public.logins(id) on delete set null,
  titulo text not null,
  descricao text not null,
  categoria text,
  prioridade text not null default 'normal' check (prioridade in ('baixa','normal','alta','urgente')),
  status text not null default 'aberta' check (status in ('aberta','em_andamento','aguardando','resolvida','cancelada')),
  etapa text,
  prazo_sla timestamptz,
  finalizada_em timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.anexos
  add constraint anexos_ocorrencia_fk
  foreign key (ocorrencia_id) references public.ocorrencias(id) on delete cascade;

create table if not exists public.ocorrencias_historico (
  id uuid primary key default gen_random_uuid(),
  ocorrencia_id uuid not null references public.ocorrencias(id) on delete cascade,
  usuario_id uuid references public.logins(id) on delete set null,
  status_anterior text,
  status_novo text,
  comentario text,
  created_at timestamptz not null default now()
);

-- =========================
-- COMUNICADOS
-- =========================
create table if not exists public.comunicados (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  titulo text not null,
  conteudo text not null,
  publicado boolean not null default true,
  fixado boolean not null default false,
  data_publicacao timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- =========================
-- AUDITORIA SIMPLES
-- =========================
create table if not exists public.auditoria (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid references public.logins(id) on delete set null,
  acao text not null,
  tabela text,
  registro_id uuid,
  detalhes jsonb,
  created_at timestamptz not null default now()
);

-- =========================
-- CONFIGURAÇÕES DA EMPRESA
-- =========================
create table if not exists public.configuracoes_empresa (
  id uuid primary key default gen_random_uuid(),
  nome_empresa text not null default 'Arquipélago Administração de Condomínios',
  slogan text default 'Sua jornada imobiliária começa aqui!',
  telefone text,
  whatsapp text,
  email text,
  site text,
  logo_url text,
  cor_primaria text default '#064B5E',
  cor_secundaria text default '#08A4C7',
  cor_destaque text default '#F77A1B',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.configuracoes_empresa (nome_empresa, slogan, cor_primaria, cor_secundaria, cor_destaque)
select 'Arquipélago Administração de Condomínios', 'Sua jornada imobiliária começa aqui!', '#064B5E', '#08A4C7', '#F77A1B'
where not exists (select 1 from public.configuracoes_empresa);

-- =========================
-- ÍNDICES
-- =========================
create index if not exists idx_logins_perfil on public.logins(perfil);
create index if not exists idx_logins_condominio on public.logins(condominio_id);
create index if not exists idx_moradores_condominio on public.moradores(condominio_id);
create index if not exists idx_porteiros_condominio on public.porteiros(condominio_id);
create index if not exists idx_lancamentos_condominio on public.lancamentos(condominio_id);
create index if not exists idx_lancamentos_status on public.lancamentos(status);
create index if not exists idx_lancamentos_competencia on public.lancamentos(competencia);
create index if not exists idx_anexos_condominio on public.anexos(condominio_id);
create index if not exists idx_mensagens_destinatario on public.mensagens(destinatario_id);
create index if not exists idx_ocorrencias_condominio on public.ocorrencias(condominio_id);
create index if not exists idx_ocorrencias_status on public.ocorrencias(status);
create index if not exists idx_comunicados_condominio on public.comunicados(condominio_id);

-- =========================
-- TRIGGER updated_at
-- =========================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_condominios_updated_at on public.condominios;
create trigger set_condominios_updated_at before update on public.condominios for each row execute function public.set_updated_at();

drop trigger if exists set_logins_updated_at on public.logins;
create trigger set_logins_updated_at before update on public.logins for each row execute function public.set_updated_at();

drop trigger if exists set_moradores_updated_at on public.moradores;
create trigger set_moradores_updated_at before update on public.moradores for each row execute function public.set_updated_at();

drop trigger if exists set_porteiros_updated_at on public.porteiros;
create trigger set_porteiros_updated_at before update on public.porteiros for each row execute function public.set_updated_at();

drop trigger if exists set_lancamentos_updated_at on public.lancamentos;
create trigger set_lancamentos_updated_at before update on public.lancamentos for each row execute function public.set_updated_at();

drop trigger if exists set_ocorrencias_updated_at on public.ocorrencias;
create trigger set_ocorrencias_updated_at before update on public.ocorrencias for each row execute function public.set_updated_at();

drop trigger if exists set_configuracoes_empresa_updated_at on public.configuracoes_empresa;
create trigger set_configuracoes_empresa_updated_at before update on public.configuracoes_empresa for each row execute function public.set_updated_at();

-- =========================
-- STORAGE PARA ANEXOS
-- =========================
insert into storage.buckets (id, name, public)
values ('portal-arquipelago', 'portal-arquipelago', true)
on conflict (id) do nothing;

-- Políticas liberais para compatibilidade com portal próprio usando chave anon.
-- Depois que o portal estiver funcionando, recomendo endurecer RLS com autenticação real.
alter table public.condominios disable row level security;
alter table public.logins disable row level security;
alter table public.moradores disable row level security;
alter table public.porteiros disable row level security;
alter table public.lancamentos disable row level security;
alter table public.anexos disable row level security;
alter table public.mensagens disable row level security;
alter table public.ocorrencias disable row level security;
alter table public.ocorrencias_historico disable row level security;
alter table public.comunicados disable row level security;
alter table public.auditoria disable row level security;
alter table public.configuracoes_empresa disable row level security;

-- Usuário administrador inicial. Troque a senha no primeiro acesso.
-- Caso seu app espere senha sem hash, ajuste no próprio app ou atualize senha_hash.
insert into public.logins (nome, email, perfil, senha_hash, ativo)
select 'Administrador Arquipélago', 'admin@arquipelago.local', 'admin', 'admin123', true
where not exists (select 1 from public.logins where email = 'admin@arquipelago.local');
