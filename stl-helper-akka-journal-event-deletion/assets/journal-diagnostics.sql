-- 1. Discover candidate event serializer manifests by short event name.
SELECT DISTINCT event_ser_manifest
FROM <schema>.event_journal
WHERE event_ser_manifest LIKE '%<ShortEventName>%'
LIMIT 20;

-- 2. Count affected journal rows by persistence id.
SELECT persistence_id,
       COUNT(*) AS cnt,
       MIN(sequence_number) AS min_seq,
       MAX(sequence_number) AS max_seq
FROM <schema>.event_journal
WHERE event_ser_manifest = '<FQN>'
GROUP BY persistence_id;

-- 3. Detect mid-stream rows. Any returned row means later events exist.
SELECT j.persistence_id,
       j.sequence_number
FROM <schema>.event_journal j
WHERE j.event_ser_manifest = '<FQN>'
  AND EXISTS (
    SELECT 1
    FROM <schema>.event_journal j2
    WHERE j2.persistence_id = j.persistence_id
      AND j2.sequence_number > j.sequence_number
  );

-- 4. Inspect snapshots for affected persistence ids. Adjust table name if needed.
SELECT persistence_id,
       sequence_number,
       created
FROM <schema>.snapshot
WHERE persistence_id IN (
  SELECT DISTINCT persistence_id
  FROM <schema>.event_journal
  WHERE event_ser_manifest = '<FQN>'
);

-- 5. Post-deploy verification.
SELECT COUNT(*) AS remaining
FROM <schema>.event_journal
WHERE event_ser_manifest = '<FQN>';
