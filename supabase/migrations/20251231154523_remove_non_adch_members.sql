-- Migration: Remove non-ADCH member rescues
-- This migration removes rescue organizations that are no longer in the current ADCH member list
-- Data verified against: Editable-Members-List-with-regions-01102025.pdf (Updated: December 10, 2025)
-- 
-- Removes 22 rescues that are no longer ADCH members
-- Associated dogs will be automatically removed via CASCADE
-- Updates Woodgreen name to current name

-- First, update Woodgreen to its current name
UPDATE dogadopt.rescues
SET name = 'Woodgreen Pets Charity'
WHERE name = 'Woodgreen The Animals Charity';

-- Update Oak Tree Animals' Charity region (was incorrectly set to South West England)
UPDATE dogadopt.rescues
SET region = 'North West England'
WHERE name = 'Oak Tree Animals'' Charity';

-- Remove rescues that are no longer ADCH members
DELETE FROM dogadopt.rescues
WHERE name IN (
  'Staffie Smiles',
  'North Lincolnshire Greyhound Sanctuary',
  'Norfolk Greyhound Welfare',
  'Old Windsor Safari Park',
  'Paws Animal Sanctuary',
  'Pennine Pen Animal Rescue',
  'Pointer Rescue Service',
  'Redwings Horse Sanctuary',
  'Retired Greyhound Trust',
  'Rochdale Dog Rescue',
  'Scruples & Wellies Animal Rescue',
  'Setter Rescue Scotland',
  'Severn Edge Vets Charity',
  'Shropshire Cat Rescue',
  'The Surrey Border Collie & Sheepdog Welfare Society',
  'Underheugh Animal Sanctuary',
  'Viva Rescue',
  'West London Dog Rescue',
  'Westmorland Animal Sanctuary',
  'Wild at Heart Foundation',
  'Yorkshire Animal Sanctuary',
  'Yorkshire Coast Dog Rescue'
);
