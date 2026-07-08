-- =============================================================
-- ATUALIZAÇÃO 100% SUPABASE - PORTAL ARQUIPÉLAGO
-- Execute este arquivo no SQL Editor do Supabase antes de subir o novo portal.
-- Ele cria a tabela central de usuários e padroniza mensagens para Site + App Android.
-- =============================================================

create extension if not exists "pgcrypto";

-- 1) Tabela central de usuários/login para todos os perfis.
create table if not exists public.usuarios (
  id uuid primary key default gen_random_uuid(),
  perfil text not null check (perfil in ('administrador','morador','portaria')),
  perfil_ref_id uuid,
  condominio_id uuid references public.condominios(id) on delete cascade,
  nome text not null,
  email text not null,
  senha text not null,
  ativo boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (perfil, perfil_ref_id),
  unique (perfil, condominio_id, email)
);

-- 2) Garante campos usados pelos cadastros e anexos.
alter table public.moradores add column if not exists bloco text;
alter table public.moradores add column if not exists apartamento text;
alter table public.moradores add column if not exists pessoas_vinculadas text;
alter table public.moradores add column if not exists foto_placa_data text;

alter table public.lancamentos add column if not exists imagens text;
alter table public.lancamentos add column if not exists documentos text;

-- 3) Mensagens padronizadas para site e app usarem a mesma tabela.
alter table public.mensagens drop constraint if exists mensagens_remetente_check;
alter table public.mensagens add constraint mensagens_remetente_check check (remetente in ('morador','admin','portaria'));
alter table public.mensagens add column if not exists destinatario text default 'admin';
alter table public.mensagens add column if not exists portaria_id uuid references public.portaria(id) on delete set null;
alter table public.mensagens add column if not exists anexo_imagem text;
alter table public.mensagens add column if not exists lida_admin boolean default false;
alter table public.mensagens add column if not exists lida_morador boolean default false;
alter table public.mensagens add column if not exists lida_portaria boolean default false;
alter table public.mensagens add column if not exists deleted_by text default '[]';
alter table public.mensagens add column if not exists perfil_remetente text;
alter table public.mensagens add column if not exists perfil_destinatario text;
alter table public.mensagens add column if not exists remetente_ref_id uuid;
alter table public.mensagens add column if not exists destinatario_ref_id uuid;

-- 4) Avisos com múltiplas imagens e leitura individual.
create table if not exists public.avisos (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  titulo text not null,
  texto text not null,
  imagem text,
  imagens text,
  lidos text default '[]',
  ocultos text default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.avisos add column if not exists imagens text;
alter table public.avisos add column if not exists ocultos text default '[]';
alter table public.avisos add column if not exists lidos text default '[]';

-- 5) Trigger updated_at.
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_usuarios_updated_at on public.usuarios;
create trigger trg_usuarios_updated_at before update on public.usuarios for each row execute function public.set_updated_at();
drop trigger if exists trg_avisos_updated_at on public.avisos;
create trigger trg_avisos_updated_at before update on public.avisos for each row execute function public.set_updated_at();

-- 6) RLS liberado para o portal estático com ANON KEY.
-- Para uso comercial, depois recomenda-se migrar para Supabase Auth + políticas por usuário.
alter table public.usuarios enable row level security;
alter table public.avisos enable row level security;

drop policy if exists "portal_public_usuarios" on public.usuarios;
create policy "portal_public_usuarios" on public.usuarios for all using (true) with check (true);
drop policy if exists "portal_public_avisos" on public.avisos;
create policy "portal_public_avisos" on public.avisos for all using (true) with check (true);

-- Garante as políticas das tabelas principais, caso não existam.
alter table public.condominios enable row level security;
alter table public.administradores enable row level security;
alter table public.moradores enable row level security;
alter table public.portaria enable row level security;
alter table public.lancamentos enable row level security;
alter table public.mensagens enable row level security;

drop policy if exists "portal_public_condominios" on public.condominios;
create policy "portal_public_condominios" on public.condominios for all using (true) with check (true);
drop policy if exists "portal_public_administradores" on public.administradores;
create policy "portal_public_administradores" on public.administradores for all using (true) with check (true);
drop policy if exists "portal_public_moradores" on public.moradores;
create policy "portal_public_moradores" on public.moradores for all using (true) with check (true);
drop policy if exists "portal_public_portaria" on public.portaria;
create policy "portal_public_portaria" on public.portaria for all using (true) with check (true);
drop policy if exists "portal_public_lancamentos" on public.lancamentos;
create policy "portal_public_lancamentos" on public.lancamentos for all using (true) with check (true);
drop policy if exists "portal_public_mensagens" on public.mensagens;
create policy "portal_public_mensagens" on public.mensagens for all using (true) with check (true);

-- 7) Índices para busca rápida no app e no site.
create index if not exists idx_usuarios_login on public.usuarios(perfil, condominio_id, email);
create index if not exists idx_usuarios_ref on public.usuarios(perfil, perfil_ref_id);
create index if not exists idx_mensagens_condominio_destino on public.mensagens(condominio_id, destinatario, created_at desc);
create index if not exists idx_mensagens_morador_portaria on public.mensagens(morador_id, portaria_id, created_at desc);
create index if not exists idx_avisos_condominio_created on public.avisos(condominio_id, created_at desc);

-- 8) Usuário administrador inicial salvo no Supabase.
insert into public.administradores (nome,email,senha,perfil,status)
values ('Administração Arquipélago','admin@arquipelago.com','admin123','administrador','ativo')
on conflict (email) do update set nome=excluded.nome, senha=excluded.senha, perfil=excluded.perfil, status=excluded.status;

-- 9) Migração automática dos logins atuais para a tabela central usuarios.
insert into public.usuarios (perfil, perfil_ref_id, condominio_id, nome, email, senha, ativo)
select 'administrador', a.id, null, a.nome, lower(a.email), a.senha, coalesce(a.status,'ativo') <> 'inativo'
from public.administradores a
on conflict (perfil, perfil_ref_id) do update
set nome=excluded.nome, email=excluded.email, senha=excluded.senha, ativo=excluded.ativo, updated_at=now();

insert into public.usuarios (perfil, perfil_ref_id, condominio_id, nome, email, senha, ativo)
select 'morador', m.id, m.condominio_id, m.nome, lower(m.email), m.senha, coalesce(m.status,'ativo') <> 'inativo'
from public.moradores m
on conflict (perfil, perfil_ref_id) do update
set condominio_id=excluded.condominio_id, nome=excluded.nome, email=excluded.email, senha=excluded.senha, ativo=excluded.ativo, updated_at=now();

insert into public.usuarios (perfil, perfil_ref_id, condominio_id, nome, email, senha, ativo)
select 'portaria', p.id, p.condominio_id, p.nome, lower(p.email), p.senha, coalesce(p.status,'ativo') <> 'inativo'
from public.portaria p
on conflict (perfil, perfil_ref_id) do update
set condominio_id=excluded.condominio_id, nome=excluded.nome, email=excluded.email, senha=excluded.senha, ativo=excluded.ativo, updated_at=now();

-- 10) Storage público para anexos/fotos/documentos.
insert into storage.buckets (id, name, public)
values ('portal-arquipelago', 'portal-arquipelago', true)
on conflict (id) do nothing;

drop policy if exists "portal_arquipelago_storage_public" on storage.objects;
create policy "portal_arquipelago_storage_public" on storage.objects
for all using (bucket_id = 'portal-arquipelago') with check (bucket_id = 'portal-arquipelago');
