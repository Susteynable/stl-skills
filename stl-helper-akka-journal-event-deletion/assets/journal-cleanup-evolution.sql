# --- !Ups
-- Irreversible: removes persisted events of this type.
-- Replace <schema> and <FQN>; confirm ownership and diagnostics first.
DELETE FROM <schema>.event_journal
WHERE event_ser_manifest = '<FQN>';

# --- !Downs
-- Irreversible data deletion; no restore of journal rows.
