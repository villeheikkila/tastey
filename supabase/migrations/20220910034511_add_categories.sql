create table "public"."categories" (
    "id" bigint generated by default as identity not null,
    "name" text not null
);


CREATE UNIQUE INDEX categories_pkey ON public.categories USING btree (id);

alter table "public"."categories" add constraint "categories_pkey" PRIMARY KEY using index "categories_pkey";


