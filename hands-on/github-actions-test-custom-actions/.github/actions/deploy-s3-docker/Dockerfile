FROM python:3.14@sha256:1eb6b7d4b76454b1de8317863ac3213b678c337b27e604a4e3fb70bddbb2bad7

COPY requirements.txt /requirements.txt

RUN pip install -r requirements.txt

COPY deployment.py /deployment.py

CMD ["python", "/deployment.py"]
