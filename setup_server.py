#!/usr/bin/python
from optparse import OptionParser
import sys
import subprocess
import os
import json
import tempfile
import requests
import urlparse

def add_worker(server, worker):
    # Sequence is:
    # GET /accounts/login -> cookies1
    # POST /admin/login(cookies1,username,password) -> cookies2
    # POST /admin/lava_scheduler_app/worker/add(cookies2,hostname)
    print("Adding worker:{} to URL:{}".
            format(worker['name'], server['url']))
    if server['url'] == None:
        raise Exception("Need URL")

    resp = requests.get(urlparse.urljoin(server['url'], '/accounts/login/'))
    #print "Get Cookies: result= {} cookies= {}".format(resp, resp.cookies);
    #print "Get Cookies:text={}".format(resp.text);

    auth = {
     'csrfmiddlewaretoken': resp.cookies['csrftoken'],
     'username': server['username'],
     'password': server['password']
    }

    login = requests.post(urlparse.urljoin(server['url'], '/admin/login/'),
                            data=auth,
                            cookies=resp.cookies,
                            allow_redirects=False)
    #print "Login:result= {} cookies= {}".format(login, login.cookies.keys);
    #print "Login:text={}".format(login.text);

    worker_req = {
     'csrfmiddlewaretoken': login.cookies['csrftoken'],
     'hostname': worker['name']
    }

    worker = requests.post(urlparse.urljoin(server['url'],
                                '/admin/lava_scheduler_app/worker/add/'),
                            data=worker_req,
                            cookies=login.cookies)
    #print "Worker:result= {} cookies= {}".format(worker, worker.cookies.keys);
    #print "Worker:text={}".format(worker.text);

def add_devicetype(server, dt):
    # Sequence is:
    # GET /accounts/login -> cookies1
    # POST /admin/login(cookies1,username,password) -> cookies2
    # POST /admin/lava_scheduler_app/devicetype/add(cookies2,devicetype)
    print("Adding devicetype:{} to URL:{}".
            format(dt['name'], server['url']))
    if server['url'] == None:
        raise Exception("Need URL")

    resp = requests.get(urlparse.urljoin(server['url'], '/accounts/login/'))
    #print "Get Cookies: result= {} cookies= {}".format(resp, resp.cookies);
    #print "Get Cookies:text={}".format(resp.text);

    auth = {
     'csrfmiddlewaretoken': resp.cookies['csrftoken'],
     'username': server['username'],
     'password': server['password']
    }

    login = requests.post(urlparse.urljoin(server['url'], '/admin/login/'),
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

    dt = requests.post(urlparse.urljoin(server['url'],
                                '/admin/lava_scheduler_app/devicetype/add/'),
                            data=dt_req,
                            cookies=login.cookies)
    #print "DT:result= {} cookies= {}".format(dt, dt.cookies);
    #print "DT:text={}".format(dt.text);

def add_device(server, dev):
    # Sequence is:
    # GET /accounts/login -> cookies1
    # POST /admin/login(cookies1,username,password) -> cookies2
    # POST /admin/lava_scheduler_app/device/add(cookies2,device)
    print("Adding device:{} to URL:{}".
            format(dev['name'], server['url']))
    if server['url'] == None:
        raise Exception("Need URL")

    resp = requests.get(urlparse.urljoin(server['url'], '/accounts/login/'))
    #print "Get Cookies: result= {} cookies= {}".format(resp, resp.cookies);
    #print "Get Cookies:text={}".format(resp.text);

    auth = {
     'csrfmiddlewaretoken': resp.cookies['csrftoken'],
     'username': server['username'],
     'password': server['password']
    }

    login = requests.post(urlparse.urljoin(server['url'], '/admin/login/'),
                            data=auth,
                            cookies=resp.cookies,
                            allow_redirects=False)
    #print "Login:result= {} cookies= {}".format(login, login.cookies.keys);
    #print "Login:text={}".format(login.text);

    dev_req = {
     'csrfmiddlewaretoken': login.cookies['csrftoken'],
     'hostname': dev['name'],
     'device_type': dev['devicetype'],
     'device_version': '1',
     'status': '1',
     'health_status': '0',
     'is_pipeline': 'on',
     'worker_host': dev['worker']
    }

    dev = requests.post(urlparse.urljoin(server['url'],
                                '/admin/lava_scheduler_app/device/add/'),
                            data=dev_req,
                            cookies=login.cookies)
    #print "Dev:result= {} cookies= {}".format(dev, dev.cookies);
    #print "Dev:text={}".format(dev.text);


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
  server = {
    'url': options.url,
    'username': 'admin',
    'password': 'admin'
  }
  basedir=os.path.dirname(ini_filename);
  print "initfile=", ini_filename
  ini_file = open(ini_filename, 'r')
  ini = json.loads(ini_file.read())
  ini_file.close()
  if 'workers' in ini:
      for worker in ini['workers']:
            add_worker(server, worker)

  if 'devicetypes' in ini:
      for dt in ini['devicetypes']:
            add_devicetype(server, dt)

  if 'devices' in ini:
      for dev in ini['devices']:
            add_device(server, dev)

if __name__ == "__main__":
  main(sys.argv[1:])
