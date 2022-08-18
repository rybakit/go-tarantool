#!/usr/bin/env bash
set -xeuo pipefail

SRC_COMMIT="9ee45289e01232b8df1413efea11db170ae3b3b4"
SRC_FILE=timezones.h
DST_FILE=timezones.go

[ -e ${SRC_FILE} ] && rm ${SRC_FILE}
wget -O ${SRC_FILE} \
	https://raw.githubusercontent.com/tarantool/tarantool/${SRC_COMMIT}/src/lib/tzcode/timezones.h

# We don't need aliases in indexToTimezone because Tarantool always replace it:
#
# tarantool> T = date.parse '2022-01-01T00:00 Pacific/Enderbury'
# ---
# ...
# tarantool> T
# ---
# - 2022-01-01T00:00:00 Pacific/Kanton
# ...
#
# So we can do the same and don't worry, be happy.

cat <<EOF > ${DST_FILE}
package datetime

/* Automatically generated by gen-timezones.sh */

var indexToTimezone = map[int]string{
EOF

grep ZONE_ABBREV ${SRC_FILE} | sed "s/ZONE_ABBREV( *//g" | sed "s/[),]//g" \
	| awk '{printf("\t%s : %s,\n", $1, $3)}' >> ${DST_FILE}
grep ZONE_UNIQUE ${SRC_FILE} | sed "s/ZONE_UNIQUE( *//g" | sed "s/[),]//g" \
	| awk '{printf("\t%s : %s,\n", $1, $2)}' >> ${DST_FILE}

cat <<EOF >> ${DST_FILE}
}

var timezoneToIndex = map[string]int{
EOF

grep ZONE_ABBREV ${SRC_FILE} | sed "s/ZONE_ABBREV( *//g" | sed "s/[),]//g" \
	| awk '{printf("\t%s : %s,\n", $3, $1)}' >> ${DST_FILE}
grep ZONE_UNIQUE ${SRC_FILE} | sed "s/ZONE_UNIQUE( *//g" | sed "s/[),]//g" \
	| awk '{printf("\t%s : %s,\n", $2, $1)}' >> ${DST_FILE}
grep ZONE_ALIAS  ${SRC_FILE} | sed "s/ZONE_ALIAS( *//g"  | sed "s/[),]//g" \
	| awk '{printf("\t%s : %s,\n", $2, $1)}' >> ${DST_FILE}

echo "}" >> ${DST_FILE}

rm timezones.h

gofmt -s -w ${DST_FILE}