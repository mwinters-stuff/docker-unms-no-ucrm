#!/bin/sh
REPO=$1
BRANCH=$2

git clone --depth=1 --single-branch --branch ${BRANCH} ${REPO}
cd docker-unms || exit 1

VER=$(grep "ubnt/unms:" Dockerfile | cut -f 2 -d ' ' | cut -f 2 -d ':')
echo "ums_version=${VER}"


CRM_UPDATE="psql -U \$UNMS_PG_USER -d \$POSTGRES_DB -c \"update crm_db_version_view set value = '$VER';\""
rm -rf root/etc/logrotate.d/ucrm || exit 1
rm -rf root/etc/services.d/ucrm || exit 1

sed -i '/^# UCRM/,+3 s|^|#|' root/etc/cont-init.d/40-prepare || exit 1
sed -i 's/.*logrotate.d\/ucrm/#&/' root/etc/cont-init.d/40-prepare || exit 1

sed -i "/if.*QUIET_MODE.*then/i $CRM_UPDATE" root/etc/services.d/unms/run || exit 1

sed -i 's/^FROM ubnt\/unms-crm.*/#&/' Dockerfile || exit 1
sed -i '/^# start unms-crm #$/,/^# end unms-crm #$/ s|^|#|' Dockerfile || exit 1
sed -i '/^# start php plugins \/ composer #$/,/^# end php plugins \/ composer #$/ s|^|#|' Dockerfile || exit 1
sed -i 's/^COPY --from=unms-crm.*available-servers.*/#&/' Dockerfile || exit 1
sed -i '/.*#location \/nms #g" \\/ s/\\//' Dockerfile || exit 1
sed -i '/.*sed.*\/etc\/nginx\/ucrm\/ucrm.conf.*/,+2 d' Dockerfile || exit 1
sed -i '/.*#location \/crm #g"/ d' Dockerfile || exit 1
