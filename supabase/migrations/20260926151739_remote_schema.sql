ALTER TABLE "public"."product_discount"
  ADD COLUMN "deleted_at" timestamp WITH time zone DEFAULT now();

