-- Sincronização definitiva entre Portal Web e App Android
-- Pessoas vinculadas, registros da portaria, múltiplas imagens e entregas.

alter table public.moradores add column if not exists pessoas_vinculadas text default '[]';
alter table public.moradores add column if not exists pessoas_moram_junto text default '[]';

-- Mantém as duas colunas espelhadas. Os clientes gravam um JSON textual
-- no formato [{"nome":"...","cpf":"..."}].
update public.moradores
set pessoas_vinculadas = pessoas_moram_junto
where (pessoas_vinculadas is null or btrim(pessoas_vinculadas) in ('','[]','null'))
  and pessoas_moram_junto is not null
  and btrim(pessoas_moram_junto) not in ('','[]','null');

update public.moradores
set pessoas_moram_junto = pessoas_vinculadas
where (pessoas_moram_junto is null or btrim(pessoas_moram_junto) in ('','[]','null'))
  and pessoas_vinculadas is not null
  and btrim(pessoas_vinculadas) not in ('','[]','null');

alter table public.registros_portaria add column if not exists nome text;
alter table public.registros_portaria add column if not exists cpf_rg text;
alter table public.registros_portaria add column if not exists empresa text;
alter table public.registros_portaria add column if not exists descricao text;
alter table public.registros_portaria add column if not exists observacao text;
alter table public.registros_portaria add column if not exists nome_entregador text;
alter table public.registros_portaria add column if not exists entregador_nome text;
alter table public.registros_portaria add column if not exists cpf_entregador text;
alter table public.registros_portaria add column if not exists entregador_cpf text;
alter table public.registros_portaria add column if not exists visitante_nome text;
alter table public.registros_portaria add column if not exists visitante_cpf text;
alter table public.registros_portaria add column if not exists prestador_empresa text;
alter table public.registros_portaria add column if not exists prestador_nome text;
alter table public.registros_portaria add column if not exists prestador_cpf text;
alter table public.registros_portaria add column if not exists imagens jsonb default '[]'::jsonb;
alter table public.registros_portaria add column if not exists imagem text;
alter table public.registros_portaria add column if not exists foto_url text;
alter table public.registros_portaria add column if not exists status_entrega text;
alter table public.registros_portaria add column if not exists recebedor_nome text;
alter table public.registros_portaria add column if not exists recebedor_cpf text;
alter table public.registros_portaria add column if not exists entregue_em timestamptz;
alter table public.registros_portaria add column if not exists lida_morador boolean default false;
alter table public.registros_portaria add column if not exists data_hora timestamptz default now();

update public.registros_portaria set tipo=lower(tipo) where tipo is not null;
update public.registros_portaria set tipo='prestador' where tipo in ('prestador de serviço','prestador de servico');
update public.registros_portaria set nome_entregador=coalesce(nullif(nome_entregador,''),nullif(entregador_nome,''),case when tipo='encomenda' then nome end),
 entregador_nome=coalesce(nullif(entregador_nome,''),nullif(nome_entregador,''),case when tipo='encomenda' then nome end),
 cpf_entregador=coalesce(nullif(cpf_entregador,''),nullif(entregador_cpf,''),case when tipo='encomenda' then cpf_rg end),
 entregador_cpf=coalesce(nullif(entregador_cpf,''),nullif(cpf_entregador,''),case when tipo='encomenda' then cpf_rg end),
 visitante_nome=coalesce(nullif(visitante_nome,''),case when tipo='visitante' then nome end),
 visitante_cpf=coalesce(nullif(visitante_cpf,''),case when tipo='visitante' then cpf_rg end),
 prestador_nome=coalesce(nullif(prestador_nome,''),case when tipo='prestador' then nome end),
 prestador_cpf=coalesce(nullif(prestador_cpf,''),case when tipo='prestador' then cpf_rg end),
 prestador_empresa=coalesce(nullif(prestador_empresa,''),case when tipo='prestador' then empresa end),
 descricao=coalesce(nullif(descricao,''),observacao),
 observacao=coalesce(nullif(observacao,''),descricao),
 status_entrega=case when tipo='encomenda' then coalesce(nullif(status_entrega,''),'pendente') else coalesce(nullif(status_entrega,''),'registrado') end,
 data_hora=coalesce(data_hora,created_at,now());

create index if not exists idx_registros_portaria_condominio on public.registros_portaria(condominio_id);
create index if not exists idx_registros_portaria_morador on public.registros_portaria(morador_id);
create index if not exists idx_registros_portaria_tipo on public.registros_portaria(tipo);
create index if not exists idx_registros_portaria_status on public.registros_portaria(status_entrega);

grant select,insert,update,delete on public.moradores to anon, authenticated;
grant select,insert,update,delete on public.registros_portaria to anon, authenticated;
