begin;
-- Table structure for table: users
CREATE TABLE users (
   name TEXT PRIMARY KEY,
   password TEXT,
   email TEXT,
   gpg_keyid TEXT,
   last_login TIMESTAMP
);
CREATE INDEX users_email_idx ON users(email);

-- OpenID tables

CREATE TABLE openids (
   id TEXT PRIMARY KEY,
   name TEXT REFERENCES users
);

CREATE TABLE openid_sessions (
   id SERIAL PRIMARY KEY,
   provider TEXT,
   url TEXT,
   assoc_handle TEXT,
   expires TIMESTAMP,
   mac_key TEXT
);

CREATE TABLE openid_stypes (
   id INTEGER REFERENCES openid_sessions ON DELETE CASCADE,
   stype TEXT
);
CREATE INDEX openid_stypes_id ON openid_stypes(id);


CREATE TABLE openid_nonces (
   created TIMESTAMP,
   nonce TEXT
);
CREATE INDEX openid_nonces_created ON openid_nonces(created);
CREATE INDEX openid_nonces_nonce ON openid_nonces(nonce);

CREATE TABLE cookies (
    cookie text PRIMARY KEY,
    name text references users,
    last_seen timestamp
);
CREATE INDEX cookies_last_seen ON cookies(last_seen);

CREATE TABLE sshkeys(
   id SERIAL PRIMARY KEY,
   name TEXT REFERENCES users ON DELETE CASCADE,
   key TEXT
);
CREATE INDEX sshkeys_name ON sshkeys(name);

-- Table structure for table: rego_otk
CREATE TABLE rego_otk (
   name TEXT REFERENCES users,
   otk TEXT UNIQUE,
   date TIMESTAMP );
CREATE INDEX rego_otk_name_idx ON rego_otk(name);
CREATE INDEX rego_otk_otk_idx ON rego_otk(otk);

-- Table structure for table: journals
CREATE TABLE journals (
   name TEXT,
   version TEXT,
   action TEXT,
   submitted_date TIMESTAMP,
   submitted_by TEXT REFERENCES users,
   submitted_from TEXT
);
CREATE INDEX journals_name_idx ON journals(name);
CREATE INDEX journals_version_idx ON journals(version);
-- nosqlite
CREATE INDEX journals_latest_releases ON
  journals(submitted_date, name, version)
  WHERE version IS NOT NULL AND action='new release';
-- nosqlite-end
CREATE INDEX journals_changelog ON
  journals(submitted_date, name, version, action);

-- Table structure for table: packages
CREATE TABLE packages (
   name TEXT PRIMARY KEY,
   stable_version TEXT,
   normalized_name TEXT,
   autohide BOOLEAN DEFAULT TRUE,
   comments BOOLEAN DEFAULT TRUE
);

CREATE TABLE cheesecake_main_indices (
    id SERIAL PRIMARY KEY,
    absolute INTEGER NOT NULL,
    relative INTEGER NOT NULL
);

CREATE TABLE cheesecake_subindices (
    main_index_id INTEGER REFERENCES cheesecake_main_indices,
    name TEXT,
    value INTEGER NOT NULL,
    details TEXT NOT NULL,
    PRIMARY KEY (main_index_id, name)
);

-- Table structure for table: releases
CREATE TABLE releases (
   name TEXT REFERENCES packages ON UPDATE CASCADE,
   version TEXT,
   author TEXT,
   author_email TEXT,
   maintainer TEXT,
   maintainer_email TEXT,
   home_page TEXT,
   license TEXT,
   summary TEXT,
   description TEXT,
   description_html TEXT,
   keywords TEXT,
   platform TEXT,
   download_url TEXT,
   requires_python TEXT,
   cheesecake_installability_id INTEGER REFERENCES cheesecake_main_indices,
   cheesecake_documentation_id INTEGER REFERENCES cheesecake_main_indices,
   cheesecake_code_kwalitee_id INTEGER REFERENCES cheesecake_main_indices,
   _pypi_ordering INTEGER,
   _pypi_hidden BOOLEAN,
   PRIMARY KEY (name, version)
);
CREATE INDEX release_pypi_hidden_idx ON releases(_pypi_hidden);

-- Table structure for table: trove_classifiers
-- l2, l3, l4, l5 is the corresponding parent;
-- 0 if there is no parent on that level (each node is its
-- own parent)
CREATE TABLE trove_classifiers (
   id INTEGER PRIMARY KEY,
   classifier TEXT UNIQUE,
   l2 INTEGER,
   l3 INTEGER,
   l4 INTEGER,
   l5 INTEGER
);
CREATE INDEX trove_class_class_idx ON trove_classifiers(classifier);
CREATE INDEX trove_class_id_idx ON trove_classifiers(id);


-- Table structure for table: release_classifiers
CREATE TABLE release_classifiers (
   name TEXT,
   version TEXT,
   trove_id INTEGER REFERENCES trove_classifiers,
   FOREIGN KEY (name, version) REFERENCES releases (name, version)
);
CREATE INDEX rel_class_name_idx ON release_classifiers(name);
CREATE INDEX rel_class_version_id_idx ON release_classifiers(version);
CREATE INDEX rel_class_trove_id_idx ON release_classifiers(trove_id);
CREATE INDEX rel_class_name_version_idx ON release_classifiers(name, version);

-- Release dependencies
-- See store.py for the valid kind values
CREATE TABLE release_dependencies (
   name TEXT,
   version TEXT,
   kind INTEGER,
   specifier TEXT,
   FOREIGN KEY (name, version) REFERENCES releases (name, version)  ON UPDATE CASCADE
);
CREATE INDEX rel_dep_name_idx ON release_dependencies(name);
CREATE INDEX rel_dep_name_version_idx ON release_dependencies(name, version);
CREATE INDEX rel_dep_name_version_kind_idx ON release_dependencies(name, version, kind);

-- Table structure for table: package_files
-- python version is only first two digits
-- actual file path is constructed <py version>/<a-z>/<name>/<filename>
-- we remember filename because it can differ
CREATE TABLE release_files (
   name TEXT,
   version TEXT,
   python_version TEXT,
   packagetype TEXT,
   comment_text TEXT,
   filename TEXT UNIQUE,
   md5_digest TEXT UNIQUE,
   upload_time TIMESTAMP,
   downloads INTEGER DEFAULT 0,
   FOREIGN KEY (name, version) REFERENCES releases (name, version) ON UPDATE CASCADE
);
CREATE INDEX release_files_name_idx ON release_files(name);
CREATE INDEX release_files_version_idx ON release_files(version);
CREATE INDEX release_files_packagetype_idx ON release_files(packagetype);
CREATE INDEX release_files_name_version_idx ON release_files(name,version);


-- Table structure for table: package_urls
CREATE TABLE release_urls (
   name TEXT,
   version TEXT,
   url TEXT,
   packagetype TEXT,
   FOREIGN KEY (name, version) REFERENCES releases (name, version) ON UPDATE CASCADE
);
CREATE INDEX release_urls_name_idx ON release_urls(name);
CREATE INDEX release_urls_version_idx ON release_urls(version);
CREATE INDEX release_urls_packagetype_idx ON release_urls(packagetype);

-- Table structure for table: description_urls
CREATE TABLE description_urls (
   name TEXT,
   version TEXT,
   url TEXT,
   FOREIGN KEY (name, version) REFERENCES releases (name, version) ON UPDATE CASCADE
);
CREATE INDEX description_urls_name_idx ON description_urls(name);
CREATE INDEX description_urls_name_version_idx ON description_urls(name, version);

-- Table structure for table: roles
-- Note: roles are Maintainer, Admin, Owner
CREATE TABLE roles (
   role_name TEXT,
   user_name TEXT REFERENCES users,
   package_name TEXT REFERENCES packages ON UPDATE CASCADE
);
CREATE INDEX roles_pack_name_idx ON roles(package_name);
CREATE INDEX roles_user_name_idx ON roles(user_name);

-- Table structure for table: timestamps
-- Note: stamp_name is ftp, http, browse_tally
CREATE TABLE timestamps (
   name TEXT PRIMARY KEY,
   value TIMESTAMP
);
INSERT INTO timestamps(name, value) VALUES('http','1970-01-01 00:00:00');
INSERT INTO timestamps(name, value) VALUES('ftp','1970-01-01 00:00:00');
INSERT INTO timestamps(name, value) VALUES('browse_tally','1970-01-01 00:00:00');

-- Table structure for table: timestamps
-- Note: stamp_name is ftp, http
CREATE TABLE browse_tally (
   trove_id INTEGER PRIMARY KEY,
   tally INTEGER
);

-- Table structure for table: mirrors
CREATE TABLE mirrors (
   ip TEXT PRIMARY KEY,
   user_name TEXT REFERENCES users
);

-- ratings
CREATE TABLE ratings(
   id SERIAL PRIMARY KEY,
   name TEXT,
   version TEXT,
   user_name TEXT REFERENCES users ON DELETE CASCADE,
   date TIMESTAMP,
   rating INTEGER,
   UNIQUE(name,version,user_name),
   FOREIGN KEY (name, version) REFERENCES releases ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE INDEX rating_name_version ON ratings(name, version);
CREATE TABLE comments(
  id SERIAL PRIMARY KEY,
  rating INTEGER REFERENCES ratings(id) ON DELETE CASCADE,
  user_name TEXT REFERENCES users ON DELETE CASCADE,
  date TIMESTAMP,
  message TEXT,
  in_reply_to INTEGER REFERENCES comments ON DELETE CASCADE
);
CREATE TABLE comments_journal(
  name text,
  version text,
  id INTEGER,
  submitted_by TEXT REFERENCES users ON DELETE CASCADE,
  date TIMESTAMP,
  action TEXT,
  FOREIGN KEY (name, version) REFERENCES releases ON UPDATE CASCADE ON DELETE CASCADE
);

commit;
