-- Atualização única para portal web e app Android
alter table if exists public.mensagens
  add column if not exists perfil_remetente text,
  add column if not exists perfil_destinatario text,
  add column if not exists remetente_ref_id uuid,
  add column if not exists destinatario_ref_id uuid,
  add column if not exists lida_admin boolean default false,
  add column if not exists lida_morador boolean default false,
  add column if not exists lida_portaria boolean default false,
  add column if not exists deleted_by jsonb default '[]'::jsonb,
  add column if not exists anexo_imagem text;

create table if not exists public.registros_portaria (
  id uuid primary key default gen_random_uuid(), tipo text not null,
  condominio_id uuid, condominio text, torre text, apartamento text,
  morador_id uuid, morador_nome text, empresa text, descricao text,
  entregador_nome text, entregador_cpf text, foto_url text,
  status_entrega text default 'pendente', recebedor_nome text,
  recebedor_cpf text, entregue_em timestamptz, lida_morador boolean default false,
  visitante_nome text, visitante_cpf text, prestador_empresa text,
  prestador_nome text, prestador_cpf text, destino text, observacao text,
  criado_por uuid, criado_por_perfil text, data_registro date default current_date,
  hora_registro time default current_time, created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.registros_portaria
  add column if not exists entregador_nome text,
  add column if not exists entregador_cpf text,
  add column if not exists foto_url text,
  add column if not exists status_entrega text default 'pendente',
  add column if not exists recebedor_nome text,
  add column if not exists recebedor_cpf text,
  add column if not exists entregue_em timestamptz,
  add column if not exists lida_morador boolean default false;
create index if not exists idx_registros_portaria_morador on public.registros_portaria(morador_id);
create index if not exists idx_registros_portaria_cond_tipo on public.registros_portaria(condominio_id,tipo);
create index if not exists idx_registros_portaria_status on public.registros_portaria(status_entrega);
create index if not exists idx_mensagens_morador on public.mensagens(morador_id);
create index if not exists idx_mensagens_portaria on public.mensagens(portaria_id);
alter table public.registros_portaria enable row level security;
drop policy if exists "registros_portaria_select" on public.registros_portaria;
drop policy if exists "registros_portaria_insert" on public.registros_portaria;
drop policy if exists "registros_portaria_update" on public.registros_portaria;
drop policy if exists "registros_portaria_delete" on public.registros_portaria;
create policy "registros_portaria_select" on public.registros_portaria for select using (true);
create policy "registros_portaria_insert" on public.registros_portaria for insert with check (true);
create policy "registros_portaria_update" on public.registros_portaria for update using (true) with check (true);
create policy "registros_portaria_delete" on public.registros_portaria for delete using (true);
grant select,insert,update,delete on public.registros_portaria to anon,authenticated;
