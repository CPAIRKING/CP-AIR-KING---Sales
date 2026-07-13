create table if not exists kv_store (
  key text primary key,
  value text not null,
  updated_at timestamptz default now()
);

alter table kv_store enable row level security;

create policy "public read" on kv_store for select using (true);
create policy "public insert" on kv_store for insert with check (true);
create policy "public update" on kv_store for update using (true);
create policy "public delete" on kv_store for delete using (true);
