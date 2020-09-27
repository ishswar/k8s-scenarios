FROM python:3.6

RUN pip install flask

COPY . /opt/

EXPOSE 8080

WORKDIR /opt

ENTRYPOINT ["python", "app.py"]

#docker run -it --entrypoint "/bin/sh" ishswar/webpyapp:1.0.0 -c "python app.py >> out.text"