-- Profiles linked to auth.users. Run this in the Supabase SQL editor.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'student'
    check (role in ('admin', 'teacher', 'student')),
  name text,
  address text,
  contact_number text,
  guardian text,
  year text,
  section text
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Create a profile row when a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role)
  values (
    new.id,
    case
      when lower(coalesce(new.email, '')) like '%@deped.gov.ph' then 'teacher'
      when lower(coalesce(new.email, '')) like '%@depedlaspinas.ph' then 'student'
      else 'student'
    end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- If profiles already exists, re-run only the function above in the SQL editor
-- so new @deped.gov.ph signups are created as teachers.
