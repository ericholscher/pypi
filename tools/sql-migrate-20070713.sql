create index journals_changelog on journals(submitted_date, name, version, action) where version is not null;
