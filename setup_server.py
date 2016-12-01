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
  for worker in ini['workers']:
        print "Adding worker:", worker['name']
        add_worker(options.url, worker)

if __name__ == "__main__":
  main(sys.argv[1:])
