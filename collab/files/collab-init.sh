#!/bin/sh

set -e

if ! test -d /srv/wikis/collab/underlay/pages; then
    cp -R /usr/share/moin/underlay/pages /srv/wikis/collab/underlay
    chmod -R g=u,o-rwx /srv/wikis/collab/underlay/pages
    chown -R collab:collab /srv/wikis/collab/underlay/pages
fi

if ! test -d /srv/wikis/collab/wikis/collab; then
    su -s /bin/sh - collab -c "collab-create collab collab && collab-account-create -f -r collab"
    su -s /bin/sh - collab -c "env PYTHONPATH=/srv/wikis/collab/wikis/collab/config python -m MoinMoin.packages -u collab i /srv/wikis/collab/underlay/pages/LanguageSetup/attachments/English--all_pages.zip"
    su -s /bin/sh - collab -c "env PYTHONPATH=/srv/wikis/collab/wikis/collab/config python -m MoinMoin.packages -u collab i /var/lib/collab/CollabBase.zip"
    su -s /bin/sh - collab -c "gwiki-rehash /srv/wikis/collab/wikis/collab"
fi
