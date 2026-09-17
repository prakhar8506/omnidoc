-- Storage buckets for Health Companion (run after core tables exist)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('lab-uploads', 'lab-uploads', false, 52428800, array['image/jpeg','image/png','image/webp','application/pdf']),
  ('avatars', 'avatars', false, 5242880, array['image/jpeg','image/png','image/webp']),
  ('exports', 'exports', false, 52428800, array['application/pdf','application/json','application/fhir+json'])
on conflict (id) do nothing;

-- Lab uploads: users can manage only their own folder (user_id as first path segment)
drop policy if exists "lab_uploads_select_own" on storage.objects;
create policy "lab_uploads_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "lab_uploads_insert_own" on storage.objects;
create policy "lab_uploads_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "lab_uploads_update_own" on storage.objects;
create policy "lab_uploads_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "lab_uploads_delete_own" on storage.objects;
create policy "lab_uploads_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_select_own" on storage.objects;
create policy "avatars_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "exports_select_own" on storage.objects;
create policy "exports_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "exports_insert_own" on storage.objects;
create policy "exports_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text);
