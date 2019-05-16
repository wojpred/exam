FROM python:3.6.2
ADD . /usr/app
WORKDIR /usr/app
RUN pip install -r requirements.txt
ENTRYPOINT ["python"]
CMD ["whoami.py"]
