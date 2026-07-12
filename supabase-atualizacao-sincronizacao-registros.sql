-- ARQUIPÉLAGO — sincronização Portal Web + Android
-- Execute no SQL Editor do Supabase. Script idempotente.

-- Moradores: os dois clientes passam a gravar as pessoas vinculadas em JSON textual.
alter table if exists public.moradores add column if not exists pessoas_vinculadas text default '[]';
alter table if exists public.moradores add column if not exists pessoas_moram_junto text default '[]';

update public.moradores
set pessoas_vinculadas = pessoas_moram_junto
where (pessoas_vinculadas is null or btrim(pessoas_vinculadas::text) in ('','[]','null'))
  and pessoas_moram_junto is not null;

update public.moradores
set pessoas_moram_junto = pessoas_vinculadas
where (pessoas_moram_junto is null or btrim(pessoas_moram_junto::text) in ('','[]','null'))
  and pessoas_vinculadas is not null;

-- Registros da portaria: nomenclatura única para site e aplicativo.
alter table if exists public.registros_portaria add column if not exists nome text;
alter table if exists public.registros_portaria add column if not exists cpf_rg text;
alter table if exists public.registros_portaria add column if not exists empresa text;
alter table if exists public.registros_portaria add column if not exists observacao text;
alter table if exists public.registros_portaria add column if not exists descricao text;
alter table if exists public.registros_portaria add column if not exists nome_entregador text;
alter table if exists public.registros_portaria add column if not exists entregador_nome text;
alter table if exists public.registros_portaria add column if not exists cpf_entregador text;
alter table if exists public.registros_portaria add column if not exists entregador_cpf text;
alter table if exists public.registros_portaria add column if not exists visitante_nome text;
alter table if exists public.registros_portaria add column if not exists visitante_cpf text;
alter table if exists public.registros_portaria add column if not exists prestador_empresa text;
alter table if exists public.registros_portaria add column if not exists prestador_nome text;
alter table if exists public.registros_portaria add column if not exists prestador_cpf text;
alter table if exists public.registros_portaria add column if not exists imagem text;
alter table if exists public.registros_portaria add column if not exists foto_url text;
alter table if exists public.registros_portaria add column if not exists imagens jsonb default '[]'::jsonb;
alter table if exists public.registros_portaria add column if not exists status_entrega text default 'pendente';
alter table if exists public.registros_portaria add column if not exists recebedor_nome text;
alter table if exists public.registros_portaria add column if not exists recebedor_cpf text;
alter table if exists public.registros_portaria add column if not exists entregue_em timestamptz;
alter table if exists public.registros_portaria add column if not exists lida_morador boolean default false;
alter table if exists public.registros_portaria add column if not exists data_hora timestamptz default now();

create index if not exists idx_registros_portaria_tipo_condominio
on public.registros_portaria(tipo, condominio_id);

create index if not exists idx_registros_portaria_morador_data
on public.registros_portaria(morador_id, created_at desc);

-- Compatibiliza registros antigos que usavam nomes de colunas diferentes.
update public.registros_portaria
set nome_entregador = coalesce(nullif(nome_entregador,''), nullif(entregador_nome,''), nome),
    entregador_nome = coalesce(nullif(entregador_nome,''), nullif(nome_entregador,''), nome),
    cpf_entregador = coalesce(nullif(cpf_entregador,''), nullif(entregador_cpf,''), cpf_rg),
    entregador_cpf = coalesce(nullif(entregador_cpf,''), nullif(cpf_entregador,''), cpf_rg)
where lower(tipo) = 'encomenda';

update public.registros_portaria
set visitante_nome = coalesce(nullif(visitante_nome,''), nome),
    visitante_cpf = coalesce(nullif(visitante_cpf,''), cpf_rg)
where lower(tipo) = 'visitante';

update public.registros_portaria
set prestador_nome = coalesce(nullif(prestador_nome,''), nome),
    prestador_cpf = coalesce(nullif(prestador_cpf,''), cpf_rg),
    prestador_empresa = coalesce(nullif(prestador_empresa,''), empresa)
where lower(tipo) in ('prestador','prestador de serviço');

notify pgrst, 'reload schema';
