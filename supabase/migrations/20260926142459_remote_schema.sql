ALTER TABLE "public"."product_discount"
  ADD COLUMN "updated_at" timestamp WITH time zone DEFAULT now();

