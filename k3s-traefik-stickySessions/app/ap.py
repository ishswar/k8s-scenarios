import uuid
import socket
from flask import Flask, render_template, request, redirect, url_for, flash, make_response, session

app = Flask(__name__)

uid = uuid.uuid4()
app.secret_key = str(uid)


# ...
@app.route('/visits-counter/')
def visits():
    if 'visits' in session:
        session['visits'] = session.get('visits') + 1  # reading and updating session data
    else:
        session['visits'] = 1  # setting session data
    return "Hello from Server [" + socket.gethostname() \
           + "] Total visitors on this server : {}".format(session.get('visits'))


@app.route('/delete-visits/')
def delete_visits():
    session.pop('visits', None)  # delete visits
    return 'Visits deleted'


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)

#curl --cookie cookie.txt --cookie-jar cookie.txt http://localhost:8080/visits-counter/

"""FROM python:3.6

RUN pip install flask

COPY . /opt/

EXPOSE 8080

WORKDIR /opt

ENTRYPOINT ["python", "app.py"] """

#ishswar/webpyapp:1.0.0