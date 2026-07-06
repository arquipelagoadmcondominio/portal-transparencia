-- =============================================================
-- SUPABASE - PORTAL TRANSPARÊNCIA ARQUIPÉLAGO
-- Execute este arquivo no SQL Editor do Supabase novo.
-- Depois, no arquivo portal.js, substitua SUPABASE_URL e SUPABASE_ANON_KEY.
-- =============================================================

create extension if not exists "pgcrypto";

create table if not exists public.condominios (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  endereco text,
  cnpj text,
  responsavel text,
  telefone text,
  email text,
  status text default 'ativo',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.administradores (
  id uuid primary key default gen_random_uuid(),
  nome text not null default 'Administração Arquipélago',
  email text unique not null,
  senha text not null,
  perfil text default 'administrador',
  status text default 'ativo',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.moradores (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  nome text not null,
  email text not null,
  senha text not null default '123456',
  unidade text,
  cpf text,
  celular text,
  placa_veiculo text,
  moradores_juntos text,
  foto_placa_url text,
  status text default 'ativo',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (condominio_id, email)
);

create table if not exists public.portaria (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  nome text not null,
  cpf text,
  celular text,
  email text not null,
  senha text not null default '123456',
  status text default 'ativo',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (condominio_id, email)
);

create table if not exists public.lancamentos (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  titulo text not null,
  categoria text,
  descricao text,
  tipo text default 'despesa' check (tipo in ('despesa','receita')),
  valor numeric(12,2) not null default 0,
  data_lancamento date default current_date,
  arquivo_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.mensagens (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  morador_id uuid references public.moradores(id) on delete cascade,
  remetente text not null check (remetente in ('morador','admin')),
  texto text not null,
  lida boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.slas (
  id uuid primary key default gen_random_uuid(),
  categoria text not null,
  setor text,
  responsavel text,
  perfil text,
  dias integer default 3,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.ocorrencias (
  id uuid primary key default gen_random_uuid(),
  numero text unique not null,
  condominio_id uuid references public.condominios(id) on delete cascade,
  unidade text,
  solicitante text,
  categoria text not null,
  prioridade text default 'normal' check (prioridade in ('normal','alta','urgente')),
  descricao text not null,
  anexos text,
  status text default 'aberta' check (status in ('aberta','em_andamento','concluida','cancelada')),
  data_abertura date default current_date,
  data_conclusao date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_condominios_updated_at on public.condominios;
create trigger trg_condominios_updated_at before update on public.condominios for each row execute function public.set_updated_at();
drop trigger if exists trg_administradores_updated_at on public.administradores;
create trigger trg_administradores_updated_at before update on public.administradores for each row execute function public.set_updated_at();
drop trigger if exists trg_moradores_updated_at on public.moradores;
create trigger trg_moradores_updated_at before update on public.moradores for each row execute function public.set_updated_at();
drop trigger if exists trg_portaria_updated_at on public.portaria;
create trigger trg_portaria_updated_at before update on public.portaria for each row execute function public.set_updated_at();
drop trigger if exists trg_lancamentos_updated_at on public.lancamentos;
create trigger trg_lancamentos_updated_at before update on public.lancamentos for each row execute function public.set_updated_at();
drop trigger if exists trg_mensagens_updated_at on public.mensagens;
create trigger trg_mensagens_updated_at before update on public.mensagens for each row execute function public.set_updated_at();
drop trigger if exists trg_slas_updated_at on public.slas;
create trigger trg_slas_updated_at before update on public.slas for each row execute function public.set_updated_at();
drop trigger if exists trg_ocorrencias_updated_at on public.ocorrencias;
create trigger trg_ocorrencias_updated_at before update on public.ocorrencias for each row execute function public.set_updated_at();

-- Views úteis para relatórios
create or replace view public.vw_resumo_lancamentos_condominio as
select
  c.id as condominio_id,
  c.nome as condominio,
  count(l.id) as quantidade_lancamentos,
  coalesce(sum(case when l.tipo = 'despesa' then l.valor else 0 end),0) as total_despesas,
  coalesce(sum(case when l.tipo = 'receita' then l.valor else 0 end),0) as total_receitas,
  coalesce(sum(case when l.tipo = 'despesa' then l.valor else -l.valor end),0) as saldo_gastos
from public.condominios c
left join public.lancamentos l on l.condominio_id = c.id
group by c.id, c.nome;

-- Índices
create index if not exists idx_moradores_condominio on public.moradores(condominio_id);
create index if not exists idx_portaria_condominio on public.portaria(condominio_id);
create index if not exists idx_lancamentos_condominio on public.lancamentos(condominio_id);
create index if not exists idx_mensagens_morador on public.mensagens(morador_id);
create index if not exists idx_ocorrencias_condominio on public.ocorrencias(condominio_id);

-- Políticas simples para projeto estático com anon key.
-- Para uso comercial avançado, recomendo migrar login para Supabase Auth + RLS por usuário.
alter table public.condominios enable row level security;
alter table public.administradores enable row level security;
alter table public.moradores enable row level security;
alter table public.portaria enable row level security;
alter table public.lancamentos enable row level security;
alter table public.mensagens enable row level security;
alter table public.slas enable row level security;
alter table public.ocorrencias enable row level security;

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
drop policy if exists "portal_public_slas" on public.slas;
create policy "portal_public_slas" on public.slas for all using (true) with check (true);
drop policy if exists "portal_public_ocorrencias" on public.ocorrencias;
create policy "portal_public_ocorrencias" on public.ocorrencias for all using (true) with check (true);

-- Dados iniciais
insert into public.administradores (nome,email,senha,perfil)
values ('Administração Arquipélago','admin@arquipelago.com','admin123','administrador')
on conflict (email) do nothing;

insert into public.condominios (nome,endereco,responsavel)
values ('Condomínio Reserva das Praias','Manaus/AM','Síndico responsável')
on conflict do nothing;

insert into public.slas (categoria,setor,perfil,dias)
values
('Administrativo','Administrativo','Administrativo',3),
('Engenharia','Engenharia','Engenharia',5),
('Financeiro','Financeiro','Financeiro',2)
on conflict do nothing;

-- Storage para anexos/fotos, caso queira usar uploads pelo Supabase futuramente.
insert into storage.buckets (id, name, public)
values ('portal-arquipelago', 'portal-arquipelago', true)
on conflict (id) do nothing;

drop policy if exists "portal_arquipelago_storage_public" on storage.objects;
create policy "portal_arquipelago_storage_public" on storage.objects
for all using (bucket_id = 'portal-arquipelago') with check (bucket_id = 'portal-arquipelago');

-- =============================================================
-- ATUALIZAÇÃO 06/07/2026 - mensagens, avisos e anexos
-- Execute este bloco também se o banco já existir.
-- =============================================================
alter table public.moradores add column if not exists bloco text;
alter table public.moradores add column if not exists apartamento text;
alter table public.moradores add column if not exists pessoas_vinculadas text;
alter table public.moradores add column if not exists foto_placa_data text;

alter table public.lancamentos add column if not exists imagens text;
alter table public.lancamentos add column if not exists documentos text;

alter table public.mensagens drop constraint if exists mensagens_remetente_check;
alter table public.mensagens add constraint mensagens_remetente_check check (remetente in ('morador','admin','portaria'));
alter table public.mensagens add column if not exists destinatario text default 'admin';
alter table public.mensagens add column if not exists portaria_id uuid references public.portaria(id) on delete set null;
alter table public.mensagens add column if not exists anexo_imagem text;
alter table public.mensagens add column if not exists lida_admin boolean default false;
alter table public.mensagens add column if not exists lida_morador boolean default false;
alter table public.mensagens add column if not exists lida_portaria boolean default false;

create table if not exists public.avisos (
  id uuid primary key default gen_random_uuid(),
  condominio_id uuid references public.condominios(id) on delete cascade,
  titulo text not null,
  texto text not null,
  imagem text,
  lidos text default '[]',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.avisos enable row level security;
drop policy if exists "portal_public_avisos" on public.avisos;
create policy "portal_public_avisos" on public.avisos for all using (true) with check (true);
drop trigger if exists trg_avisos_updated_at on public.avisos;
create trigger trg_avisos_updated_at before update on public.avisos for each row execute function public.set_updated_at();
create index if not exists idx_avisos_condominio on public.avisos(condominio_id);
create index if not exists idx_mensagens_portaria on public.mensagens(portaria_id);
