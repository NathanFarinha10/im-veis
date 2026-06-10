-- ============================================================
-- PATRIMÔNIO FII · Setup do banco no Supabase
-- Cole este script inteiro em: SQL Editor → New query → Run
-- ============================================================

-- Tabelas (modelo flexível: cada registro guarda os campos em JSONB,
-- exatamente como o front-end envia — sem risco de divergência de schema)
create table if not exists public.imoveis (
  id         bigint generated always as identity primary key,
  dados      jsonb not null,
  criado_em  timestamptz default now(),
  atualizado_em timestamptz default now()
);

create table if not exists public.propostas (
  id         bigint generated always as identity primary key,
  dados      jsonb not null,
  criado_em  timestamptz default now(),
  atualizado_em timestamptz default now()
);

-- Atualiza "atualizado_em" automaticamente em toda edição
create or replace function public.touch_atualizado_em()
returns trigger language plpgsql as $$
begin
  new.atualizado_em = now();
  return new;
end $$;

drop trigger if exists trg_touch_imoveis on public.imoveis;
create trigger trg_touch_imoveis before update on public.imoveis
  for each row execute function public.touch_atualizado_em();

drop trigger if exists trg_touch_propostas on public.propostas;
create trigger trg_touch_propostas before update on public.propostas
  for each row execute function public.touch_atualizado_em();

-- Índices úteis para filtros futuros
create index if not exists ix_imoveis_status on public.imoveis ((dados->>'status'));
create index if not exists ix_propostas_imovel on public.propostas (((dados->>'imovelId')::bigint));

-- ============================================================
-- Segurança (RLS)
-- Versão inicial: qualquer pessoa com a chave "anon" do projeto
-- pode ler e gravar. Suficiente para um time interno pequeno,
-- mas a URL do site dá acesso aos dados — veja a nota no guia
-- para evoluir para login por e-mail (Supabase Auth).
-- ============================================================
alter table public.imoveis   enable row level security;
alter table public.propostas enable row level security;

drop policy if exists "acesso_total_imoveis" on public.imoveis;
create policy "acesso_total_imoveis" on public.imoveis
  for all using (true) with check (true);

drop policy if exists "acesso_total_propostas" on public.propostas;
create policy "acesso_total_propostas" on public.propostas
  for all using (true) with check (true);

-- ============================================================
-- Realtime: permite que todos os analistas vejam alterações
-- ao vivo, sem recarregar a página
-- ============================================================
alter publication supabase_realtime add table public.imoveis;
alter publication supabase_realtime add table public.propostas;
