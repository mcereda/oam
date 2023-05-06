FROM python:alpine

RUN pip3 --no-cache-dir install flask jsonpatch
COPY webhook.py /

USER nobody
EXPOSE 8080
ENTRYPOINT [ "python3", "/webhook.py" ]
