SET local check_function_bodies = off;

CREATE TABLE "public"."article_tag" (
  "article_id" uuid NOT NULL,
  "tag_id"     uuid NOT NULL,
  CONSTRAINT "article_tag_pkey" PRIMARY KEY (article_id, tag_id)
);

ALTER TABLE "public"."article_tag"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."articles" (
  "id"           uuid                     NOT NULL DEFAULT extensions.uuid_generate_v4(),
  "slug"         text                     NOT NULL,
  "title"        text                     NOT NULL,
  "author"       text                     NOT NULL,
  "cover"        text,
  "content"      text                     NOT NULL,
  "is_published" boolean                  NOT NULL DEFAULT false,
  "created_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "deleted_at"   timestamp with time zone,
  CONSTRAINT "articles_pkey" PRIMARY KEY (id),
  CONSTRAINT "articles_slug_key" UNIQUE (slug)
);

ALTER TABLE "public"."articles"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."discounts" (
  "id"           uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "title"        character varying(255)   NOT NULL,
  "value"        numeric(12,2)            NOT NULL,
  "max_discount" numeric(12,2)            DEFAULT NULL::numeric,
  "min_purchase" numeric(12,2)            DEFAULT 0,
  "start_at"     timestamp with time zone NOT NULL,
  "end_at"       timestamp with time zone NOT NULL,
  "created_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "deleted_at"   timestamp with time zone,
  CONSTRAINT "check_dates" CHECK ((end_at > start_at)),
  CONSTRAINT "discounts_pkey" PRIMARY KEY (id),
  CONSTRAINT "discounts_value_check" CHECK ((value > (0)::numeric))
);

ALTER TABLE "public"."discounts"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."photos" (
  "id"          uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "src"         text                     NOT NULL,
  "title"       text                     NOT NULL DEFAULT 'Untitled'::text,
  "description" text,
  "created_at"  timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"  timestamp with time zone NOT NULL DEFAULT now(),
  "deleted_at"  timestamp with time zone,
  CONSTRAINT "photos_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."photos"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."product_discount" (
  "id"          uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "product_id"  uuid                     NOT NULL,
  "discount_id" uuid                     NOT NULL,
  "created_at"  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "catalog_discounts_pkey" PRIMARY KEY (id),
  CONSTRAINT "unique_catalog_discount" UNIQUE (product_id, discount_id)
);

ALTER TABLE "public"."product_discount"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."product_tags" (
  "product_id" uuid NOT NULL,
  "tag_id"     uuid NOT NULL,
  CONSTRAINT "product_tags_pkey" PRIMARY KEY (product_id, tag_id)
);

ALTER TABLE "public"."product_tags"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."products" (
  "id"          uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "title"       character varying(255)   NOT NULL,
  "description" text,
  "price"       numeric(12,2)            NOT NULL,
  "stock"       integer                  DEFAULT 0,
  "img"         text,
  "created_at"  timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"  timestamp with time zone NOT NULL DEFAULT now(),
  "deleted_at"  timestamp with time zone,
  CONSTRAINT "catalogs_pkey" PRIMARY KEY (id),
  CONSTRAINT "catalogs_price_check" CHECK ((price >= (0)::numeric)),
  CONSTRAINT "catalogs_stock_check" CHECK ((stock >= 0))
);

ALTER TABLE "public"."products"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."tags" (
  "id"   uuid NOT NULL DEFAULT gen_random_uuid(),
  "name" text NOT NULL,
  CONSTRAINT "tags_name_key" UNIQUE (name),
  CONSTRAINT "tags_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."tags"
  ENABLE ROW LEVEL SECURITY;

CREATE TYPE "public"."discount_type" AS ENUM (
  'percentage',
  'fixed'
);

ALTER TABLE "public"."discounts"
  ADD COLUMN "type" public.discount_type NOT NULL;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
begin
    new.updated_at = now();
    return new;
end;
$function$;

ALTER TABLE "public"."article_tag"
  ADD CONSTRAINT "article_tag_article_id_fkey" FOREIGN KEY (article_id) REFERENCES public.articles(id) ON DELETE CASCADE;

ALTER TABLE "public"."product_discount"
  ADD CONSTRAINT "catalog_discounts_discount_id_fkey" FOREIGN KEY (discount_id) REFERENCES public.discounts(id) ON DELETE CASCADE;

ALTER TABLE "public"."product_discount"
  ADD CONSTRAINT "catalog_discounts_catalog_id_fkey" FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE "public"."product_tags"
  ADD CONSTRAINT "product_tags_product_id_fkey" FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE "public"."article_tag"
  ADD CONSTRAINT "article_tag_tag_id_fkey" FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;

ALTER TABLE "public"."product_tags"
  ADD CONSTRAINT "product_tags_tag_id_fkey" FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;

CREATE INDEX idx_articles_deleted_at ON public.articles USING btree (deleted_at);

CREATE INDEX idx_articles_slug ON public.articles USING btree (slug);

CREATE INDEX idx_photos_created_at ON public.photos USING btree (created_at DESC);

CREATE INDEX idx_photos_deleted_at ON public.photos USING btree (deleted_at);

CREATE TRIGGER update_discounts_updated_at
  BEFORE UPDATE ON public.discounts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER set_photos_updated_at
  BEFORE UPDATE ON public.photos
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_catalogs_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE POLICY "Authenticated users can manage article_tag" ON "public"."article_tag"
  FOR ALL
  TO "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Public article_tag are viewable by everyone" ON "public"."article_tag"
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Authenticated users can delete articles" ON "public"."articles"
  FOR DELETE
  TO "authenticated"
  USING (true);

CREATE POLICY "Authenticated users can insert articles" ON "public"."articles"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (true);

CREATE POLICY "Authenticated users can read all articles" ON "public"."articles"
  FOR SELECT
  TO "authenticated"
  USING (true);

CREATE POLICY "Authenticated users can update articles" ON "public"."articles"
  FOR UPDATE
  TO "authenticated"
  USING (true);

CREATE POLICY "Public can read published articles" ON "public"."articles"
  FOR SELECT
  TO "anon"
  USING (((is_published = true) AND (deleted_at IS NULL)));

CREATE POLICY "Allow delete for authenticated users on discounts" ON "public"."discounts"
  FOR DELETE
  TO "authenticated"
  USING (true);

CREATE POLICY "Allow insert for authenticated users on discounts" ON "public"."discounts"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (true);

CREATE POLICY "Allow read for non-deleted discounts" ON "public"."discounts"
  FOR SELECT
  TO PUBLIC
  USING ((deleted_at IS NULL));

CREATE POLICY "Allow update for authenticated users on discounts" ON "public"."discounts"
  FOR UPDATE
  TO "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated to read all photos" ON "public"."photos"
  FOR SELECT
  TO "authenticated"
  USING (true);

CREATE POLICY "Allow authenticated users to delete photos" ON "public"."photos"
  FOR DELETE
  TO "authenticated"
  USING (true);

CREATE POLICY "Allow authenticated users to insert photos" ON "public"."photos"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update photos" ON "public"."photos"
  FOR UPDATE
  TO "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow public to read non-deleted photos" ON "public"."photos"
  FOR SELECT
  TO "anon"
  USING ((deleted_at IS NULL));

CREATE POLICY "Allow delete for authenticated users on catalog_discounts" ON "public"."product_discount"
  FOR DELETE
  TO "authenticated"
  USING (true);

CREATE POLICY "Allow insert for authenticated users on catalog_discounts" ON "public"."product_discount"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (true);

CREATE POLICY "Allow read for catalog_discounts" ON "public"."product_discount"
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow update for authenticated users on catalog_discounts" ON "public"."product_discount"
  FOR UPDATE
  TO "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Pengguna terautentikasi dapat menambah product_tags" ON "public"."product_tags"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (true);

CREATE POLICY "Pengguna terautentikasi dapat menghapus product_tags" ON "public"."product_tags"
  FOR DELETE
  TO "authenticated"
  USING (true);

CREATE POLICY "Siapapun dapat melihat product_tags" ON "public"."product_tags"
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow anon to read active catalogs" ON "public"."products"
  FOR SELECT
  TO "anon"
  USING ((deleted_at IS NULL));

CREATE POLICY "Allow authenticated to read all catalogs" ON "public"."products"
  FOR SELECT
  TO "authenticated"
  USING (true);

CREATE POLICY "Allow delete for authenticated users on catalogs" ON "public"."products"
  FOR DELETE
  TO "authenticated"
  USING (true);

CREATE POLICY "Allow insert for authenticated users on catalogs" ON "public"."products"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (true);

CREATE POLICY "Allow update for authenticated users on catalogs" ON "public"."products"
  FOR UPDATE
  TO "authenticated"
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Authenticated users can insert tags" ON "public"."tags"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (true);

CREATE POLICY "Public tags are viewable by everyone" ON "public"."tags"
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Allow authenticated users to delete photo_assets" ON "storage"."objects"
  FOR DELETE
  TO "authenticated"
  USING ((bucket_id = 'photo_assets'::text));

CREATE POLICY "Allow authenticated users to update photo_assets" ON "storage"."objects"
  FOR UPDATE
  TO "authenticated"
  USING ((bucket_id = 'photo_assets'::text));

CREATE POLICY "Allow authenticated users to upload photo_assets" ON "storage"."objects"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((bucket_id = 'photo_assets'::text));

CREATE POLICY "Allow public read-only access to photo_assets" ON "storage"."objects"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((bucket_id = 'photo_assets'::text));

CREATE POLICY "Authenticated Users Delete Product Assets" ON "storage"."objects"
  FOR DELETE
  TO "authenticated"
  USING ((bucket_id = 'product_assets'::text));

CREATE POLICY "Authenticated Users Update Product Assets" ON "storage"."objects"
  FOR UPDATE
  TO "authenticated"
  USING ((bucket_id = 'product_assets'::text));

CREATE POLICY "Authenticated Users Upload Product Assets" ON "storage"."objects"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((bucket_id = 'product_assets'::text));

CREATE POLICY "Authenticated users can update assets" ON "storage"."objects"
  FOR UPDATE
  TO "authenticated"
  USING ((bucket_id = 'article_assets'::text));

CREATE POLICY "Authenticated users can upload assets" ON "storage"."objects"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((bucket_id = 'article_assets'::text));

CREATE POLICY "Public Access Product Assets" ON "storage"."objects"
  FOR SELECT
  TO PUBLIC
  USING ((bucket_id = 'product_assets'::text));

CREATE POLICY "Public Access" ON "storage"."objects"
  FOR SELECT
  TO PUBLIC
  USING ((bucket_id = 'article_assets'::text));

GRANT EXECUTE ON FUNCTION "public"."update_updated_at_column"() TO PUBLIC, "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."article_tag" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."articles" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."discounts" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."photos" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."product_discount" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."product_tags" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."products" TO "anon", "authenticated", "postgres", "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."tags" TO "anon", "authenticated", "postgres", "service_role";

GRANT USAGE ON TYPE "public"."discount_type" TO "postgres";

