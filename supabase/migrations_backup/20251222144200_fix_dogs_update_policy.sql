-- Fix the UPDATE policy for dogs table to include WITH CHECK clause
-- This is needed because UPDATE policies require both USING (to check if you can see the row)
-- and WITH CHECK (to validate the new values)

DROP POLICY IF EXISTS "Admins can update dogs" ON dogadopt.dogs;

CREATE POLICY "Admins can update dogs"
ON dogadopt.dogs FOR UPDATE
USING (dogadopt.has_role(auth.uid(), 'admin'))
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));
