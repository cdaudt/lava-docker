#!/usr/bin/python
from optparse import OptionParser
import sys
import subprocess
import os
import json
import tempfile
import requests
import urlparse
import shutil
import errno
import pexpect
import random
import string
import re


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def add_worker(server, basedir, worker):
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

def add_devicetype(server, basedir, dt):
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

    dtresp = requests.post(urlparse.urljoin(server['url'],
                                '/admin/lava_scheduler_app/devicetype/add/'),
                            data=dt_req,
                            cookies=login.cookies)
    #print "DT:result= {} cookies= {}".format(dtresp, dtresp.cookies);
    #print "DT:text={}".format(dtresp.text);

    #Install devicetype file if provided.
    # Note filename has to == devicetype name
    dst = os.path.join('/etc/lava-server/dispatcher-config/device-types',
                        dt['name'] + ".jinja2")
    mkdir_p(os.path.dirname(dst))

    if 'file' in dt:
        os.chdir(basedir)
        shutil.copyfile(dt['file'],
                        dst)

def add_device(server, basedir, dev):
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

    devresp = requests.post(urlparse.urljoin(server['url'],
                                '/admin/lava_scheduler_app/device/add/'),
                            data=dev_req,
                            cookies=login.cookies)
    #print "Dev:result= {} cookies= {}".format(devresp, devresp.cookies);
    #print "Dev:text={}".format(devresp.text);

    #Install device file if provided.
    # Note filename has to == devicetype name
    dst = os.path.join('/etc/dispatcher-config/devices',
                        dev['name'] + ".jinja2")
    mkdir_p(os.path.dirname(dst))
    if 'file' in dev:
        os.chdir(basedir)
        shutil.copyfile(dev['file'],
                        dst)

    # Now add config to device dictionary
    dev_dict_add = [
        'lava-server',
        'manage',
        'device-dictionary',
        '--hostname',
        dev['name'],
        '--import',
        dst
    ]
    subprocess.call(dev_dict_add)

def add_superuser(server, basedir, su):
    print("Adding superuser:{} email:{}"
            .format(su['username'],su['email']))
    p = pexpect.spawn('lava-server manage createsuperuser')
    #log = file('setup_server.log', 'w')
    #p.logfile = log
    p.expect_exact("Username (leave blank to use 'root'):")
    p.sendline(su['username'])
    p.expect_exact("Email address:")
    p.sendline(su['email'])
    p.expect_exact("Password:")
    p.sendline(su['password'])
    p.expect_exact("Password (again):")
    p.sendline(su['password'])
    p.expect_exact("Superuser created successfully.")

def add_apikey(server, basedir, apikey):
    # Sequence is:
    # GET /accounts/login -> cookies1
    # POST /admin/login(cookies1,username,password) -> cookies2
    # POST /admin/lava_scheduler_app/device/add(cookies2,device)
    print("Adding apikey:{} to URL:{}".
            format(apikey['file'], server['url']))
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
    desc = ''.join(random.SystemRandom().
                choice(string.ascii_uppercase + string.digits)
                for _ in range(8))
    print("Description:{}".format(desc))
    apik_req = {
     'csrfmiddlewaretoken': login.cookies['csrftoken'],
     'description': desc,
    }

    apikresp = requests.post(urlparse.urljoin(server['url'],
                                '/api/tokens/create/'),
                            data=apik_req,
                            cookies=login.cookies)
    #print "APIKey:result= {} cookies= {}".format(apikresp, apikresp.cookies)
    #print "APIKey:{}".format(str(apikresp.content))
    count = 0
    keyline = -1
    #TODO: Find key # and add that to apikey file
    for line in string.split(str(apikresp.content), '\n'):
        count += 1
        #print("Line[{}]:{}".format(count, line))
        if keyline == count:
            g = re.search(r'<code>(.*)</code>', line)
            if not g:
                #print("Can't find code block")
                raise Error("Unknown format in response")
            genkey = g.group(1)
            #print("Found key:{}".format(genkey))
        if re.search(r'<p>'+desc+'</p>', line):
            #print("**** MATCH")
            keyline = count+1
    if keyline == -1:
        raise Error("Can't find key")
    keyfile = open(apikey['file'],'w')
    keyfile.write("{}\n".format(genkey))
    keyfile.close()


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
  }
  basedir=os.path.dirname(ini_filename);
  print "initfile=", ini_filename
  ini_file = open(ini_filename, 'r')
  ini = json.loads(ini_file.read())
  ini_file.close()
  if 'superusers' in ini:
      for superuser in ini['superusers']:
          #TODO: Make selecting superuser to use configurable
          #for now assume there's just 1
          server['username'] = superuser['username']
          server['password'] = superuser['password']
          if superuser['create'] == 'yes':
                add_superuser(server, basedir, superuser)

  if 'apikeys' in ini:
      for apikey in ini['apikeys']:
            add_apikey(server, basedir, apikey)

  if 'workers' in ini:
      for worker in ini['workers']:
            add_worker(server, basedir, worker)

  if 'devicetypes' in ini:
      for dt in ini['devicetypes']:
            add_devicetype(server, basedir, dt)

  if 'devices' in ini:
      for dev in ini['devices']:
            add_device(server, basedir, dev)

if __name__ == "__main__":
  main(sys.argv[1:])
