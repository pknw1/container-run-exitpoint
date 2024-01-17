FROM alpine:latest
COPY root/ /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
