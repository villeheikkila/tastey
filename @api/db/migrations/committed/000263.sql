--! Previous: sha1:4b8fd6484b8074c9f8e3a1d200300ec1536d5cb8
--! Hash: sha1:d671f90037dca34b4e3cd3b48b6e647a951fad54

--! split: 1-current.sql
-- Enter migration here
create or replace function app_public.users_friends(u app_public.users)
  returns table
          (
            id                  uuid,
            first_name          text,
            last_name           text,
            username            text,
            avatar_url          text,
            current_user_status app_public.friend_status
          )
  language sql
  stable
as
$$
with user_friends as (select urs.id, urs.first_name, urs.last_name, urs.username, urs.avatar_url
                      from app_public.friends f
                             left join app_public.users urs
                                       on (f.user_id_2 = urs.id or f.user_id_1 = urs.id) and urs.id != u.id
                      where f.user_id_1 = u.id
                         or f.user_id_2 = u.id)
select uf.*, f.status current_user_status
from user_friends uf
       left join app_public.friends f
                 on (f.user_id_1 = u.id and f.user_id_2 = app_public.current_user_id()) or
                    (f.user_id_2 = u.id and f.user_id_1 = app_public.current_user_id());
$$;
