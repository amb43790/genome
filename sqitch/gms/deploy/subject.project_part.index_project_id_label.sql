-- Deploy subject.project_part.project_id_label
-- requires: subject_project_part

BEGIN;

CREATE INDEX project_part_project_label_index on subject.project_part using btree (project_id, label);

COMMIT;
