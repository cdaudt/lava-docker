#!/usr/bin/python
from optparse import OptionParser
import sys
import subprocess
import os
import json
import tempfile
import requests
import urlparse

def add_worker(url, worker):
    # Sequence is:
    # GET /accounts/login -> cookies1
    # POST /admin/login(cookies1,username,password) -> cookies2
    # POST /admin/lava_scheduler_app/worker/add(cookies2,hostname)
    print("Adding worker:{} to URL:{}".
            format(worker['name'], url))
    if url == None:
        raise Exception("Need URL")

    resp = requests.get(urlparse.urljoin(url, '/accounts/login/'))
    #print "Get Cookies: result= {} cookies= {}".format(resp, resp.cookies);
    #print "Get Cookies:text={}".format(resp.text);

    auth = {
     'csrfmiddlewaretoken': resp.cookies['csrftoken'],
     'username': 'admin',
     'password': 'admin'
    }

    login = requests.post(urlparse.urljoin(url, '/admin/login/'),
                            data=auth,
                            cookies=resp.cookies,
                            allow_redirects=False)
    #print "Login:result= {} cookies= {}".format(login, login.cookies.keys);
    #print "Login:text={}".format(login.text);

    worker_req = {
     'csrfmiddlewaretoken': login.cookies['csrftoken'],
     'hostname': worker['name']
    }

    worker = requests.post(urlparse.urljoin(url,
                                '/admin/lava_scheduler_app/worker/add/'),
                            data=worker_req,
                            cookies=login.cookies)
    #print "Worker:result= {} cookies= {}".format(worker, worker.cookies.keys);
    #print "Worker:text={}".format(worker.text);

def add_devicetype(url, dt):
    # Sequence is:
    # GET /accounts/login -> cookies1
    # POST /admin/login(cookies1,username,password) -> cookies2
    # POST /admin/lava_scheduler_app/devicetype/add(cookies2,devicetype)

    print("Adding devicetype:{} to URL:{}".
            format(dt['name'], url))
    if url == None:
        raise Exception("Need URL")

    resp = requests.get(urlparse.urljoin(url, '/accounts/login/'))
    #print "Get Cookies: result= {} cookies= {}".format(resp, resp.cookies);
    #print "Get Cookies:text={}".format(resp.text);

    auth = {
     'csrfmiddlewaretoken': resp.cookies['csrftoken'],
     'username': 'admin',
     'password': 'admin'
    }

    login = requests.post(urlparse.urljoin(url, '/admin/login/'),
                            data=auth,
                            cookies=resp.cookies,
                            allow_redirects=False)
    #print "Login:result= {} cookies= {}".format(login, login.cookies.keys);
    #print "Login:text={}".format(login.text);

    dt_req = {
     'csrfmiddlewaretoken': login.cookies['csrftoken'],
     'name': dt['name'],
     'display': 'on',
     'health_frequency': '24',
     '_save': 'Save',
     'health_denominator': '0'
    }

    dt = requests.post(urlparse.urljoin(url,
                                '/admin/lava_scheduler_app/devicetype/add/'),
                            data=dt_req,
                            cookies=login.cookies)
    #print "DT:result= {} cookies= {}".format(dt, dt.cookies);
    #print "DT:text={}".format(dt.text);


def myargs(argv):
  parser = OptionParser()
  parser.add_option("-u", "--url", dest="url", action="store", type="string",
                    help="URL for lava server")
  (options, args) = parser.parse_args()
  return (options, args)

def main(argv):
  (options, args) = myargs(argv)
  print "options={} args={}".format(str(options), str(args))
  ini_filename=args[0]
  basedir=os.path.dirname(ini_filename);
  print "initfile=", ini_filename
  ini_file = open(ini_filename, 'r')
  ini = json.loads(ini_file.read())
  ini_file.close()
  if 'workers' in ini:
      for worker in ini['workers']:
            add_worker(options.url, worker)

  if 'devicetypes' in ini:
      for dt in ini['devicetypes']:
            add_devicetype(options.url, dt)

if __name__ == "__main__":
  main(sys.argv[1:])
