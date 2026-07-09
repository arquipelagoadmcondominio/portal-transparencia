-- Atualização do Portal Web para ficar alinhado com o app Android
-- Execute no SQL Editor do Supabase antes de subir/testar o projeto atualizado.

-- 1) Compatibiliza tabela avisos para admin e portaria publicarem avisos no mesmo quadro
create table if not exists public.avisos (
  id uuid primary key default gen_random_uuid(),
  condominio_id text,
  titulo text,
  texto text,
  created_at timestamptz default now()
);

alter table public.avisos add column if not exists condominio text;
alter table public.avisos add column if not exists mensagem text;
alter table public.avisos add column if not exists descricao text;
alter table public.avisos add column if not exists perfil_autor text default 'admin';
alter table public.avisos add column if not exists autor_id text;
alter table public.avisos add column if not exists imagem text;
alter table public.avisos add column if not exists imagem_url text;
alter table public.avisos add column if not exists imagens jsonb default '[]'::jsonb;
alter table public.avisos add column if not exists lidos jsonb default '[]'::jsonb;
alter table public.avisos add column if not exists ocultos jsonb default '[]'::jsonb;
alter table public.avisos add column if not exists lida boolean default false;
alter table public.avisos add column if not exists oculto boolean default false;
alter table public.avisos add column if not exists updated_at timestamptz default now();

update public.avisos set mensagem = coalesce(mensagem, texto, descricao) where mensagem is null;
update public.avisos set descricao = coalesce(descricao, mensagem, texto) where descricao is null;
update public.avisos set texto = coalesce(texto, mensagem, descricao) where texto is null;

-- 2) Garante colunas necessárias na tabela mensagens
create table if not exists public.mensagens (
  id uuid primary key default gen_random_uuid(),
  condominio_id text,
  morador_id text,
  portaria_id text,
  remetente text,
  destinatario text,
  texto text,
  created_at timestamptz default now()
);

alter table public.mensagens add column if not exists perfil_remetente text;
alter table public.mensagens add column if not exists perfil_destinatario text;
alter table public.mensagens add column if not exists remetente_ref_id text;
alter table public.mensagens add column if not exists destinatario_ref_id text;
alter table public.mensagens add column if not exists anexo_imagem text;
alter table public.mensagens add column if not exists lida_admin boolean default false;
alter table public.mensagens add column if not exists lida_morador boolean default false;
alter table public.mensagens add column if not exists lida_portaria boolean default false;
alter table public.mensagens add column if not exists deleted_by jsonb default '[]'::jsonb;
alter table public.mensagens add column if not exists updated_at timestamptz default now();

-- 3) Nova tabela para registros da portaria: encomendas, visitantes e prestadores
create table if not exists public.registros_portaria (
  id uuid primary key default gen_random_uuid(),
  tipo text not null, -- encomenda, visitante, prestador
  condominio text,
  condominio_id text,
  torre text,
  apartamento text,
  morador_id text,
  morador_nome text,

  empresa text,
  descricao text,
  foto_url text,

  visitante_nome text,
  visitante_cpf text,
  visitante_rg text,
  visitante_telefone text,

  prestador_empresa text,
  prestador_nome text,
  prestador_cpf text,
  prestador_rg text,
  prestador_telefone text,
  destino text,

  observacao text,
  criado_por text,
  criado_por_perfil text default 'portaria',
  data_registro date default current_date,
  hora_registro time default current_time,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4) RLS e permissões para uso via API anon do projeto atual
alter table public.avisos enable row level security;
alter table public.mensagens enable row level security;
alter table public.registros_portaria enable row level security;

drop policy if exists "avisos_select" on public.avisos;
drop policy if exists "avisos_insert" on public.avisos;
drop policy if exists "avisos_update" on public.avisos;
drop policy if exists "avisos_delete" on public.avisos;
create policy "avisos_select" on public.avisos for select using (true);
create policy "avisos_insert" on public.avisos for insert with check (true);
create policy "avisos_update" on public.avisos for update using (true) with check (true);
create policy "avisos_delete" on public.avisos for delete using (true);

drop policy if exists "mensagens_select" on public.mensagens;
drop policy if exists "mensagens_insert" on public.mensagens;
drop policy if exists "mensagens_update" on public.mensagens;
drop policy if exists "mensagens_delete" on public.mensagens;
create policy "mensagens_select" on public.mensagens for select using (true);
create policy "mensagens_insert" on public.mensagens for insert with check (true);
create policy "mensagens_update" on public.mensagens for update using (true) with check (true);
create policy "mensagens_delete" on public.mensagens for delete using (true);

drop policy if exists "registros_portaria_select" on public.registros_portaria;
drop policy if exists "registros_portaria_insert" on public.registros_portaria;
drop policy if exists "registros_portaria_update" on public.registros_portaria;
drop policy if exists "registros_portaria_delete" on public.registros_portaria;
create policy "registros_portaria_select" on public.registros_portaria for select using (true);
create policy "registros_portaria_insert" on public.registros_portaria for insert with check (true);
create policy "registros_portaria_update" on public.registros_portaria for update using (true) with check (true);
create policy "registros_portaria_delete" on public.registros_portaria for delete using (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.avisos to anon, authenticated;
grant select, insert, update, delete on public.mensagens to anon, authenticated;
grant select, insert, update, delete on public.registros_portaria to anon, authenticated;
