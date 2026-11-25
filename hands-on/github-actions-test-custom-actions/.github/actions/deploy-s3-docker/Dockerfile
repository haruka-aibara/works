FROM python:3.15@sha256:46837ed3105db0029b6d656816185c6258e3b39690532fb782428e0a5fd76182

COPY requirements.txt /requirements.txt

RUN pip install -r requirements.txt

COPY deployment.py /deployment.py

CMD ["python", "/deployment.py"]
