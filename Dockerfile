FROM jammyjamjamman/megaglest-no-data:latest

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
