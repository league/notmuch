#!/usr/bin/env bash

test_description='"notmuch config"'
. $(dirname "$0")/test-lib.sh || exit 1

test_begin_subtest "Get string value"
test_expect_equal "$(notmuch config get user.name)" "Notmuch Test Suite"

test_begin_subtest "Get list value"
cat <<EOF > EXPECTED
inbox
unread
EOF
notmuch config get new.tags | sort > OUTPUT
test_expect_equal_file EXPECTED OUTPUT

test_begin_subtest "Set string value"
notmuch config set foo.string "this is a string value"
test_expect_equal "$(notmuch config get foo.string)" "this is a string value"

test_begin_subtest "Set string value again"
notmuch config set foo.string "this is another string value"
test_expect_equal "$(notmuch config get foo.string)" "this is another string value"

test_begin_subtest "Set list value"
notmuch config set foo.list this "is a" "list value"
test_expect_equal "$(notmuch config get foo.list)" "\
this
is a
list value"

test_begin_subtest "Set list value again"
notmuch config set foo.list this "is another" "list value"
test_expect_equal "$(notmuch config get foo.list)" "\
this
is another
list value"

test_begin_subtest "Remove key"
notmuch config set foo.remove baz
notmuch config set foo.remove
test_expect_equal "$(notmuch config get foo.remove)" ""

test_begin_subtest "Remove non-existent key"
notmuch config set foo.nonexistent
test_expect_equal "$(notmuch config get foo.nonexistent)" ""

test_begin_subtest "List all items"
notmuch config list 2>&1 | notmuch_config_sanitize > OUTPUT
cat <<EOF > EXPECTED
built_with.compact=something
built_with.field_processor=something
built_with.retry_lock=something
database.mail_root=MAIL_DIR
database.path=MAIL_DIR
foo.list=this;is another;list value;
foo.string=this is another string value
maildir.synchronize_flags=true
new.ignore=
new.tags=unread;inbox
search.exclude_tags=
user.name=Notmuch Test Suite
user.other_email=test_suite_other@notmuchmail.org;test_suite@otherdomain.org
user.primary_email=test_suite@notmuchmail.org
EOF
test_expect_equal_file EXPECTED OUTPUT

test_begin_subtest "Top level --config=FILE option"
cp "${NOTMUCH_CONFIG}" alt-config
notmuch --config=alt-config config set user.name "Another Name"
test_expect_equal "$(notmuch --config=alt-config config get user.name)" \
    "Another Name"

test_begin_subtest "Top level --config:FILE option"
test_expect_equal "$(notmuch --config:alt-config config get user.name)" \
    "Another Name"

test_begin_subtest "Top level --config<space>FILE option"
test_expect_equal "$(notmuch --config  alt-config config get user.name)" \
    "Another Name"

test_begin_subtest "Top level --config=FILE option changed the right file"
test_expect_equal "$(notmuch config get user.name)" \
    "Notmuch Test Suite"

test_begin_subtest "Read config file through a symlink"
ln -s alt-config alt-config-link
test_expect_equal "$(notmuch --config=alt-config-link config get user.name)" \
    "Another Name"

test_begin_subtest "Write config file through a symlink"
notmuch --config=alt-config-link config set user.name "Link Name"
test_expect_equal "$(notmuch --config=alt-config-link config get user.name)" \
    "Link Name"

test_begin_subtest "Writing config file through symlink follows symlink"
test_expect_equal "$(readlink alt-config-link)" "alt-config"

test_begin_subtest "Round trip arbitrary key"
key=g${RANDOM}.m${RANDOM}
value=${RANDOM}
notmuch config set ${key} ${value}
output=$(notmuch config get ${key})
test_expect_equal "${output}" "${value}"

test_begin_subtest "Clear arbitrary key"
notmuch config set ${key}
output=$(notmuch config get ${key})
test_expect_equal "${output}" ""

db_path=${HOME}/database-path

test_begin_subtest "Absolute database path returned"
mkdir -p ${db_path}
notmuch config set database.path ${db_path}
test_expect_equal "$(notmuch config get database.path)" \
		  "${db_path}"

test_begin_subtest "Relative database path properly expanded"
notmuch config set database.path ${db_path}
test_expect_equal "$(notmuch config get database.path)" \
		  "${db_path}"


test_done
