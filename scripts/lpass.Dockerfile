FROM alpine:latest
RUN apk add --no-cache lastpass-cli
COPY lpass-get-note.sh /usr/local/bin/lpass-get-note
RUN chmod +x /usr/local/bin/lpass-get-note
ENTRYPOINT ["lpass-get-note"]
